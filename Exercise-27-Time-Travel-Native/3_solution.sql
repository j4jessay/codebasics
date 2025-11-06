-- ============================================================
-- EXERCISE 27: TIME TRAVEL & ZERO-COPY CLONING
-- FILE: 3_solution.sql
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE EXERCISES_DB;
USE SCHEMA PUBLIC;

-- ============================================================
-- SOLUTION TO TODO 1: UNDERSTAND INITIAL STATE
-- ============================================================

-- Count total customers
SELECT COUNT(*) AS total_customers FROM customers;
-- Expected: 10,000

-- Count CA customers
SELECT COUNT(*) AS ca_customers FROM customers WHERE state = 'CA';
-- Expected: ~963 (varies due to random distribution)

-- Calculate percentage
SELECT
  COUNT(*) AS ca_customers,
  ROUND(COUNT(*) * 100.0 / 10000, 2) AS ca_percentage
FROM customers
WHERE state = 'CA';

-- Capture timestamp BEFORE deletion
SELECT CURRENT_TIMESTAMP() AS timestamp_before_deletion;
-- IMPORTANT: In real scenario, save this value!

-- Alternative: Capture query ID (more reliable)
SELECT COUNT(*) FROM customers WHERE state = 'CA';
SELECT LAST_QUERY_ID() AS query_id_before_deletion;

/*
EXPLANATION:
- We establish baseline numbers for verification
- Timestamp OR query ID must be captured BEFORE deletion
- Query ID approach is more precise than timestamp
*/


-- ============================================================
-- SOLUTION TO TODO 2: DISASTER STRIKES
-- ============================================================

-- Execute the "accidental" deletion
DELETE FROM customers WHERE state = 'CA';

-- Verify deletion
SELECT COUNT(*) AS total_customers FROM customers;
-- Expected: ~9,037 (10,000 - 963)

SELECT COUNT(*) AS ca_customers_remaining FROM customers WHERE state = 'CA';
-- Expected: 0

-- Calculate impact
SELECT
  10000 - COUNT(*) AS customers_lost
FROM customers;

/*
EXPLANATION:
- All CA customers are now gone from the current table
- But they still exist in Time Travel history!
- Traditional databases would require backup restore (hours)
- Snowflake can recover in seconds
*/


-- ============================================================
-- SOLUTION TO TODO 3: TIME TRAVEL QUERY
-- ============================================================

-- Method 1: Using timestamp (less precise)
SELECT COUNT(*) AS ca_customers_historical
FROM customers
AT(TIMESTAMP => '2024-11-06 10:30:00'::TIMESTAMP)
WHERE state = 'CA';

-- Method 2: Using query ID (more precise - RECOMMENDED)
SELECT COUNT(*) AS ca_customers_historical
FROM customers
BEFORE(STATEMENT => '01b38abc-0001-e3f4-0000-000123456789')
WHERE state = 'CA';

/*
EXPLANATION:
- AT(TIMESTAMP => ...) queries data as it existed at that exact time
- BEFORE(STATEMENT => ...) queries data before a specific query executed
- BEFORE with query ID is more reliable (no timezone issues)
- Both show the data IS STILL THERE in Time Travel history!

Why use BEFORE vs AT?
- AT: "Show me data at 10:30 AM"
- BEFORE: "Show me data before this specific change happened"
- BEFORE is more precise for disaster recovery
*/


-- ============================================================
-- SOLUTION TO TODO 4: RECOVER DELETED DATA
-- ============================================================

-- Recovery using BEFORE clause (recommended)
INSERT INTO customers
SELECT * FROM customers
BEFORE(STATEMENT => 'your_query_id_here')
WHERE state = 'CA';

-- Alternative: Recovery using AT clause
INSERT INTO customers
SELECT * FROM customers
AT(TIMESTAMP => '2024-11-06 10:30:00'::TIMESTAMP)
WHERE state = 'CA';

-- Verify recovery
SELECT COUNT(*) AS total_customers FROM customers;
-- Expected: 10,000 (back to original!)

SELECT COUNT(*) AS ca_customers FROM customers WHERE state = 'CA';
-- Expected: ~963 (recovered!)

/*
EXPLANATION:
- INSERT INTO ... SELECT FROM ... with Time Travel recovers the data
- We filter for state = 'CA' to only recover deleted records
- No duplicate checking needed (we deleted ALL CA records)
- Recovery time: ~5-10 seconds total
- Traditional database: 2-4 hours minimum

Why so fast?
- Data wasn't actually deleted, just marked as deleted
- Time Travel maintains references to old versions
- No data movement required - just metadata updates
*/


