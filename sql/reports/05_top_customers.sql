SELECT
    customer_id,
    customer_name,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(net_amount) AS total_spend
FROM FOODEE_DB.PUB.PUB_ORDER_ITEM
WHERE order_status <> 'CANCELLED'
GROUP BY
    customer_id,
    customer_name
ORDER BY total_orders DESC, total_spend DESC;