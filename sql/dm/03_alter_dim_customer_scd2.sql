ALTER TABLE FOODEE_DB.DM.DIM_CUSTOMER
ADD COLUMN effective_start_date DATE,
 effective_end_date DATE,
 is_current BOOLEAN;