-- ============================================================
-- SOLUTION TO TODO 5: ZERO-COPY CLONE
-- ============================================================

-- Create zero-copy clone
CREATE OR REPLACE TABLE customers_test CLONE customers;

-- Verify counts match
SELECT
  (SELECT COUNT(*) FROM customers) AS original_count,
  (SELECT COUNT(*) FROM customers_test) AS clone_count,
  'Should be identical' AS note;

-- Test copy-on-write behavior
UPDATE customers_test
SET first_name = 'TimeTravel'
WHERE customer_id = 'CUST00001';

-- Check clone
SELECT * FROM customers_test WHERE customer_id = 'CUST00001';
-- Shows: first_name = 'TimeTravel'

-- Check original (should be unchanged)
SELECT * FROM customers WHERE customer_id = 'CUST00001';
-- Shows: Original first_name (not 'TimeTravel')

/*
EXPLANATION:

Zero-Copy Clone Mechanics:
1. CREATE TABLE ... CLONE creates instant copy
2. Initially shares all data files with original (no storage cost)
3. When you modify clone, only changed blocks are copied (copy-on-write)
4. Original table is never affected by clone modifications

Storage Costs:
- At creation: $0.00 additional cost
- After UPDATE: Only changed micro-partitions consume storage
- Very cost-effective for test/dev environments

Use Cases:
- Create test environment instantly
- Test risky changes safely
- Provide isolated data for developers
- Snapshot data for analysis
- Backup before major changes
*/


-- ============================================================
-- COMPARISON: Traditional vs Snowflake Approach
-- ============================================================

SELECT
  'Traditional Database' AS approach,
  '2-4 hours' AS recovery_time,
  'Restore from backup, extract records, re-import' AS process,
  'Complex, error-prone' AS complexity
UNION ALL
SELECT
  'Snowflake Time Travel' AS approach,
  '30 seconds' AS recovery_time,
  'INSERT ... SELECT with Time Travel' AS process,
  'Simple, reliable' AS complexity;

/*
KEY DIFFERENCES:

Traditional Approach:
- Find latest backup (may be hours old)
- Restore to staging environment
- Identify deleted records
- Export and import
- Verify data integrity
- Total time: 2-4 hours
- Potential data loss: Everything since last backup

Snowflake Approach:
- Query historical data with Time Travel
- INSERT back into table
- Verify recovery
- Total time: 30 seconds
- Data loss: Zero (up to retention period)
*/


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================

/*
1. TIME TRAVEL IS BUILT-IN
   - Standard: 1 day retention
   - Enterprise: Up to 90 days
   - No configuration needed
   - Minimal storage overhead

2. TWO TIME TRAVEL METHODS
   - AT(TIMESTAMP => ...) for specific point in time
   - BEFORE(STATEMENT => ...) for before specific query
   - BEFORE is more precise for recovery

3. DISASTER RECOVERY IN SECONDS
   - Deleted data isn't really gone
   - Query historical state
   - Re-insert with simple SQL
   - No backup restore needed

4. ZERO-COPY CLONING
   - Instant table/schema/database copies
   - No initial storage cost
   - Copy-on-write mechanics
   - Perfect for test environments

5. REAL-WORLD VALUE
   - Protects against human error
   - Enables instant recovery
   - Simplifies testing/development
   - Reduces storage costs for clones

6. LIMITATIONS TO KNOW
   - Retention period limits (1-90 days)
   - Fail-safe adds 7 more days (Snowflake support only)
   - Time Travel doesn't replace backups
   - TRUNCATE and DROP have different behaviors
*/


-- ============================================================
-- SOLUTION COMPLETE!
-- ============================================================

SELECT
  '✓ Solution Complete!' AS status,
  'You mastered Time Travel and Zero-Copy Cloning!' AS achievement,
  'Complete validation_quiz.md to test your knowledge' AS next_step;

/*
CONGRATULATIONS! 🎊

You've learned:
✓ How Time Travel works and why it's revolutionary
✓ AT and BEFORE clauses for querying historical data
✓ Disaster recovery in seconds (not hours)
✓ Zero-copy cloning for instant test environments
✓ Copy-on-write mechanics and cost optimization

This is one of Snowflake's most powerful features!

NEXT STEPS:
1. Compare your solution with this reference
2. Complete validation_quiz.md
3. Try 4_advanced_exploration.sql
4. Apply Time Travel to your own tables
5. Set up test environments with clones!
*/
