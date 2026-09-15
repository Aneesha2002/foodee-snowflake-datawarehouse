-- ============================================================
-- FOODEE - Batch Control Table
-- Stores the boundary for each pipeline run
-- ============================================================

CREATE TABLE IF NOT EXISTS FOODEE_DB.RAW.FOODEE_BATCH_CONTROL
(
    RUN_ID VARCHAR,
    PROCESS_NAME VARCHAR,
    OLD_WATERMARK TIMESTAMP_NTZ,
    BATCH_END_TIMESTAMP TIMESTAMP_NTZ,
    CREATED_AT TIMESTAMP_NTZ
);