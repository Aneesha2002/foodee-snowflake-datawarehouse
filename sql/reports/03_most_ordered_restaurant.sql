SELECT
    restaurant_id,
    restaurant_name,
    SUM(quantity) AS total_quantity_ordered
FROM FOODEE_DB.PUB.PUB_ORDER_ITEM
WHERE order_status <> 'CANCELLED'
GROUP BY 
    restaurant_id,
    restaurant_name
ORDER BY total_quantity_ordered DESC;
