INSERT INTO FOODEE_DB.STAGE.STG_ORDERS
(
    order_id,
    customer_id,
    restaurant_id,
    order_date,
    total_amount,
    status,
    last_updated_timestamp
)
SELECT
    order_id,
    customer_id,
    restaurant_id,
    order_date,
    total_amount,
    status,
    last_updated_timestamp
FROM (
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
    WHERE order_id IS NOT NULL
      AND customer_id IS NOT NULL
      AND restaurant_id IS NOT NULL
      AND order_date IS NOT NULL
      AND total_amount IS NOT NULL
      AND status IS NOT NULL
      AND last_updated_timestamp IS NOT NULL
      AND total_amount >= 0
)
WHERE rn = 1;