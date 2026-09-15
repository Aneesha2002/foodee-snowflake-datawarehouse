-- ============================================================
-- FOODEE - Incremental PREPUB ORDER_ITEM Load
-- ============================================================

MERGE INTO FOODEE_DB.PREPUB.PREPUB_ORDER_ITEM AS target

USING (
    SELECT
        f.order_item_id,
        f.order_id,
        f.customer_sk,
        f.restaurant_sk,
        f.menu_item_sk,
        f.order_date,
        f.order_status,
        f.quantity,
        f.unit_price,
        f.discount_amount,
        f.gross_amount,
        f.net_amount
    FROM FOODEE_DB.DM.FACT_ORDER_ITEM f

    JOIN (
        SELECT DISTINCT
            order_item_id
        FROM FOODEE_DB.RAW.RAW_ORDER_ITEMS

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

        WHERE LAST_UPDATED_TIMESTAMP > batch.OLD_WATERMARK
          AND LAST_UPDATED_TIMESTAMP <= batch.BATCH_END_TIMESTAMP
    ) changed
        ON f.order_item_id = changed.order_item_id

) source

ON target.order_item_id = source.order_item_id

WHEN MATCHED THEN UPDATE SET
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

WHEN NOT MATCHED THEN INSERT (
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
VALUES (
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