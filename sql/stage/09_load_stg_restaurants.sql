INSERT INTO FOODEE_DB.STAGE.STG_RESTAURANTS
(
    restaurant_id,
    restaurant_name,
    cuisine,
    city,
    rating
)
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
AND rating BETWEEN 0 AND 5;