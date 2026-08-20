SELECT
    cuisine,
    SUM(quantity) AS total_quantity_ordered
FROM FOODEE_DB.PUB.PUB_ORDER_ITEM
WHERE order_status <> 'CANCELLED'
GROUP BY cuisine
ORDER BY total_quantity_ordered DESC;
