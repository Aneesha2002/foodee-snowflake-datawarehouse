UPDATE FOODEE_DB.DM.DIM_CUSTOMER
SET 
    effective_start_date=CURRENT_DATE(),
    effective_end_date='9999-12-31',
    is_current=TRUE;