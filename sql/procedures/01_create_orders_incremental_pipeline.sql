-- ============================================================
-- FOODEE - Automated Incremental Orders Pipeline
-- ============================================================
-- Flow:
--   START BATCH
--      ↓
--   STG_ORDERS
--      ↓
--   STG_ORDER_ITEMS
--      ↓
--   DIM_CUSTOMER SCD2
--      ↓
--   FACT_ORDER_ITEM
--      ↓
--   PREPUB_ORDER_ITEM
--      ↓
--   PUB_ORDER_ITEM
--      ↓
--   DATA QUALITY
--      ↓
--   AUDIT SUCCESS
--      ↓
--   UPDATE WATERMARKS
--
-- If anything fails:
--   AUDIT FAILED
--   WATERMARKS ARE NOT ADVANCED
-- ============================================================

CREATE OR REPLACE PROCEDURE FOODEE_DB.RAW.SP_ORDERS_INCREMENTAL_PIPELINE()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$

DECLARE

    v_orders_run_id VARCHAR;
    v_order_items_run_id VARCHAR;

    v_orders_old_watermark TIMESTAMP_NTZ;
    v_order_items_old_watermark TIMESTAMP_NTZ;

    v_orders_batch_end TIMESTAMP_NTZ;
    v_order_items_batch_end TIMESTAMP_NTZ;

    v_dq_failures NUMBER DEFAULT 0;

