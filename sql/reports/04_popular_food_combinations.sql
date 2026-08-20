SELECT
    a.menu_item_name AS item_1,
    b.menu_item_name AS item_2,
    COUNT(*) AS times_ordered_together
FROM FOODEE_DB.PUB.PUB_ORDER_ITEM a
JOIN FOODEE_DB.PUB.PUB_ORDER_ITEM b
    ON a.order_id = b.order_id
   AND a.menu_item_id < b.menu_item_id
WHERE a.order_status <> 'CANCELLED'
  AND b.order_status <> 'CANCELLED'
GROUP BY
    a.menu_item_name,
    b.menu_item_name
ORDER BY times_ordered_together DESC;