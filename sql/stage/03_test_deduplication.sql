SELECT
    order_id,
    customer_id,
    restaurant_id,
    order_date,
    total_amount,
    status,
    last_updated_timestamp,
    ROW_NUMBER() OVER (
        PARTITION BY order_id
        ORDER BY last_updated_timestamp DESC
    ) AS rn
FROM FOODEE_DB.RAW.RAW_ORDERS
ORDER BY order_id, rn;