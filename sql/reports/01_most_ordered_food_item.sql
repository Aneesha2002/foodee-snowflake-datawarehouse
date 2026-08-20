SELECT
    menu_item_id,
    menu_item_name,
    SUM(quantity) AS total_quantity_ordered
FROM FOODEE_DB.PUB.PUB_ORDER_ITEM
GROUP BY
    menu_item_id,
    menu_item_name
ORDER BY total_quantity_ordered DESC;