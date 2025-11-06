-- ============================================================
-- EXERCISE 27: TIME TRAVEL - ADVANCED EXPLORATION
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE EXERCISES_DB;
USE SCHEMA PUBLIC;

-- ============================================================
-- CHALLENGE 1: Time Travel with OFFSET
-- ============================================================

-- Query data from 5 minutes ago
SELECT COUNT(*) FROM customers AT(OFFSET => -300);

-- Query data from 1 hour ago
SELECT COUNT(*) FROM customers AT(OFFSET => -3600);

/*
EXPERIMENT: What happens if you specify an offset beyond retention?
*/


-- ============================================================
-- CHALLENGE 2: UNDROP Command
-- ============================================================

-- Drop the customers_test table
DROP TABLE IF EXISTS customers_test;

-- Verify it's gone
SHOW TABLES LIKE 'customers_test';

-- UNDROP it!
UNDROP TABLE customers_test;

-- Verify it's back
SELECT COUNT(*) FROM customers_test;

/*
ANALYSIS: How is UNDROP different from Time Travel?
*/


-- ============================================================
-- CHALLENGE 3: Clone Entire Schema
-- ============================================================

-- Create a clone of the entire PUBLIC schema
CREATE SCHEMA public_backup CLONE public;

-- Verify all tables were cloned
SHOW TABLES IN SCHEMA public_backup;

/*
Use case: Instant backup before major schema changes
*/


-- ============================================================
-- CHALLENGE 4: Time Travel for Auditing
-- ============================================================

-- See all changes to a specific customer over time
SELECT *
FROM customers
AT(TIMESTAMP => DATEADD(hour, -1, CURRENT_TIMESTAMP()))
WHERE customer_id = 'CUST00100';

-- Compare with current state
SELECT * FROM customers WHERE customer_id = 'CUST00100';

/*
Use case: Audit trail without additional logging infrastructure
*/


-- ============================================================
-- CHALLENGE 5: Monitor Storage Usage
-- ============================================================

-- Check Time Travel storage
SELECT * FROM TABLE(INFORMATION_SCHEMA.TABLE_STORAGE_METRICS(
  TABLE_NAME => 'CUSTOMERS'
));

/*
Analyze:
- active_bytes: Current data
- time_travel_bytes: Historical data
- failsafe_bytes: Fail-safe protection (7 days after retention)
*/
