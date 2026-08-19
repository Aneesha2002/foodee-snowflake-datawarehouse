INSERT INTO FOODEE_DB.DM.DIM_MENU_ITEM
(
    menu_item_id,
    menu_item_name,
    restaurant_sk,
    cuisine,
    price
)
SELECT
    m.menu_item_id,
    m.menu_item_name,
    r.restaurant_sk,
    m.cuisine,
    m.price
FROM FOODEE_DB.STAGE.STG_MENU_ITEMS m
JOIN FOODEE_DB.DM.DIM_RESTAURANT r
ON m.restaurant_id = r.restaurant_id;