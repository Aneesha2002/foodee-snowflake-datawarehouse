-- ============================================================
-- FOODEE - Incremental Load Test Data
-- ============================================================

INSERT INTO FOODEE_DB.RAW.RAW_ORDERS
(
    ORDER_ID,
    CUSTOMER_ID,
    RESTAURANT_ID,
    ORDER_DATE,
    TOTAL_AMOUNT,
    STATUS,
    LAST_UPDATED_TIMESTAMP
)
SELECT
    'O1000',
    'C001',
    'R001',
    CURRENT_DATE(),
    950.00,
    'DELIVERED',
    CURRENT_TIMESTAMP();

SELECT
    ORDER_ID,
    LAST_UPDATED_TIMESTAMP
FROM FOODEE_DB.RAW.RAW_ORDERS
WHERE ORDER_ID = 'O1000';