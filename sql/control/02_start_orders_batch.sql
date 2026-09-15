-- ============================================================
-- FOODEE - Start Orders Incremental Batch
-- Captures the watermark and fixed batch boundary
-- ============================================================

INSERT INTO FOODEE_DB.RAW.FOODEE_BATCH_CONTROL
(
    RUN_ID,
    PROCESS_NAME,
    OLD_WATERMARK,
    BATCH_END_TIMESTAMP,
    CREATED_AT
)
SELECT
    UUID_STRING(),
    'ORDERS',
    c.LAST_SUCCESSFUL_TIMESTAMP,
    MAX(r.LAST_UPDATED_TIMESTAMP),
    CURRENT_TIMESTAMP()
FROM FOODEE_DB.RAW.FOODEE_LOAD_CONTROL c
CROSS JOIN FOODEE_DB.RAW.RAW_ORDERS r
WHERE c.PROCESS_NAME = 'ORDERS'
GROUP BY c.LAST_SUCCESSFUL_TIMESTAMP;