SELECT
    customer_id,
    customer_name,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT CASE
        WHEN order_status = 'CANCELLED'
        THEN order_id
    END) AS cancelled_orders,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN order_status = 'CANCELLED'
            THEN order_id
        END) * 100.0
        / COUNT(DISTINCT order_id),
        2
    ) AS cancellation_rate_pct
FROM FOODEE_DB.PUB.PUB_ORDER_ITEM
GROUP BY
    customer_id,
    customer_name
HAVING COUNT(DISTINCT order_id) > 0
ORDER BY cancellation_rate_pct DESC;