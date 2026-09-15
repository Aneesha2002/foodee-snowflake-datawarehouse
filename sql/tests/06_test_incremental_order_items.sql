-- ============================================================
-- Second incremental test record
-- ============================================================

INSERT INTO FOODEE_DB.RAW.RAW_ORDER_ITEMS
(
    ORDER_ITEM_ID,
    ORDER_ID,
    MENU_ITEM_ID,
    QUANTITY,
    UNIT_PRICE,
    DISCOUNT_AMOUNT,
    LAST_UPDATED_TIMESTAMP
)
SELECT
    'OI1000',
    'O1000',
    'M002',
    1,
    180.00,
    10.00,
    CURRENT_TIMESTAMP();

SELECT *
FROM FOODEE_DB.RAW.RAW_ORDER_ITEMS
WHERE ORDER_ITEM_ID = 'OI1000';