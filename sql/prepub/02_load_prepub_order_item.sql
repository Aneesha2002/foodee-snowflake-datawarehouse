INSERT INTO FOODEE_DB.PREPUB.PREPUB_ORDER_ITEM
SELECT
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
FROM FOODEE_DB.DM.FACT_ORDER_ITEM;