BEGIN

    -- ========================================================
    -- 1. GET CURRENT WATERMARKS
    -- ========================================================

    SELECT LAST_SUCCESSFUL_TIMESTAMP
    INTO :v_orders_old_watermark
    FROM FOODEE_DB.RAW.FOODEE_LOAD_CONTROL
    WHERE PROCESS_NAME = 'ORDERS';


    SELECT LAST_SUCCESSFUL_TIMESTAMP
    INTO :v_order_items_old_watermark
    FROM FOODEE_DB.RAW.FOODEE_LOAD_CONTROL
    WHERE PROCESS_NAME = 'ORDER_ITEMS';


    -- ========================================================
    -- 2. CAPTURE FIXED BATCH BOUNDARIES
    -- ========================================================

    SELECT MAX(LAST_UPDATED_TIMESTAMP)
    INTO :v_orders_batch_end
    FROM FOODEE_DB.RAW.RAW_ORDERS
    WHERE LAST_UPDATED_TIMESTAMP > :v_orders_old_watermark;


    SELECT MAX(LAST_UPDATED_TIMESTAMP)
    INTO :v_order_items_batch_end
    FROM FOODEE_DB.RAW.RAW_ORDER_ITEMS
    WHERE LAST_UPDATED_TIMESTAMP > :v_order_items_old_watermark;


    -- ========================================================
    -- 3. HANDLE NO-DATA RUN
    -- ========================================================

    IF (v_orders_batch_end IS NULL AND v_order_items_batch_end IS NULL) THEN

        RETURN 'NO_DATA - No new Orders or Order Items found';

    END IF;


    -- ========================================================
    -- 4. CREATE ORDERS BATCH CONTROL RECORD
    -- ========================================================

    IF (v_orders_batch_end IS NOT NULL) THEN

        v_orders_run_id := UUID_STRING();

        INSERT INTO FOODEE_DB.RAW.FOODEE_BATCH_CONTROL
        (
            RUN_ID,
            PROCESS_NAME,
            OLD_WATERMARK,
            BATCH_END_TIMESTAMP,
            CREATED_AT,
            STATUS
        )
        VALUES
        (
            :v_orders_run_id,
            'ORDERS',
            :v_orders_old_watermark,
            :v_orders_batch_end,
            CURRENT_TIMESTAMP(),
            'RUNNING'
        );

    END IF;


    -- ========================================================
    -- 5. CREATE ORDER ITEMS BATCH CONTROL RECORD
    -- ========================================================

    IF (v_order_items_batch_end IS NOT NULL) THEN

        v_order_items_run_id := UUID_STRING();

        INSERT INTO FOODEE_DB.RAW.FOODEE_BATCH_CONTROL
        (
            RUN_ID,
            PROCESS_NAME,
            OLD_WATERMARK,
            BATCH_END_TIMESTAMP,
            CREATED_AT,
            STATUS
        )
        VALUES
        (
            :v_order_items_run_id,
            'ORDER_ITEMS',
            :v_order_items_old_watermark,
            :v_order_items_batch_end,
            CURRENT_TIMESTAMP(),
            'RUNNING'
        );

    END IF;


    -- ========================================================
    -- 6. INCREMENTAL ORDERS → STAGE
    -- ========================================================

    IF (v_orders_batch_end IS NOT NULL) THEN

        MERGE INTO FOODEE_DB.STAGE.STG_ORDERS AS target

        USING
        (
            SELECT
                order_id,
                customer_id,
                restaurant_id,
                order_date,
                total_amount,
                status,
                last_updated_timestamp
            FROM
            (
                SELECT
                    r.order_id,
                    r.customer_id,
                    r.restaurant_id,
                    r.order_date,
                    r.total_amount,
                    r.status,
                    r.last_updated_timestamp,

                    ROW_NUMBER() OVER
                    (
                        PARTITION BY r.order_id
                        ORDER BY r.last_updated_timestamp DESC
                    ) AS rn

                FROM FOODEE_DB.RAW.RAW_ORDERS r

                WHERE r.last_updated_timestamp > :v_orders_old_watermark
                  AND r.last_updated_timestamp <= :v_orders_batch_end

                  AND r.order_id IS NOT NULL
                  AND r.customer_id IS NOT NULL
                  AND r.restaurant_id IS NOT NULL
                  AND r.order_date IS NOT NULL
                  AND r.total_amount IS NOT NULL
                  AND r.status IS NOT NULL
                  AND r.last_updated_timestamp IS NOT NULL
                  AND r.total_amount >= 0
            )

            WHERE rn = 1

        ) AS source

        ON target.order_id = source.order_id

        WHEN MATCHED THEN
            UPDATE SET
                target.customer_id = source.customer_id,
                target.restaurant_id = source.restaurant_id,
                target.order_date = source.order_date,
                target.total_amount = source.total_amount,
                target.status = source.status,
                target.last_updated_timestamp = source.last_updated_timestamp

        WHEN NOT MATCHED THEN
            INSERT
            (
                order_id,
                customer_id,
                restaurant_id,
                order_date,
                total_amount,
                status,
                last_updated_timestamp
            )
            VALUES
            (
                source.order_id,
                source.customer_id,
                source.restaurant_id,
                source.order_date,
                source.total_amount,
                source.status,
                source.last_updated_timestamp
            );

    END IF;


    -- ========================================================
    -- 7. INCREMENTAL ORDER ITEMS → STAGE
    -- ========================================================

    IF (v_order_items_batch_end IS NOT NULL) THEN

        MERGE INTO FOODEE_DB.STAGE.STG_ORDER_ITEMS AS target

        USING
        (
            SELECT
                order_item_id,
                order_id,
                menu_item_id,
                quantity,
                unit_price,
                discount_amount,
                last_updated_timestamp

            FROM
            (
                SELECT
                    r.*,

                    ROW_NUMBER() OVER
                    (
                        PARTITION BY r.order_item_id
                        ORDER BY r.last_updated_timestamp DESC
                    ) AS rn

                FROM FOODEE_DB.RAW.RAW_ORDER_ITEMS r

                WHERE r.last_updated_timestamp > :v_order_items_old_watermark
                  AND r.last_updated_timestamp <= :v_order_items_batch_end

                  AND r.order_item_id IS NOT NULL
                  AND r.order_id IS NOT NULL
                  AND r.menu_item_id IS NOT NULL
                  AND r.quantity IS NOT NULL
                  AND r.unit_price IS NOT NULL
                  AND r.discount_amount IS NOT NULL
                  AND r.last_updated_timestamp IS NOT NULL
                  AND r.quantity > 0
                  AND r.unit_price >= 0
                  AND r.discount_amount >= 0
            )

            WHERE rn = 1

        ) AS source

        ON target.order_item_id = source.order_item_id

        WHEN MATCHED THEN
            UPDATE SET
                target.order_id = source.order_id,
                target.menu_item_id = source.menu_item_id,
                target.quantity = source.quantity,
                target.unit_price = source.unit_price,
                target.discount_amount = source.discount_amount,
                target.last_updated_timestamp = source.last_updated_timestamp

        WHEN NOT MATCHED THEN
            INSERT
            (
                order_item_id,
                order_id,
                menu_item_id,
                quantity,
                unit_price,
                discount_amount,
                last_updated_timestamp
            )
            VALUES
            (
                source.order_item_id,
                source.order_id,
                source.menu_item_id,
                source.quantity,
                source.unit_price,
                source.discount_amount,
                source.last_updated_timestamp
            );

    END IF;


    -- ========================================================
    -- 8. CUSTOMER SCD TYPE 2
    -- ========================================================

    UPDATE FOODEE_DB.DM.DIM_CUSTOMER d

    SET
        effective_end_date = CURRENT_DATE() - 1,
        is_current = FALSE

    FROM FOODEE_DB.STAGE.STG_CUSTOMERS s

    WHERE d.customer_id = s.customer_id
      AND d.is_current = TRUE

      AND
      (
            d.customer_name IS DISTINCT FROM s.customer_name
         OR d.city IS DISTINCT FROM s.city
      );


    INSERT INTO FOODEE_DB.DM.DIM_CUSTOMER
    (
        customer_id,
        customer_name,
        city,
        effective_start_date,
        effective_end_date,
        is_current
    )

    SELECT
        s.customer_id,
        s.customer_name,
        s.city,
        CURRENT_DATE(),
        TO_DATE('9999-12-31'),
        TRUE

    FROM FOODEE_DB.STAGE.STG_CUSTOMERS s

    LEFT JOIN FOODEE_DB.DM.DIM_CUSTOMER d
        ON s.customer_id = d.customer_id
       AND d.is_current = TRUE

        WHERE d.customer_sk IS NULL;


    -- ========================================================
    -- 9. FACT ORDER ITEM
    -- ========================================================
    -- Process:
    --   1. Changed Order Items
    --   2. Order Items belonging to changed Orders
    --
    -- This means an Order status/customer/restaurant change
    -- can update the corresponding fact rows even when the
    -- Order Item itself did not change.
    -- ========================================================

    MERGE INTO FOODEE_DB.DM.FACT_ORDER_ITEM AS target

    USING
    (
        SELECT
            oi.order_item_id,
            oi.order_id,
            c.customer_sk,
            r.restaurant_sk,
            m.menu_item_sk,
            o.order_date,
            o.status AS order_status,
            oi.quantity,
            oi.unit_price,
            oi.discount_amount,

            oi.quantity * oi.unit_price AS gross_amount,

            (oi.quantity * oi.unit_price)
                - oi.discount_amount AS net_amount

        FROM FOODEE_DB.STAGE.STG_ORDER_ITEMS oi

        JOIN
        (
            SELECT
                order_id,
                customer_id,
                restaurant_id,
                order_date,
                status,
                last_updated_timestamp

            FROM FOODEE_DB.STAGE.STG_ORDERS

            QUALIFY ROW_NUMBER() OVER
            (
                PARTITION BY order_id
                ORDER BY last_updated_timestamp DESC
            ) = 1

        ) o
            ON oi.order_id = o.order_id

        JOIN FOODEE_DB.DM.DIM_CUSTOMER c
            ON o.customer_id = c.customer_id
           AND o.order_date >= c.effective_start_date
           AND o.order_date <= c.effective_end_date

        JOIN FOODEE_DB.DM.DIM_RESTAURANT r
            ON o.restaurant_id = r.restaurant_id

        JOIN FOODEE_DB.DM.DIM_MENU_ITEM m
            ON oi.menu_item_id = m.menu_item_id

        WHERE
            (
                (
                    :v_order_items_batch_end IS NOT NULL
                    AND oi.last_updated_timestamp
                        > :v_order_items_old_watermark
                    AND oi.last_updated_timestamp
                        <= :v_order_items_batch_end
                )

                OR

                (
                    :v_orders_batch_end IS NOT NULL
                    AND o.last_updated_timestamp
                        > :v_orders_old_watermark
                    AND o.last_updated_timestamp
                        <= :v_orders_batch_end
                )
            )

    ) AS source

    ON target.order_item_id = source.order_item_id

    WHEN MATCHED THEN
        UPDATE SET
            target.order_id = source.order_id,
            target.customer_sk = source.customer_sk,
            target.restaurant_sk = source.restaurant_sk,
            target.menu_item_sk = source.menu_item_sk,
            target.order_date = source.order_date,
            target.order_status = source.order_status,
            target.quantity = source.quantity,
            target.unit_price = source.unit_price,
            target.discount_amount = source.discount_amount,
            target.gross_amount = source.gross_amount,
            target.net_amount = source.net_amount

    WHEN NOT MATCHED THEN
        INSERT
        (
            order_item_id,
            order_id,
            customer_sk,
            restaurant_sk,
            menu_item_sk,
            order_date,
            order_status,
            quantity,
            unit_price,
            discount_amount,
            gross_amount,
            net_amount
        )

        VALUES
        (
            source.order_item_id,
            source.order_id,
            source.customer_sk,
            source.restaurant_sk,
            source.menu_item_sk,
            source.order_date,
            source.order_status,
            source.quantity,
            source.unit_price,
            source.discount_amount,
            source.gross_amount,
            source.net_amount
        );


    -- ========================================================
    -- 10. FACT → PREPUB
    -- ========================================================

    MERGE INTO FOODEE_DB.PREPUB.PREPUB_ORDER_ITEM target

    USING FOODEE_DB.DM.FACT_ORDER_ITEM source

    ON target.order_item_id = source.order_item_id

    WHEN MATCHED THEN
        UPDATE SET
            target.order_id = source.order_id,
            target.customer_sk = source.customer_sk,
            target.restaurant_sk = source.restaurant_sk,
            target.menu_item_sk = source.menu_item_sk,
            target.order_date = source.order_date,
            target.order_status = source.order_status,
            target.quantity = source.quantity,
            target.unit_price = source.unit_price,
            target.discount_amount = source.discount_amount,
            target.gross_amount = source.gross_amount,
            target.net_amount = source.net_amount

    WHEN NOT MATCHED THEN
        INSERT
        (
            order_item_id,
            order_id,
            customer_sk,
            restaurant_sk,
            menu_item_sk,
            order_date,
            order_status,
            quantity,
            unit_price,
            discount_amount,
            gross_amount,
            net_amount
        )

        VALUES
        (
            source.order_item_id,
            source.order_id,
            source.customer_sk,
            source.restaurant_sk,
            source.menu_item_sk,
            source.order_date,
            source.order_status,
            source.quantity,
            source.unit_price,
            source.discount_amount,
            source.gross_amount,
            source.net_amount
        );

