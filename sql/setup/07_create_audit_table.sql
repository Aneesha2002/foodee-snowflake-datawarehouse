-- ============================================================
-- FOODEE - Pipeline Audit Table
-- ============================================================

CREATE TABLE IF NOT EXISTS FOODEE_DB.RAW.FOODEE_PIPELINE_AUDIT
(
    RUN_ID VARCHAR,
    PROCESS_NAME VARCHAR,
    START_TIME TIMESTAMP_NTZ,
    END_TIME TIMESTAMP_NTZ,
    ROWS_PROCESSED NUMBER,
    STATUS VARCHAR,
    ERROR_MESSAGE VARCHAR
);
