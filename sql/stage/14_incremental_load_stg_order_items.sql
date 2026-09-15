-- ============================================================
-- FOODEE - Incremental ORDER_ITEMS Stage Load
-- ============================================================

MERGE INTO FOODEE_DB.STAGE.STG_ORDER_ITEMS AS target

USING (
    SELECT
        order_item_id,
        order_id,
        menu_item_id,
        quantity,
        unit_price,
        discount_amount,
        last_updated_timestamp
    FROM (
        SELECT
            oi.order_item_id,
            oi.order_id,
            oi.menu_item_id,
            oi.quantity,
            oi.unit_price,
            oi.discount_amount,
            oi.last_updated_timestamp,

            ROW_NUMBER() OVER (
                PARTITION BY oi.order_item_id
                ORDER BY oi.last_updated_timestamp DESC
            ) AS rn

        FROM FOODEE_DB.RAW.RAW_ORDER_ITEMS oi

        CROSS JOIN (
            SELECT
                OLD_WATERMARK,
                BATCH_END_TIMESTAMP
            FROM FOODEE_DB.RAW.FOODEE_BATCH_CONTROL
            WHERE RUN_ID = (
                SELECT RUN_ID
                FROM FOODEE_DB.RAW.FOODEE_BATCH_CONTROL
                WHERE PROCESS_NAME = 'ORDER_ITEMS'
                ORDER BY CREATED_AT DESC
                LIMIT 1
            )
        ) batch

        WHERE oi.last_updated_timestamp > batch.OLD_WATERMARK
          AND oi.last_updated_timestamp <= batch.BATCH_END_TIMESTAMP

          AND oi.order_item_id IS NOT NULL
          AND oi.order_id IS NOT NULL
          AND oi.menu_item_id IS NOT NULL
          AND oi.quantity > 0
          AND oi.unit_price > 0
          AND oi.discount_amount >= 0
          AND oi.last_updated_timestamp IS NOT NULL
    )
    WHERE rn = 1
) source

ON target.order_item_id = source.order_item_id

WHEN MATCHED THEN UPDATE SET
    target.order_id = source.order_id,
    target.menu_item_id = source.menu_item_id,
    target.quantity = source.quantity,
    target.unit_price = source.unit_price,
    target.discount_amount = source.discount_amount,
    target.last_updated_timestamp = source.last_updated_timestamp

WHEN NOT MATCHED THEN INSERT (
    order_item_id,
    order_id,
    menu_item_id,
    quantity,
    unit_price,
    discount_amount,
    last_updated_timestamp
)
VALUES (
    source.order_item_id,
    source.order_id,
    source.menu_item_id,
    source.quantity,
    source.unit_price,
    source.discount_amount,
    source.last_updated_timestamp
);