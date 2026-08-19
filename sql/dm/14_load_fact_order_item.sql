INSERT INTO FOODEE_DB.DM.FACT_ORDER_ITEM
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
SELECT
    oi.order_item_id,
    oi.order_id,
    c.customer_sk,
    r.restaurant_sk,
    m.menu_item_sk,
    o.order_date,
    o.status,
    oi.quantity,
    oi.unit_price,
    oi.discount_amount,
    oi.quantity * oi.unit_price AS gross_amount,
    (oi.quantity * oi.unit_price) - oi.discount_amount AS net_amount
FROM FOODEE_DB.STAGE.STG_ORDER_ITEMS oi
JOIN FOODEE_DB.STAGE.STG_ORDERS o
    ON oi.order_id = o.order_id
JOIN FOODEE_DB.DM.DIM_CUSTOMER c
    ON o.customer_id = c.customer_id
   AND c.is_current = TRUE
JOIN FOODEE_DB.DM.DIM_RESTAURANT r
    ON o.restaurant_id = r.restaurant_id
JOIN FOODEE_DB.DM.DIM_MENU_ITEM m
    ON oi.menu_item_id = m.menu_item_id;