-- ============================================================
-- EXERCISE 27: TIME TRAVEL & ZERO-COPY CLONING
-- FILE: 1_setup.sql
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE EXERCISES_DB;
USE SCHEMA PUBLIC;

SELECT 'Context verified: ' || CURRENT_DATABASE() || '.' || CURRENT_SCHEMA() AS status;

-- ============================================================
-- GENERATE CUSTOMER DATA (10,000 records)
-- ============================================================

CREATE OR REPLACE TABLE customers AS
SELECT
  'CUST' || LPAD(SEQ4()::STRING, 5, '0') AS customer_id,

  -- Generate realistic first names
  CASE (UNIFORM(0, 9, RANDOM()))
    WHEN 0 THEN 'John' WHEN 1 THEN 'Sarah' WHEN 2 THEN 'Michael'
    WHEN 3 THEN 'Jennifer' WHEN 4 THEN 'David' WHEN 5 THEN 'Emily'
    WHEN 6 THEN 'Robert' WHEN 7 THEN 'Lisa' WHEN 8 THEN 'William'
    ELSE 'Jessica'
  END AS first_name,

  -- Generate realistic last names
  CASE (UNIFORM(0, 9, RANDOM()))
    WHEN 0 THEN 'Smith' WHEN 1 THEN 'Johnson' WHEN 2 THEN 'Williams'
    WHEN 3 THEN 'Brown' WHEN 4 THEN 'Jones' WHEN 5 THEN 'Garcia'
    WHEN 6 THEN 'Miller' WHEN 7 THEN 'Davis' WHEN 8 THEN 'Rodriguez'
    ELSE 'Martinez'
  END AS last_name,

  -- Generate email
  'customer' || SEQ4() || '@email.com' AS email,

  -- 10 US states
  CASE (UNIFORM(0, 9, RANDOM()))
    WHEN 0 THEN 'CA' WHEN 1 THEN 'NY' WHEN 2 THEN 'TX'
    WHEN 3 THEN 'FL' WHEN 4 THEN 'IL' WHEN 5 THEN 'PA'
    WHEN 6 THEN 'OH' WHEN 7 THEN 'GA' WHEN 8 THEN 'NC'
    ELSE 'MI'
  END AS state,

  -- Signup dates over last 2 years
  DATEADD(day, -UNIFORM(0, 730, RANDOM()), CURRENT_DATE()) AS signup_date,

  -- Account status
  CASE (UNIFORM(0, 2, RANDOM()))
    WHEN 0 THEN 'active'
    WHEN 1 THEN 'inactive'
    ELSE 'suspended'
  END AS account_status

FROM TABLE(GENERATOR(ROWCOUNT => 10000));

-- ============================================================
-- VERIFY DATA CREATION
-- ============================================================

SELECT COUNT(*) AS total_customers, '✓ Should be 10,000' AS expected
FROM customers;

SELECT
  state,
  COUNT(*) AS customer_count,
  ROUND(COUNT(*) * 100.0 / 10000, 1) AS percentage
FROM customers
GROUP BY state
ORDER BY state;

SELECT COUNT(*) AS ca_customers, '✓ Remember this number!' AS note
FROM customers
WHERE state = 'CA';

SELECT * FROM customers LIMIT 10;

-- ============================================================
-- IMPORTANT: Wait for Time Travel History
-- ============================================================

SELECT
  'Waiting 15 seconds for Time Travel history...' AS status,
  'This establishes a baseline for our Time Travel exercise' AS reason;

-- In a real worksheet, you'd wait here. The data is now ready.

SELECT
  '✓ Setup Complete!' AS status,
  '10,000 customers created' AS message,
  'Note the CA customer count above!' AS important,
  'Next: Open "Exercise 27 - Challenge" worksheet' AS next_step;

/*
SUCCESS CHECKLIST:
☑ 10,000 total customers created
☑ Each state has ~1,000 customers (~10%)
☑ CA customer count recorded (you'll need this!)
☑ Time Travel history established

NEXT STEPS:
1. **IMPORTANT:** Note the number of CA customers above
2. Wait at least 10-15 seconds before starting challenge
3. Open "Exercise 27 - Challenge" worksheet
4. Copy 2_challenge.sql and begin!
*/