-- ========================================================
-- 11. PREPUB → PUB
-- ========================================================

MERGE INTO FOODEE_DB.PUB.PUB_ORDER_ITEM AS target

USING
(
    SELECT
        p.order_item_id,
        p.order_id,
        p.order_date,
        p.order_status,

        p.customer_sk,
        c.customer_id,
        c.customer_name,

        p.restaurant_sk,
        r.restaurant_id,
        r.restaurant_name,

        p.menu_item_sk,
        m.menu_item_id,
        m.menu_item_name,
        m.cuisine,

        p.quantity,
        p.unit_price,
        p.discount_amount,
        p.gross_amount,
        p.net_amount

    FROM FOODEE_DB.PREPUB.PREPUB_ORDER_ITEM p

    JOIN FOODEE_DB.DM.DIM_CUSTOMER c
        ON p.customer_sk = c.customer_sk

    JOIN FOODEE_DB.DM.DIM_RESTAURANT r
        ON p.restaurant_sk = r.restaurant_sk

    JOIN FOODEE_DB.DM.DIM_MENU_ITEM m
        ON p.menu_item_sk = m.menu_item_sk

) AS source

ON target.order_item_id = source.order_item_id

WHEN MATCHED THEN
    UPDATE SET
        target.order_id = source.order_id,
        target.order_date = source.order_date,
        target.order_status = source.order_status,

        target.customer_sk = source.customer_sk,
        target.customer_id = source.customer_id,
        target.customer_name = source.customer_name,

        target.restaurant_sk = source.restaurant_sk,
        target.restaurant_id = source.restaurant_id,
        target.restaurant_name = source.restaurant_name,

        target.menu_item_sk = source.menu_item_sk,
        target.menu_item_id = source.menu_item_id,
        target.menu_item_name = source.menu_item_name,
        target.cuisine = source.cuisine,

        target.quantity = source.quantity,
        target.unit_price = source.unit_price,
        target.discount_amount = source.discount_amount,
        target.gross_amount = source.gross_amount,
        target.net_amount = source.net_amount

