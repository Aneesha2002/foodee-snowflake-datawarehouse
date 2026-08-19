CREATE TABLE FOODEE_DB.PUB.PUB_ORDER_ITEM (
    order_item_id      VARCHAR,
    order_id           VARCHAR,
    order_date         DATE,
    order_status       VARCHAR,
    customer_id        VARCHAR,
    customer_name      VARCHAR,
    restaurant_id      VARCHAR,
    restaurant_name    VARCHAR,
    menu_item_id       VARCHAR,
    menu_item_name     VARCHAR,
    cuisine            VARCHAR,
    quantity            NUMBER,
    unit_price          NUMBER(10,2),
    discount_amount     NUMBER(10,2),
    gross_amount        NUMBER(12,2),
    net_amount          NUMBER(12,2)
);