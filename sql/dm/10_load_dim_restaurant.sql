INSERT INTO FOODEE_DB.DM.DIM_RESTAURANT
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
FROM FOODEE_DB.STAGE.STG_RESTAURANTS;