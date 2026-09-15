-- ============================================================
-- FOODEE - Incremental Restaurant Dimension Load
-- ============================================================

MERGE INTO FOODEE_DB.DM.DIM_RESTAURANT d
USING (
    SELECT
        restaurant_id,
        restaurant_name,
        cuisine,
        city,
        rating
    FROM FOODEE_DB.STAGE.STG_RESTAURANTS
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY restaurant_id
        ORDER BY restaurant_id
    ) = 1
) s
ON d.restaurant_id = s.restaurant_id

-- Update existing restaurant when attributes change
WHEN MATCHED AND (
       d.restaurant_name IS DISTINCT FROM s.restaurant_name
    OR d.cuisine        IS DISTINCT FROM s.cuisine
    OR d.city           IS DISTINCT FROM s.city
    OR d.rating         IS DISTINCT FROM s.rating
)
THEN UPDATE SET
    d.restaurant_name = s.restaurant_name,
    d.cuisine = s.cuisine,
    d.city = s.city,
    d.rating = s.rating

-- Insert new restaurants
WHEN NOT MATCHED
THEN INSERT (
    restaurant_id,
    restaurant_name,
    cuisine,
    city,
    rating
)
VALUES (
    s.restaurant_id,
    s.restaurant_name,
    s.cuisine,
    s.city,
    s.rating
);