WHEN NOT MATCHED THEN
    INSERT
    (
        order_item_id,
        order_id,
        order_date,
        order_status,

        customer_sk,
        customer_id,
        customer_name,

        restaurant_sk,
        restaurant_id,
        restaurant_name,

        menu_item_sk,
        menu_item_id,
        menu_item_name,
        cuisine,

        quantity,
        unit_price,
        discount_amount,
        gross_amount,
        net_amount
    )

    VALUES
    (
        source.order_item_id,
        source.order_id,
        source.order_date,
        source.order_status,

        source.customer_sk,
        source.customer_id,
        source.customer_name,

        source.restaurant_sk,
        source.restaurant_id,
        source.restaurant_name,

        source.menu_item_sk,
        source.menu_item_id,
        source.menu_item_name,
        source.cuisine,

        source.quantity,
        source.unit_price,
        source.discount_amount,
        source.gross_amount,
        source.net_amount
    );

    -- ========================================================
    -- 12. DATA QUALITY GATE
    -- ========================================================
    -- Each check contributes either:
    --   0 = passed
    --   positive number = failures
    --
    -- Customer natural-key duplicates are NOT automatically
    -- failures because SCD Type 2 intentionally creates
    -- multiple records for the same customer_id.
    -- ========================================================

    v_dq_failures := 0;


    -- 1. Duplicate customer SK
    v_dq_failures := v_dq_failures + (
        SELECT COUNT(*)
        FROM
        (
            SELECT customer_sk
            FROM FOODEE_DB.DM.DIM_CUSTOMER
            GROUP BY customer_sk
            HAVING COUNT(*) > 1
        )
    );


    -- 2. Duplicate restaurant SK
    v_dq_failures := v_dq_failures + (
        SELECT COUNT(*)
        FROM
        (
            SELECT restaurant_sk
            FROM FOODEE_DB.DM.DIM_RESTAURANT
            GROUP BY restaurant_sk
            HAVING COUNT(*) > 1
        )
    );


    -- 3. Duplicate menu item SK
    v_dq_failures := v_dq_failures + (
        SELECT COUNT(*)
        FROM
        (
            SELECT menu_item_sk
            FROM FOODEE_DB.DM.DIM_MENU_ITEM
            GROUP BY menu_item_sk
            HAVING COUNT(*) > 1
        )
    );


    -- 4. Duplicate order item
    v_dq_failures := v_dq_failures + (
        SELECT COUNT(*)
        FROM
        (
            SELECT order_item_id
            FROM FOODEE_DB.DM.FACT_ORDER_ITEM
            GROUP BY order_item_id
            HAVING COUNT(*) > 1
        )
    );


    -- 5. Orphan customer SK
    v_dq_failures := v_dq_failures + (
        SELECT COUNT(*)
        FROM FOODEE_DB.DM.FACT_ORDER_ITEM f
        LEFT JOIN FOODEE_DB.DM.DIM_CUSTOMER c
            ON f.customer_sk = c.customer_sk
        WHERE c.customer_sk IS NULL
    );


    -- 6. Orphan restaurant SK
    v_dq_failures := v_dq_failures + (
        SELECT COUNT(*)
        FROM FOODEE_DB.DM.FACT_ORDER_ITEM f
        LEFT JOIN FOODEE_DB.DM.DIM_RESTAURANT r
            ON f.restaurant_sk = r.restaurant_sk
        WHERE r.restaurant_sk IS NULL
    );


    -- 7. Orphan menu item SK
    v_dq_failures := v_dq_failures + (
        SELECT COUNT(*)
        FROM FOODEE_DB.DM.FACT_ORDER_ITEM f
        LEFT JOIN FOODEE_DB.DM.DIM_MENU_ITEM m
            ON f.menu_item_sk = m.menu_item_sk
        WHERE m.menu_item_sk IS NULL
    );


    -- 8. Critical NULLs
    v_dq_failures := v_dq_failures + (
        SELECT COUNT(*)
        FROM FOODEE_DB.DM.FACT_ORDER_ITEM
        WHERE order_item_id IS NULL
           OR order_id IS NULL
           OR customer_sk IS NULL
           OR restaurant_sk IS NULL
           OR menu_item_sk IS NULL
           OR order_date IS NULL
    );


    -- 9. Amount calculations
    v_dq_failures := v_dq_failures + (
        SELECT COUNT(*)
        FROM FOODEE_DB.DM.FACT_ORDER_ITEM
        WHERE gross_amount <> quantity * unit_price
           OR net_amount <> gross_amount - discount_amount
    );


    -- 10. Invalid SCD2 dates
    v_dq_failures := v_dq_failures + (
        SELECT COUNT(*)
        FROM FOODEE_DB.DM.DIM_CUSTOMER
        WHERE effective_end_date < effective_start_date
    );


    -- 11. Multiple current customer records
    v_dq_failures := v_dq_failures + (
        SELECT COUNT(*)
        FROM
        (
            SELECT customer_id
            FROM FOODEE_DB.DM.DIM_CUSTOMER
            WHERE is_current = TRUE
            GROUP BY customer_id
            HAVING COUNT(*) > 1
        )
    );


    -- 12. Duplicate restaurant natural keys
    v_dq_failures := v_dq_failures + (
        SELECT COUNT(*)
        FROM
        (
            SELECT restaurant_id
            FROM FOODEE_DB.DM.DIM_RESTAURANT
            GROUP BY restaurant_id
            HAVING COUNT(*) > 1
        )
    );


    -- 13. Duplicate menu item natural keys
    v_dq_failures := v_dq_failures + (
        SELECT COUNT(*)
        FROM
        (
            SELECT menu_item_id
            FROM FOODEE_DB.DM.DIM_MENU_ITEM
            GROUP BY menu_item_id
            HAVING COUNT(*) > 1
        )
    );


    -- 14. Overlapping SCD2 records
    v_dq_failures := v_dq_failures + (
        SELECT COUNT(*)
        FROM FOODEE_DB.DM.DIM_CUSTOMER c1
        JOIN FOODEE_DB.DM.DIM_CUSTOMER c2
            ON c1.customer_id = c2.customer_id
           AND c1.customer_sk <> c2.customer_sk
           AND c1.effective_start_date <= c2.effective_end_date
           AND c2.effective_start_date <= c1.effective_end_date
    );


    -- 15. Invalid fact values
    v_dq_failures := v_dq_failures + (
        SELECT COUNT(*)
        FROM FOODEE_DB.DM.FACT_ORDER_ITEM
        WHERE quantity <= 0
           OR unit_price < 0
           OR discount_amount < 0
    );


    -- 16. FACT → PREPUB → PUB reconciliation
    v_dq_failures := v_dq_failures + (
        SELECT
            CASE
                WHEN
                    (SELECT COUNT(*)
                     FROM FOODEE_DB.DM.FACT_ORDER_ITEM)
                    =
                    (SELECT COUNT(*)
                     FROM FOODEE_DB.PREPUB.PREPUB_ORDER_ITEM)

                AND

                    (SELECT COUNT(*)
                     FROM FOODEE_DB.PREPUB.PREPUB_ORDER_ITEM)
                    =
                    (SELECT COUNT(*)
                     FROM FOODEE_DB.PUB.PUB_ORDER_ITEM)

                THEN 0
                ELSE 1
            END
    );

