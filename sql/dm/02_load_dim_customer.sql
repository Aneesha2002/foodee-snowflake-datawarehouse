INSERT INTO FOODEE_DB.DM.DIM_CUSTOMER
(customer_id,
customer_name,
city)
SELECT
customer_id,
customer_name,
city
FROM FOODEE_DB.STAGE.STG_CUSTOMERS;
