-- ============================================================
-- FOODEE - Incremental Orders Load
-- Uses the fixed batch boundary created for this run
-- ============================================================

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

        CROSS JOIN
        (
            SELECT
                OLD_WATERMARK,
                BATCH_END_TIMESTAMP
            FROM FOODEE_DB.RAW.FOODEE_BATCH_CONTROL
            WHERE RUN_ID =
            (
                SELECT RUN_ID
                FROM FOODEE_DB.RAW.FOODEE_BATCH_CONTROL
                WHERE PROCESS_NAME = 'ORDERS'
                ORDER BY CREATED_AT DESC
                LIMIT 1
            )
        ) b

        WHERE r.last_updated_timestamp > b.OLD_WATERMARK
          AND r.last_updated_timestamp <= b.BATCH_END_TIMESTAMP

          -- Data quality checks
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