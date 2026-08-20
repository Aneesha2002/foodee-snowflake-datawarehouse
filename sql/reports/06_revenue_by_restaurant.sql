SELECT
    restaurant_id,
    restaurant_name,
    SUM(quantity) AS total_items_sold,
    SUM(gross_amount) AS gross_revenue,
    SUM(discount_amount) AS total_discount,
    SUM(net_amount) AS net_revenue
FROM FOODEE_DB.PUB.PUB_ORDER_ITEM
WHERE order_status <> 'CANCELLED'
GROUP BY
    restaurant_id,
    restaurant_name
ORDER BY net_revenue DESC;