-- ========================================================
-- 13. FAIL PIPELINE IF DQ FAILED
-- ========================================================

IF (v_dq_failures > 0) THEN

    IF (v_orders_run_id IS NOT NULL) THEN

        UPDATE FOODEE_DB.RAW.FOODEE_BATCH_CONTROL
        SET
            STATUS = 'FAILED',
            COMPLETED_AT = CURRENT_TIMESTAMP(),
            ERROR_MESSAGE = 'Data quality validation failed'
        WHERE RUN_ID = :v_orders_run_id;


        INSERT INTO FOODEE_DB.RAW.FOODEE_PIPELINE_AUDIT
        (
            RUN_ID,
            PROCESS_NAME,
            TABLE_NAME,
            LAYER,
            START_TIME,
            END_TIME,
            ROWS_PROCESSED,
            ROWS_LOADED,
            STATUS,
            ERROR_MESSAGE
        )

        SELECT
            RUN_ID,
            PROCESS_NAME,
            'ORDERS',
            'RAW_TO_PUB',
            CREATED_AT,
            COMPLETED_AT,
            ROWS_PROCESSED,
            ROWS_LOADED,
            STATUS,
            ERROR_MESSAGE

        FROM FOODEE_DB.RAW.FOODEE_BATCH_CONTROL

        WHERE RUN_ID = :v_orders_run_id;

    END IF;


    IF (v_order_items_run_id IS NOT NULL) THEN

        UPDATE FOODEE_DB.RAW.FOODEE_BATCH_CONTROL
        SET
            STATUS = 'FAILED',
            COMPLETED_AT = CURRENT_TIMESTAMP(),
            ERROR_MESSAGE = 'Data quality validation failed'
        WHERE RUN_ID = :v_order_items_run_id;


        INSERT INTO FOODEE_DB.RAW.FOODEE_PIPELINE_AUDIT
        (
            RUN_ID,
            PROCESS_NAME,
            TABLE_NAME,
            LAYER,
            START_TIME,
            END_TIME,
            ROWS_PROCESSED,
            ROWS_LOADED,
            STATUS,
            ERROR_MESSAGE
        )

        SELECT
            RUN_ID,
            PROCESS_NAME,
            'ORDER_ITEMS',
            'RAW_TO_PUB',
            CREATED_AT,
            COMPLETED_AT,
            ROWS_PROCESSED,
            ROWS_LOADED,
            STATUS,
            ERROR_MESSAGE

        FROM FOODEE_DB.RAW.FOODEE_BATCH_CONTROL

        WHERE RUN_ID = :v_order_items_run_id;

    END IF;


    RETURN
        'FAILED - Data quality validation failed. Watermarks not advanced. DQ failures: '
        || v_dq_failures;

