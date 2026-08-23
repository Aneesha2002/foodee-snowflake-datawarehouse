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

        (oi.quantity * oi.unit_price) - oi.discount_amount AS net_amount

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
       AND c.is_current = TRUE

    JOIN FOODEE_DB.DM.DIM_RESTAURANT r
        ON o.restaurant_id = r.restaurant_id

    JOIN FOODEE_DB.DM.DIM_MENU_ITEM m
        ON oi.menu_item_id = m.menu_item_id

) AS source

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

WHEN NOT MATCHED THEN INSERT
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