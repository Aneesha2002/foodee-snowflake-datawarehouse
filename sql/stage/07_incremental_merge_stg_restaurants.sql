-- ============================================================
-- FOODEE - Incremental Restaurant Stage Load
-- ============================================================

MERGE INTO FOODEE_DB.STAGE.STG_RESTAURANTS AS target

USING
(
    SELECT
        restaurant_id,
        restaurant_name,
        cuisine,
        city,
        rating
    FROM FOODEE_DB.RAW.RAW_RESTAURANTS
    WHERE restaurant_id IS NOT NULL
      AND restaurant_name IS NOT NULL
      AND cuisine IS NOT NULL
      AND city IS NOT NULL
      AND rating BETWEEN 0 AND 5
    QUALIFY ROW_NUMBER() OVER
    (
        PARTITION BY restaurant_id
        ORDER BY restaurant_id
    ) = 1
) AS source

ON target.restaurant_id = source.restaurant_id

WHEN MATCHED AND (
       target.restaurant_name IS DISTINCT FROM source.restaurant_name
    OR target.cuisine        IS DISTINCT FROM source.cuisine
    OR target.city           IS DISTINCT FROM source.city
    OR target.rating         IS DISTINCT FROM source.rating
)
THEN UPDATE SET
    target.restaurant_name = source.restaurant_name,
    target.cuisine = source.cuisine,
    target.city = source.city,
    target.rating = source.rating

WHEN NOT MATCHED
THEN INSERT
(
    restaurant_id,
    restaurant_name,
    cuisine,
    city,
    rating
)
VALUES
(
    source.restaurant_id,
    source.restaurant_name,
    source.cuisine,
    source.city,
    source.rating
);