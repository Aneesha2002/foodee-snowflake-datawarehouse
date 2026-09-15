-- Validate that each customer has at most one current SCD2 record

SELECT
    customer_id,
    COUNT(*) AS current_record_count
FROM FOODEE_DB.DM.DIM_CUSTOMER
WHERE is_current = TRUE
GROUP BY customer_id
HAVING COUNT(*) > 1;