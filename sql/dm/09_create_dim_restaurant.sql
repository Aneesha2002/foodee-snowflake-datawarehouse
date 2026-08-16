CREATE TABLE FOODEE_DB.DM.DIM_RESTAURANT(
    restaurant_sk NUMBER AUTOINCREMENT,
    restaurant_id VARCHAR,
    restaurant_name VARCHAR,
    cuisine VARCHAR,
    city VARCHAR,
    rating NUMBER(3,1)
);