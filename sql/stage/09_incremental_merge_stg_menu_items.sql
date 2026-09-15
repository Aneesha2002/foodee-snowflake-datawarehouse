-- ============================================================
-- FOODEE - Incremental Menu Item Stage Load
-- ============================================================

MERGE INTO FOODEE_DB.STAGE.STG_MENU_ITEMS AS target

USING
(
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
      AND price > 0
    QUALIFY ROW_NUMBER() OVER
    (
        PARTITION BY menu_item_id
        ORDER BY menu_item_id
    ) = 1
) AS source

ON target.menu_item_id = source.menu_item_id

WHEN MATCHED AND (
       target.menu_item_name IS DISTINCT FROM source.menu_item_name
    OR target.restaurant_id  IS DISTINCT FROM source.restaurant_id
    OR target.cuisine        IS DISTINCT FROM source.cuisine
    OR target.price          IS DISTINCT FROM source.price
)
THEN UPDATE SET
    target.menu_item_name = source.menu_item_name,
    target.restaurant_id = source.restaurant_id,
    target.cuisine = source.cuisine,
    target.price = source.price

WHEN NOT MATCHED
THEN INSERT
(
    menu_item_id,
    menu_item_name,
    restaurant_id,
    cuisine,
    price
)
VALUES
(
    source.menu_item_id,
    source.menu_item_name,
    source.restaurant_id,
    source.cuisine,
    source.price
);