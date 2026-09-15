CREATE TABLE FOODEE_DB.STAGE.STG_ORDER_ITEMS (
    order_item_id    VARCHAR,
    order_id         VARCHAR,
    menu_item_id     VARCHAR,
    quantity         NUMBER,
    unit_price       NUMBER(10,2),
    discount_amount  NUMBER(10,2)
);