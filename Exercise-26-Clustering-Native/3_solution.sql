-- ============================================================
-- EXERCISE 26: CLUSTERING KEYS & QUERY PERFORMANCE
-- FILE: 3_solution.sql
-- ============================================================
--
-- PURPOSE: Reference solution for the clustering exercise
--
-- INSTRUCTIONS:
-- 1. Complete 2_challenge.sql first!
-- 2. Compare your solution with this reference
-- 3. Note any differences in approach
-- 4. Run this to see expected results
--
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE EXERCISES_DB;
USE SCHEMA PUBLIC;

-- ============================================================
-- SOLUTION TO TODO 1: ANALYZE NON-CLUSTERED PERFORMANCE
-- ============================================================

-- Step 1: Set query tag for tracking
ALTER SESSION SET QUERY_TAG = 'exercise_non_clustered';

-- Step 2: Query the non-clustered table
SELECT *
FROM sales_non_clustered
WHERE region = 'US_EAST'
  AND order_date >= '2024-10-01'
  AND order_date < '2024-11-01';

/*
EXPLANATION:
- We filter by both region and date to simulate a realistic analyst query
- The non-clustered table must scan most/all partitions to find matching rows
- Even though only ~2% of data matches, Snowflake doesn't know where it is
- Result: High partition scanning, slower query

EXPECTED RESULTS:
- Execution time: 800-1200ms (varies by warehouse size)
- Partitions scanned: 400-500 out of 500 total (~95-100%)
- Rows returned: ~900-1100 (about 2% of 50,000)

WHY IS THIS SLOW?
Snowflake must scan nearly every partition because:
1. Data is randomly distributed across partitions
2. No clustering means no organization by region or date
3. Partition pruning can't work effectively
*/

-- Reset query tag
ALTER SESSION UNSET QUERY_TAG;


-- ============================================================
-- SOLUTION TO TODO 2: CREATE CLUSTERED TABLE
-- ============================================================

/*
DESIGN DECISION ANALYSIS:

Question: Which columns should be clustering keys?
Answer: order_date and region

Why?
- These are the most commonly filtered columns in analyst queries
- They have good cardinality (date has 300 values, region has 5)
- They're stable (don't change after insert)

Question: Column order - (order_date, region) or (region, order_date)?
Answer: (order_date, region)

Why?
- order_date is more selective (300 distinct values vs 5)
- Queries often filter by date FIRST, then optionally by region
- Snowflake organizes partitions primarily by the first clustering key
- Better granularity with date first

Question: Should we include more columns?
Answer: No

Why?
- 2 clustering keys is typically optimal
- Adding more (like product_name) provides diminishing returns
- More clustering keys = more maintenance overhead
- Keep it simple and focused on actual query patterns
*/

CREATE OR REPLACE TABLE sales_clustered
CLUSTER BY (order_date, region)
AS SELECT * FROM sales_non_clustered;

/*
EXPLANATION:
- CLUSTER BY clause tells Snowflake how to organize micro-partitions
- Data with similar dates and regions will be stored together
- Enables partition pruning when filtering by these columns
- Snowflake maintains clustering automatically on INSERT/UPDATE

WHAT HAPPENS INTERNALLY:
1. Snowflake reads all data from sales_non_clustered
2. Re-organizes it by order_date, then by region within each date
3. Creates new micro-partitions with clustered data
4. Stores clustering metadata for future queries
*/


-- ============================================================
-- SOLUTION TO TODO 3: MEASURE CLUSTERING QUALITY
-- ============================================================

SELECT SYSTEM$CLUSTERING_DEPTH('sales_clustered', '(order_date, region)') AS clustering_depth;

/*
EXPLANATION:
- SYSTEM$CLUSTERING_DEPTH returns a number indicating clustering quality
- It measures the average overlap of data across partitions
- Lower values = better clustering = more efficient pruning

EXPECTED RESULT: 1.0 to 1.5

INTERPRETATION:
- Our result is < 2, which is EXCELLENT
- This means our data is well-organized by date and region
- Queries filtering by these columns will benefit from strong pruning

WHY IS OUR DEPTH SO LOW?
- Fresh table with good key selection
- Data distribution works well with our keys
- Table size is moderate (not too large to fragment)

WHEN WOULD DEPTH BE HIGHER?
- Very large tables with many updates
- Poor clustering key choice (high cardinality like customer_id)
- Natural data distribution doesn't align with keys
- Table hasn't been reclustered recently
*/

