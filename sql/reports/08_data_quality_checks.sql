-- FOODEE Data Quality Validation
-- Validates dimensional integrity, fact integrity,
-- SCD2 consistency, calculations, and layer reconciliation.

-- 1. Check duplicate customer dimension records for the same SK
SELECT
    customer_sk,
    COUNT(*) AS row_count
FROM FOODEE_DB.DM.DIM_CUSTOMER
GROUP BY customer_sk
HAVING COUNT(*) > 1;


-- 2. Check duplicate restaurant dimension records for the same SK
SELECT
    restaurant_sk,
    COUNT(*) AS row_count
FROM FOODEE_DB.DM.DIM_RESTAURANT
GROUP BY restaurant_sk
HAVING COUNT(*) > 1;


-- 3. Check duplicate menu item dimension records for the same SK
SELECT
    menu_item_sk,
    COUNT(*) AS row_count
FROM FOODEE_DB.DM.DIM_MENU_ITEM
GROUP BY menu_item_sk
HAVING COUNT(*) > 1;


-- 4. Check duplicate order items in the fact
SELECT
    order_item_id,
    COUNT(*) AS row_count
FROM FOODEE_DB.DM.FACT_ORDER_ITEM
GROUP BY order_item_id
HAVING COUNT(*) > 1;


-- 5. Check orphaned customer SKs
SELECT f.customer_sk
FROM FOODEE_DB.DM.FACT_ORDER_ITEM f
LEFT JOIN FOODEE_DB.DM.DIM_CUSTOMER c
    ON f.customer_sk = c.customer_sk
WHERE c.customer_sk IS NULL;


-- 6. Check orphaned restaurant SKs
SELECT f.restaurant_sk
FROM FOODEE_DB.DM.FACT_ORDER_ITEM f
LEFT JOIN FOODEE_DB.DM.DIM_RESTAURANT r
    ON f.restaurant_sk = r.restaurant_sk
WHERE r.restaurant_sk IS NULL;


-- 7. Check orphaned menu item SKs
SELECT f.menu_item_sk
FROM FOODEE_DB.DM.FACT_ORDER_ITEM f
LEFT JOIN FOODEE_DB.DM.DIM_MENU_ITEM m
    ON f.menu_item_sk = m.menu_item_sk
WHERE m.menu_item_sk IS NULL;


-- 8. Check critical NULLs in the fact
SELECT *
FROM FOODEE_DB.DM.FACT_ORDER_ITEM
WHERE order_item_id IS NULL
   OR order_id IS NULL
   OR customer_sk IS NULL
   OR restaurant_sk IS NULL
   OR menu_item_sk IS NULL
   OR order_date IS NULL;


-- 9. Check fact amount calculations
SELECT *
FROM FOODEE_DB.DM.FACT_ORDER_ITEM
WHERE gross_amount <> quantity * unit_price
   OR net_amount <> gross_amount - discount_amount;


-- 10. Check SCD2 date validity
SELECT *
FROM FOODEE_DB.DM.DIM_CUSTOMER
WHERE effective_end_date < effective_start_date;


-- 11. Check multiple current customer records
SELECT
    customer_id,
    COUNT(*) AS current_record_count
FROM FOODEE_DB.DM.DIM_CUSTOMER
WHERE is_current = TRUE
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- 12. Check PREPUB/PUB row-count consistency
SELECT
    (SELECT COUNT(*)
     FROM FOODEE_DB.DM.FACT_ORDER_ITEM) AS fact_count,

    (SELECT COUNT(*)
     FROM FOODEE_DB.PREPUB.PREPUB_ORDER_ITEM) AS prepub_count,

    (SELECT COUNT(*)
     FROM FOODEE_DB.PUB.PUB_ORDER_ITEM) AS pub_count;