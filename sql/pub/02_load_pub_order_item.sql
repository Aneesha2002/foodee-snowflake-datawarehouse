INSERT INTO FOODEE_DB.PUB.PUB_ORDER_ITEM
(
    order_item_id,
    order_id,
    order_date,
    order_status,
    customer_id,
    customer_name,
    restaurant_id,
    restaurant_name,
    menu_item_id,
    menu_item_name,
    cuisine,
    quantity,
    unit_price,
    discount_amount,
    gross_amount,
    net_amount
)
SELECT
    p.order_item_id,
    p.order_id,
    p.order_date,
    p.order_status,
    c.customer_id,
    c.customer_name,
    r.restaurant_id,
    r.restaurant_name,
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
    ON p.menu_item_sk = m.menu_item_sk;