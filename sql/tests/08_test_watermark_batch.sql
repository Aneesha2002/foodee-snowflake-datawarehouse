-- ============================================================
-- FOODEE - Verify Incremental Batch
-- ============================================================

SELECT
    c.LAST_SUCCESSFUL_TIMESTAMP AS WATERMARK,
    r.ORDER_ID,
    r.LAST_UPDATED_TIMESTAMP AS ORDER_TIMESTAMP,
    CASE
        WHEN r.LAST_UPDATED_TIMESTAMP > c.LAST_SUCCESSFUL_TIMESTAMP
        THEN 'INCREMENTAL'
        ELSE 'ALREADY_PROCESSED'
    END AS STATUS
FROM FOODEE_DB.RAW.FOODEE_LOAD_CONTROL c
JOIN FOODEE_DB.RAW.RAW_ORDERS r
    ON r.ORDER_ID = 'O1000'
WHERE c.PROCESS_NAME = 'ORDERS';