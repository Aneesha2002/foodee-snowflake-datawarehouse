INSERT INTO FOODEE_DB.STAGE.STG_CUSTOMERS(
    customer_id,
    customer_name,
    city
)
SELECT 
    customer_id,
    customer_name,
    city
FROM FOODEE_DB.RAW.RAW_CUSTOMERS
WHERE customer_id IS NOT NULL AND  customer_name
IS NOT NULL AND city IS NOT NULL;