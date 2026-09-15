CREATE TABLE FOODEE_DB.DM.DIM_MENU_ITEM (
    menu_item_sk   NUMBER AUTOINCREMENT,
    menu_item_id   VARCHAR,
    menu_item_name VARCHAR,
    restaurant_sk  NUMBER,
    cuisine        VARCHAR,
    price          NUMBER(10,2)
);