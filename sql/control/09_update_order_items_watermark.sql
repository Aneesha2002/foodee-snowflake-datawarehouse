-- ============================================================
-- FOODEE - Update ORDER_ITEMS Watermark
-- ============================================================

UPDATE FOODEE_DB.RAW.FOODEE_LOAD_CONTROL
SET
    LAST_SUCCESSFUL_TIMESTAMP = (
        SELECT BATCH_END_TIMESTAMP
        FROM FOODEE_DB.RAW.FOODEE_BATCH_CONTROL
        WHERE RUN_ID = (
            SELECT RUN_ID
            FROM FOODEE_DB.RAW.FOODEE_BATCH_CONTROL
            WHERE PROCESS_NAME = 'ORDER_ITEMS'
              AND STATUS = 'SUCCESS'
            ORDER BY CREATED_AT DESC
            LIMIT 1
        )
    ),
    UPDATED_AT = CURRENT_TIMESTAMP()

WHERE PROCESS_NAME = 'ORDER_ITEMS';


-- Verify the updated watermark
SELECT *
FROM FOODEE_DB.RAW.FOODEE_LOAD_CONTROL
WHERE PROCESS_NAME = 'ORDER_ITEMS';