END IF;

    -- ========================================================
    -- 14. MARK BATCHES SUCCESSFUL
    -- ========================================================

    IF (v_orders_run_id IS NOT NULL) THEN

        UPDATE FOODEE_DB.RAW.FOODEE_BATCH_CONTROL

        SET
            STATUS = 'SUCCESS',
            COMPLETED_AT = CURRENT_TIMESTAMP(),

            ROWS_PROCESSED =
            (
                SELECT COUNT(*)
                FROM FOODEE_DB.RAW.RAW_ORDERS
                WHERE LAST_UPDATED_TIMESTAMP > :v_orders_old_watermark
                  AND LAST_UPDATED_TIMESTAMP <= :v_orders_batch_end
            ),

            ROWS_LOADED =
            (
                SELECT COUNT(*)
                FROM FOODEE_DB.STAGE.STG_ORDERS
                WHERE LAST_UPDATED_TIMESTAMP > :v_orders_old_watermark
                  AND LAST_UPDATED_TIMESTAMP <= :v_orders_batch_end
            )

        WHERE RUN_ID = :v_orders_run_id;

    END IF;


    IF (v_order_items_run_id IS NOT NULL) THEN

        UPDATE FOODEE_DB.RAW.FOODEE_BATCH_CONTROL

        SET
            STATUS = 'SUCCESS',
            COMPLETED_AT = CURRENT_TIMESTAMP(),

            ROWS_PROCESSED =
            (
                SELECT COUNT(*)
                FROM FOODEE_DB.RAW.RAW_ORDER_ITEMS
                WHERE LAST_UPDATED_TIMESTAMP > :v_order_items_old_watermark
                  AND LAST_UPDATED_TIMESTAMP <= :v_order_items_batch_end
            ),

            ROWS_LOADED =
            (
                SELECT COUNT(*)
                FROM FOODEE_DB.STAGE.STG_ORDER_ITEMS
                WHERE LAST_UPDATED_TIMESTAMP > :v_order_items_old_watermark
                  AND LAST_UPDATED_TIMESTAMP <= :v_order_items_batch_end
            )

        WHERE RUN_ID = :v_order_items_run_id;

    END IF;


    -- ========================================================
    -- 15. WRITE AUDIT RECORDS
    -- ========================================================

    IF (v_orders_run_id IS NOT NULL) THEN

        INSERT INTO FOODEE_DB.RAW.FOODEE_PIPELINE_AUDIT
        (
            RUN_ID,
            PROCESS_NAME,
            TABLE_NAME,
            LAYER,
            START_TIME,
            END_TIME,
            ROWS_PROCESSED,
            ROWS_LOADED,
            STATUS,
            ERROR_MESSAGE
        )

        SELECT
            RUN_ID,
            PROCESS_NAME,
            'ORDERS',
            'RAW_TO_PUB',
            CREATED_AT,
            COMPLETED_AT,
            ROWS_PROCESSED,
            ROWS_LOADED,
            STATUS,
            ERROR_MESSAGE

        FROM FOODEE_DB.RAW.FOODEE_BATCH_CONTROL

        WHERE RUN_ID = :v_orders_run_id;

    END IF;


    IF (v_order_items_run_id IS NOT NULL) THEN

        INSERT INTO FOODEE_DB.RAW.FOODEE_PIPELINE_AUDIT
        (
            RUN_ID,
            PROCESS_NAME,
            TABLE_NAME,
            LAYER,
            START_TIME,
            END_TIME,
            ROWS_PROCESSED,
            ROWS_LOADED,
            STATUS,
            ERROR_MESSAGE
        )

        SELECT
            RUN_ID,
            PROCESS_NAME,
            'ORDER_ITEMS',
            'RAW_TO_PUB',
            CREATED_AT,
            COMPLETED_AT,
            ROWS_PROCESSED,
            ROWS_LOADED,
            STATUS,
            ERROR_MESSAGE

        FROM FOODEE_DB.RAW.FOODEE_BATCH_CONTROL

        WHERE RUN_ID = :v_order_items_run_id;

    END IF;


    -- ========================================================
    -- 16. ADVANCE WATERMARKS ONLY AFTER SUCCESS
    -- ========================================================

    IF (v_orders_run_id IS NOT NULL) THEN

        UPDATE FOODEE_DB.RAW.FOODEE_LOAD_CONTROL

        SET
            LAST_SUCCESSFUL_TIMESTAMP = :v_orders_batch_end,
            UPDATED_AT = CURRENT_TIMESTAMP()

        WHERE PROCESS_NAME = 'ORDERS';

    END IF;


    IF (v_order_items_run_id IS NOT NULL) THEN

        UPDATE FOODEE_DB.RAW.FOODEE_LOAD_CONTROL

        SET
            LAST_SUCCESSFUL_TIMESTAMP = :v_order_items_batch_end,
            UPDATED_AT = CURRENT_TIMESTAMP()

        WHERE PROCESS_NAME = 'ORDER_ITEMS';

    END IF;


    -- ========================================================
    -- 17. RETURN SUCCESS
    -- ========================================================

    RETURN 'SUCCESS - FOODEE incremental Orders pipeline completed';

