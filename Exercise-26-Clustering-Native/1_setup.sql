-- ============================================================
-- EXERCISE 26: CLUSTERING KEYS & QUERY PERFORMANCE
-- FILE: 1_setup.sql
-- ============================================================
--
-- PURPOSE: Generate 50,000 sales records for clustering exercise
--
-- INSTRUCTIONS:
-- 1. Copy this entire file
-- 2. Paste into your "Exercise 26 - Setup" worksheet
-- 3. Verify context (top right):
--    Role: SYSADMIN | Warehouse: COMPUTE_WH | Database: EXERCISES_DB | Schema: PUBLIC
-- 4. Click "Run All" or press Ctrl+Enter
-- 5. Wait 10-30 seconds for execution
-- 6. Verify 50,000 records created
--
-- ============================================================

-- Set context
USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE EXERCISES_DB;
USE SCHEMA PUBLIC;

-- Verify we're in the right place
SELECT 'Context verified: ' || CURRENT_DATABASE() || '.' || CURRENT_SCHEMA() AS status;

-- ============================================================
-- GENERATE SALES DATA (50,000 records)
-- ============================================================
--
-- We'll create a table with:
-- - order_id: ORD000001 to ORD050000
-- - customer_id: Random customer IDs (CUST00001-CUST10000)
-- - order_date: Random dates in 2024 (Jan 1 to Oct 27)
-- - order_amount: Random amounts between $10 and $1000
-- - region: 5 regions (US_EAST, US_WEST, EU_NORTH, EU_SOUTH, ASIA)
-- - product_name: 10 product types + random suffix
--
-- This simulates a realistic e-commerce sales table.
-- ============================================================

CREATE OR REPLACE TABLE sales_non_clustered AS
SELECT
  -- Order ID: ORD000001, ORD000002, etc.
  'ORD' || LPAD(SEQ4()::STRING, 6, '0') AS order_id,

  -- Customer ID: CUST00001 to CUST10000 (random)
  'CUST' || LPAD((UNIFORM(1, 10000, RANDOM()) % 10000)::STRING, 5, '0') AS customer_id,

  -- Order date: Random dates in first 300 days of 2024
  DATEADD(day, UNIFORM(0, 300, RANDOM()), '2024-01-01'::DATE) AS order_date,

  -- Order amount: $10.00 to $1000.00
  ROUND(UNIFORM(10, 1000, RANDOM()), 2) AS order_amount,

  -- Region: Evenly distributed across 5 regions
  CASE (UNIFORM(0, 4, RANDOM()))
    WHEN 0 THEN 'US_EAST'
    WHEN 1 THEN 'US_WEST'
    WHEN 2 THEN 'EU_NORTH'
    WHEN 3 THEN 'EU_SOUTH'
    ELSE 'ASIA'
  END AS region,

  -- Product name: 10 product types with random letter suffix
  CASE (UNIFORM(0, 9, RANDOM()))
    WHEN 0 THEN 'Laptop'
    WHEN 1 THEN 'Phone'
    WHEN 2 THEN 'Tablet'
    WHEN 3 THEN 'Monitor'
    WHEN 4 THEN 'Keyboard'
    WHEN 5 THEN 'Mouse'
    WHEN 6 THEN 'Headphones'
    WHEN 7 THEN 'Webcam'
    WHEN 8 THEN 'Speaker'
    ELSE 'Printer'
  END || ' ' || CHR(UNIFORM(65, 90, RANDOM())) AS product_name

FROM TABLE(GENERATOR(ROWCOUNT => 50000));

-- ============================================================
-- VERIFY DATA CREATION
-- ============================================================

-- Check total record count
SELECT
  COUNT(*) AS total_records,
  '✓ Should be 50,000' AS expected
FROM sales_non_clustered;

-- Check data distribution by region
SELECT
  region,
  COUNT(*) AS record_count,
  ROUND(COUNT(*) * 100.0 / 50000, 2) AS percentage,
  '~20% per region' AS expected
FROM sales_non_clustered
GROUP BY region
ORDER BY region;

-- Check date range
SELECT
  MIN(order_date) AS earliest_date,
  MAX(order_date) AS latest_date,
  DATEDIFF(day, MIN(order_date), MAX(order_date)) AS date_span_days,
  '~300 days' AS expected
FROM sales_non_clustered;

-- Check order amount range
SELECT
  MIN(order_amount) AS min_amount,
  MAX(order_amount) AS max_amount,
  ROUND(AVG(order_amount), 2) AS avg_amount,
  '$10 to $1000' AS expected
FROM sales_non_clustered;

-- Sample data (first 10 records)
SELECT *
FROM sales_non_clustered
LIMIT 10;

-- ============================================================
-- SETUP COMPLETE!
-- ============================================================

SELECT
  '✓ Setup Complete!' AS status,
  '50,000 sales records created in SALES_NON_CLUSTERED table' AS message,
  'Next: Open your "Exercise 26 - Challenge" worksheet' AS next_step;

/*
SUCCESS CHECKLIST:
☑ You should see 50,000 total records
☑ Each region should have ~10,000 records (20%)
☑ Dates should span ~300 days in 2024
☑ Order amounts should range from $10 to $1000
☑ Sample data should show realistic orders

If all checks pass, you're ready for the challenge!

NEXT STEPS:
1. Open your "Exercise 26 - Challenge" worksheet
2. Copy the contents of 2_challenge.sql
3. Complete the 5 TODOs
4. Use Query Profile to see the clustering magic!

IMPORTANT NOTE:
This table is NOT clustered - it's just regular Snowflake storage.
You'll create the clustered version in the challenge.
*/
