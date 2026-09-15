CREATE TABLE FOODEE_DB.DM.FACT_ORDER_ITEM(
    order_item_sk NUMBER AUTOINCREMENT,
    order_item_id VARCHAR,
    order_id VARCHAR,
    customer_sk NUMBER,
    restaurant_sk NUMBER,
    menu_item_sk NUMBER,
    order_date DATE,
    order_status VARCHAR,
    quantity NUMBER,
    unit_price NUMBER(10,2),
    discount_amount NUMBER(10,2),
    gross_amount NUMBER(12,2),
    net_amount NUMBER(12,2)
);