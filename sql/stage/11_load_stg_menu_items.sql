INSERT INTO FOODEE_DB.STAGE.STG_MENU_ITEMS
(
    menu_item_id,
    menu_item_name,
    restaurant_id,
    cuisine,
    price
)
SELECT
    menu_item_id,
    menu_item_name,
    restaurant_id,
    cuisine,
    price
FROM FOODEE_DB.RAW.RAW_MENU_ITEMS
WHERE menu_item_id IS NOT NULL
  AND menu_item_name IS NOT NULL
  AND restaurant_id IS NOT NULL
  AND cuisine IS NOT NULL
  AND price > 0;