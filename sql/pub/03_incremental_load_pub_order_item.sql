-- ============================================================
-- FOODEE - Incremental PUB ORDER ITEM Load
-- ============================================================

MERGE INTO FOODEE_DB.PUB.PUB_ORDER_ITEM AS target

USING (
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
        ON p.order_item_id = changed.order_item_id

) source

ON target.order_item_id = source.order_item_id

WHEN MATCHED THEN UPDATE SET
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

WHEN NOT MATCHED THEN INSERT (
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
VALUES (
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