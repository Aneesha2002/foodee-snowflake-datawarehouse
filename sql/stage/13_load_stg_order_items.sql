INSERT INTO FOODEE_DB.STAGE.STG_ORDER_ITEMS(
    order_item_id, 
    order_id,   
    menu_item_id,   
    quantity,     
    unit_price,    
    discount_amount 
)
SELECT 
    order_item_id, 
    order_id,   
    menu_item_id,   
    quantity,     
    unit_price,    
    discount_amount 
FROM FOODEE_DB.RAW.RAW_ORDER_ITEMS
WHERE  order_item_id IS NOT NULL
AND order_id IS NOT NULL
AND menu_item_id IS NOT NULL
AND quantity >0
AND unit_price >0    
AND discount_amount >=0;