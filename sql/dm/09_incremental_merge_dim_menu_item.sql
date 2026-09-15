-- ============================================================
-- FOODEE - Incremental Menu Item Dimension Load
-- ============================================================

MERGE INTO FOODEE_DB.DM.DIM_MENU_ITEM AS target

USING
(
    SELECT
        m.menu_item_id,
        m.menu_item_name,
        r.restaurant_sk,
        m.cuisine,
        m.price
    FROM FOODEE_DB.STAGE.STG_MENU_ITEMS m
    JOIN FOODEE_DB.DM.DIM_RESTAURANT r
      ON m.restaurant_id = r.restaurant_id
    QUALIFY ROW_NUMBER() OVER
    (
        PARTITION BY m.menu_item_id
        ORDER BY m.menu_item_id
    ) = 1
) AS source

ON target.menu_item_id = source.menu_item_id

WHEN MATCHED AND (
       target.menu_item_name IS DISTINCT FROM source.menu_item_name
    OR target.restaurant_sk  IS DISTINCT FROM source.restaurant_sk
    OR target.cuisine        IS DISTINCT FROM source.cuisine
    OR target.price          IS DISTINCT FROM source.price
)
THEN UPDATE SET
    target.menu_item_name = source.menu_item_name,
    target.restaurant_sk = source.restaurant_sk,
    target.cuisine = source.cuisine,
    target.price = source.price

WHEN NOT MATCHED
THEN INSERT
(
    menu_item_id,
    menu_item_name,
    restaurant_sk,
    cuisine,
    price
)
VALUES
(
    source.menu_item_id,
    source.menu_item_name,
    source.restaurant_sk,
    source.cuisine,
    source.price
);