-- Check clustering information (more detailed view)
SELECT SYSTEM$CLUSTERING_INFORMATION('sales_clustered', '(order_date, region)') AS clustering_info;

/*
This returns JSON with additional details:
- average_depth: Same as CLUSTERING_DEPTH
- partition_depth_histogram: Distribution of depths
- Useful for understanding clustering health
*/


-- ============================================================
-- SOLUTION TO TODO 4: QUERY CLUSTERED TABLE
-- ============================================================

-- Step 1: Set query tag
ALTER SESSION SET QUERY_TAG = 'exercise_clustered';

-- Step 2: Query the clustered table (SAME query as TODO 1)
SELECT *
FROM sales_clustered
WHERE region = 'US_EAST'
  AND order_date >= '2024-10-01'
  AND order_date < '2024-11-01';

/*
EXPLANATION:
- IDENTICAL query to TODO 1, except table name
- Snowflake uses clustering metadata to prune partitions
- Only scans partitions containing October 2024 data from US_EAST

EXPECTED RESULTS:
- Execution time: 200-400ms (~3-5x faster than non-clustered)
- Partitions scanned: 10-30 out of 500 total (~2-5%)
- Rows returned: ~900-1100 (same as non-clustered)

WHY IS THIS FASTER?
1. Clustering metadata tells Snowflake which partitions have relevant data
2. Partition pruning eliminates 95-98% of partitions before scanning
3. Less data to read = faster query = lower cost

WHAT YOU'LL SEE IN QUERY PROFILE:
- "Partitions scanned" bar will be much smaller
- "Partitions total" stays the same (500)
- "Pruned" partitions shown in gray
- Dramatic visual difference from non-clustered query
*/

-- Reset query tag
ALTER SESSION UNSET QUERY_TAG;


-- ============================================================
-- SOLUTION TO TODO 5: QUERY HISTORY ANALYSIS
-- ============================================================

-- Basic comparison
SELECT
  query_tag,
  execution_time / 1000 AS execution_seconds,
  partitions_scanned,
  partitions_total,
  ROUND((partitions_scanned::FLOAT / NULLIF(partitions_total, 0)) * 100, 2) AS scan_percentage,
  bytes_scanned / 1024 / 1024 AS mb_scanned
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
WHERE query_tag IN ('exercise_non_clustered', 'exercise_clustered')
  AND start_time >= DATEADD(hour, -1, CURRENT_TIMESTAMP())
  AND query_text LIKE '%sales_%clustered%'
  AND query_text NOT LIKE '%INFORMATION_SCHEMA%'
ORDER BY start_time;

/*
EXPLANATION:
- INFORMATION_SCHEMA.QUERY_HISTORY() contains metadata about all queries
- We filter by our query tags to find our specific test queries
- Shows side-by-side comparison of performance metrics

EXPECTED OUTPUT:
query_tag                 | execution_seconds | partitions_scanned | partitions_total | scan_percentage | mb_scanned
--------------------------|-------------------|--------------------| -----------------|-----------------|------------
exercise_non_clustered    | 1.2               | 480                | 500              | 96.00           | 45
exercise_clustered        | 0.3               | 15                 | 500              | 3.00            | 2

KEY INSIGHTS:
- 4x faster execution time
- 32x fewer partitions scanned
- 22x less data processed (lower cost!)
*/


