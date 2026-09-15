UPDATE FOODEE_DB.DM.DIM_CUSTOMER
SET
    effective_end_date= CURRENT_DATE()-1,
    is_current = FALSE
WHERE customer_id = 'C001'
AND is_current = TRUE;

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
    customer_id,
    customer_name,
    'Mumbai',
    CURRENT_DATE(),
    '9999-12-31',
    TRUE
FROM FOODEE_DB.DM.DIM_CUSTOMER
WHERE customer_id='C001'
AND is_current=FALSE
AND effective_end_date = CURRENT_DATE()-1;
