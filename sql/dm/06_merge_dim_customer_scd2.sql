-- Step 1: Expire current records when customer attributes change

UPDATE FOODEE_DB.DM.DIM_CUSTOMER d 
SET 
    effective_end_date = CURRENT_DATE()-1,
    is_current=FALSE
FROM FOODEE_DB.STAGE.STG_CUSTOMERS s 
WHERE d.customer_id =s.customer_id
AND d.is_current = TRUE
AND (
    d.customer_name <> s.customer_name
    OR d.city <>s.city
);

-- Step 2: Insert the new current version

INSERT INTO FOODEE_DB.DM.DIM_CUSTOMER
(
    customer_id,
    customer_name,
    city,
    effective_start_date,
    effective_end_date,
    is_current
)
SELECT
    s.customer_id,
    s.customer_name,
    s.city,
    CURRENT_DATE(),
    TO_DATE('9999-12-31'),
    TRUE
FROM FOODEE_DB.STAGE.STG_CUSTOMERS s
LEFT JOIN FOODEE_DB.DM.DIM_CUSTOMER d
    ON s.customer_id = d.customer_id
   AND d.is_current = TRUE
WHERE d.customer_sk IS NULL;