EXCEPTION

    WHEN OTHER THEN

        IF (v_orders_run_id IS NOT NULL) THEN

            UPDATE FOODEE_DB.RAW.FOODEE_BATCH_CONTROL
            SET
                STATUS = 'FAILED',
                COMPLETED_AT = CURRENT_TIMESTAMP(),
                ERROR_MESSAGE =
                    'SQLCODE='
                    || :SQLCODE
                    || ' | SQLSTATE='
                    || :SQLSTATE
                    || ' | SQLERRM='
                    || :SQLERRM
            WHERE RUN_ID = :v_orders_run_id;


            INSERT INTO FOODEE_DB.RAW.FOODEE_PIPELINE_AUDIT
            (
                RUN_ID,
                PROCESS_NAME,
                TABLE_NAME,
                LAYER,
                START_TIME,
                END_TIME,
                ROWS_PROCESSED,
                ROWS_LOADED,
                STATUS,
                ERROR_MESSAGE
            )

            SELECT
                RUN_ID,
                PROCESS_NAME,
                'ORDERS',
                'RAW_TO_PUB',
                CREATED_AT,
                COMPLETED_AT,
                ROWS_PROCESSED,
                ROWS_LOADED,
                STATUS,
                ERROR_MESSAGE

            FROM FOODEE_DB.RAW.FOODEE_BATCH_CONTROL

            WHERE RUN_ID = :v_orders_run_id;

        END IF;


        IF (v_order_items_run_id IS NOT NULL) THEN

            UPDATE FOODEE_DB.RAW.FOODEE_BATCH_CONTROL
            SET
                STATUS = 'FAILED',
                COMPLETED_AT = CURRENT_TIMESTAMP(),
                ERROR_MESSAGE =
                    'SQLCODE='
                    || :SQLCODE
                    || ' | SQLSTATE='
                    || :SQLSTATE
                    || ' | SQLERRM='
                    || :SQLERRM
            WHERE RUN_ID = :v_order_items_run_id;


            INSERT INTO FOODEE_DB.RAW.FOODEE_PIPELINE_AUDIT
            (
                RUN_ID,
                PROCESS_NAME,
                TABLE_NAME,
                LAYER,
                START_TIME,
                END_TIME,
                ROWS_PROCESSED,
                ROWS_LOADED,
                STATUS,
                ERROR_MESSAGE
            )

            SELECT
                RUN_ID,
                PROCESS_NAME,
                'ORDER_ITEMS',
                'RAW_TO_PUB',
                CREATED_AT,
                COMPLETED_AT,
                ROWS_PROCESSED,
                ROWS_LOADED,
                STATUS,
                ERROR_MESSAGE

            FROM FOODEE_DB.RAW.FOODEE_BATCH_CONTROL

            WHERE RUN_ID = :v_order_items_run_id;

        END IF;


        RETURN
            'FAILED - SQLCODE: '
            || SQLCODE
            || ' | SQLSTATE: '
            || SQLSTATE
            || ' | SQLERRM: '
            || SQLERRM;

END;

$$;