-- BONUS: Calculate improvement ratio with more details
WITH query_metrics AS (
  SELECT
    query_tag,
    query_text,
    execution_time / 1000 AS execution_seconds,
    partitions_scanned,
    partitions_total,
    bytes_scanned / 1024 / 1024 AS mb_scanned,
    start_time
  FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
  WHERE query_tag IN ('exercise_non_clustered', 'exercise_clustered')
    AND start_time >= DATEADD(hour, -1, CURRENT_TIMESTAMP())
    AND query_text LIKE '%sales_%clustered%'
    AND query_text NOT LIKE '%INFORMATION_SCHEMA%'
),
comparison AS (
  SELECT
    MAX(CASE WHEN query_tag = 'exercise_non_clustered' THEN execution_seconds END) AS non_clustered_time,
    MAX(CASE WHEN query_tag = 'exercise_clustered' THEN execution_seconds END) AS clustered_time,
    MAX(CASE WHEN query_tag = 'exercise_non_clustered' THEN partitions_scanned END) AS non_clustered_partitions,
    MAX(CASE WHEN query_tag = 'exercise_clustered' THEN partitions_scanned END) AS clustered_partitions,
    MAX(CASE WHEN query_tag = 'exercise_non_clustered' THEN mb_scanned END) AS non_clustered_mb,
    MAX(CASE WHEN query_tag = 'exercise_clustered' THEN mb_scanned END) AS clustered_mb
  FROM query_metrics
)
SELECT
  non_clustered_time,
  clustered_time,
  ROUND(non_clustered_time / NULLIF(clustered_time, 0), 2) AS time_improvement_ratio,
  non_clustered_partitions,
  clustered_partitions,
  ROUND(non_clustered_partitions::FLOAT / NULLIF(clustered_partitions, 0), 2) AS partition_reduction_ratio,
  non_clustered_mb,
  clustered_mb,
  ROUND(non_clustered_mb / NULLIF(clustered_mb, 0), 2) AS data_scan_reduction_ratio
FROM comparison;

/*
EXPECTED OUTPUT:
non_clustered_time | clustered_time | time_improvement_ratio | partition_reduction_ratio | data_scan_reduction_ratio
-------------------|----------------|------------------------|---------------------------|---------------------------
1.2                | 0.3            | 4.0                    | 32.0                      | 22.5

INTERPRETATION:
- Queries are 4x faster with clustering
- We scan 32x fewer partitions
- We process 22x less data
- This translates to significant cost savings at scale!
*/


-- ============================================================
-- ADDITIONAL ANALYSIS: VISUALIZE THE DIFFERENCE
-- ============================================================

-- Compare all query metrics side by side
SELECT
  '📊 PERFORMANCE COMPARISON' AS analysis,
  '========================' AS separator;

SELECT
  'Non-Clustered Query' AS query_type,
  '~1000ms' AS typical_execution_time,
  '480/500 (96%)' AS partitions_scanned,
  'Scans almost all partitions' AS behavior
UNION ALL
SELECT
  'Clustered Query' AS query_type,
  '~250ms' AS typical_execution_time,
  '15/500 (3%)' AS partitions_scanned,
  'Prunes 97% of partitions' AS behavior;

SELECT
  '✓ Clustering Result: 3-5x Performance Improvement!' AS conclusion,
  'Partition pruning is the key to Snowflake query optimization' AS key_learning;


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================

/*
1. CLUSTERING ENABLES PARTITION PRUNING
   - Snowflake skips irrelevant partitions automatically
   - Reduces data scanning by 95%+
   - Faster queries, lower costs

2. CHOOSE CLUSTERING KEYS WISELY
   - Use columns you filter by most often
   - Start with most selective column
   - Typically 2 keys is optimal (max 3-4)

3. CLUSTERING DEPTH MATTERS
   - < 2 is excellent
   - Monitor with SYSTEM$CLUSTERING_DEPTH
   - Reclustering happens automatically but has a cost

4. QUERY PROFILE IS YOUR BEST FRIEND
   - Visualizes partition pruning
   - Shows execution bottlenecks
   - Essential for performance tuning

5. NOT EVERY TABLE NEEDS CLUSTERING
   - Small tables (< 100MB): Clustering overhead > benefit
   - Tables you never filter: No partition pruning benefit
   - Tables with high DML: Clustering maintenance is expensive

6. REAL-WORLD IMPACT
   - 3-5x query speedup (typical)
   - 95%+ reduction in data scanning
   - Significant cost savings for large tables
   - Better user experience for analysts
*/


-- ============================================================
-- SOLUTION COMPLETE!
-- ============================================================

SELECT
  '🎉 Solution Review Complete!' AS status,
  'Check validation_quiz.md to test your understanding' AS next_step,
  'Try 4_advanced_exploration.sql for bonus challenges' AS optional;

/*
CONGRATULATIONS! 🎊

You've learned:
✓ How Snowflake's micro-partitioning works
✓ How to create tables with clustering keys
✓ How to measure clustering quality
✓ How to use Query Profile for performance analysis
✓ How clustering dramatically improves query performance

NEXT STEPS:
1. Compare your solution with this reference
2. Review any concepts you're unsure about
3. Complete validation_quiz.md
4. Try the advanced exploration challenges
5. Apply clustering to your own tables!

Questions? Review the exercise README or Snowflake documentation.
*/
