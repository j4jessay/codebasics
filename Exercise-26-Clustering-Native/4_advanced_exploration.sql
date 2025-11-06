-- ============================================================
-- EXERCISE 26: CLUSTERING KEYS & QUERY PERFORMANCE
-- FILE: 4_advanced_exploration.sql
-- ============================================================
--
-- PURPOSE: Advanced challenges and experiments with clustering
--
-- PREREQUISITES:
-- - Completed 2_challenge.sql
-- - Reviewed 3_solution.sql
-- - Comfortable with clustering concepts
--
-- INSTRUCTIONS:
-- Pick any challenges that interest you and experiment!
-- There are no "right" answers - it's about exploration.
--
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE EXERCISES_DB;
USE SCHEMA PUBLIC;

-- ============================================================
-- CHALLENGE 1: Reverse Clustering Key Order
-- ============================================================

/*
EXPERIMENT: What happens if we reverse the clustering key order?

Current: CLUSTER BY (order_date, region)
Experiment: CLUSTER BY (region, order_date)

HYPOTHESIS:
Write your prediction before running:
______________________________________________________________
______________________________________________________________
*/

-- Create table with reversed clustering keys
CREATE OR REPLACE TABLE sales_clustered_reversed
CLUSTER BY (region, order_date)
AS SELECT * FROM sales_non_clustered;

-- Check clustering depth
SELECT SYSTEM$CLUSTERING_DEPTH('sales_clustered_reversed', '(region, order_date)') AS clustering_depth;

-- Run the same test query
ALTER SESSION SET QUERY_TAG = 'exercise_reversed_clustering';

SELECT *
FROM sales_clustered_reversed
WHERE region = 'US_EAST'
  AND order_date >= '2024-10-01'
  AND order_date < '2024-11-01';

ALTER SESSION UNSET QUERY_TAG;

/*
ANALYSIS QUESTIONS:
1. Is clustering depth different? Why or why not?
2. Is query performance different?
3. Which order is better for our query pattern?
4. When would (region, order_date) be better than (order_date, region)?
*/


-- ============================================================
-- CHALLENGE 2: Single Column Clustering
-- ============================================================

/*
EXPERIMENT: Does clustering by just one column work as well?

Test: CLUSTER BY (order_date) only - no region
*/

CREATE OR REPLACE TABLE sales_clustered_single
CLUSTER BY (order_date)
AS SELECT * FROM sales_non_clustered;

-- Check clustering depth
SELECT SYSTEM$CLUSTERING_DEPTH('sales_clustered_single', '(order_date)') AS clustering_depth;

-- Run the same test query
ALTER SESSION SET QUERY_TAG = 'exercise_single_clustering';

SELECT *
FROM sales_clustered_single
WHERE region = 'US_EAST'
  AND order_date >= '2024-10-01'
  AND order_date < '2024-11-01';

ALTER SESSION UNSET QUERY_TAG;

/*
ANALYSIS QUESTIONS:
1. Can Snowflake still prune partitions when filtering by region?
2. How does this compare to dual-column clustering?
3. When is single-column clustering sufficient?
*/


-- ============================================================
-- CHALLENGE 3: Wrong Clustering Keys
-- ============================================================

/*
EXPERIMENT: What happens with poorly chosen clustering keys?

Test: Cluster by columns we DON'T filter by
*/

CREATE OR REPLACE TABLE sales_clustered_wrong
CLUSTER BY (customer_id, product_name)
AS SELECT * FROM sales_non_clustered;

-- Check clustering depth
SELECT SYSTEM$CLUSTERING_DEPTH('sales_clustered_wrong', '(customer_id, product_name)') AS clustering_depth;

-- Run the same test query
ALTER SESSION SET QUERY_TAG = 'exercise_wrong_clustering';

SELECT *
FROM sales_clustered_wrong
WHERE region = 'US_EAST'
  AND order_date >= '2024-10-01'
  AND order_date < '2024-11-01';

ALTER SESSION UNSET QUERY_TAG;

/*
ANALYSIS QUESTIONS:
1. Does this help our query at all?
2. What does the clustering depth tell us?
3. Why is it important to match clustering keys to query patterns?
*/


-- ============================================================
-- CHALLENGE 4: Compare All Approaches
-- ============================================================

-- Query history comparison
SELECT
  query_tag,
  execution_time / 1000 AS execution_seconds,
  partitions_scanned,
  partitions_total,
  ROUND((partitions_scanned::FLOAT / NULLIF(partitions_total, 0)) * 100, 2) AS scan_percentage
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
WHERE query_tag LIKE 'exercise_%clustering%'
  AND start_time >= DATEADD(hour, -1, CURRENT_TIMESTAMP())
  AND query_text LIKE '%sales_clustered%'
  AND query_text NOT LIKE '%INFORMATION_SCHEMA%'
ORDER BY execution_time;

/*
RANKING:
Based on your results, rank the clustering approaches from best to worst:

1. _________________ (fastest, least partitions scanned)
2. _________________
3. _________________
4. _________________
5. _________________ (slowest, most partitions scanned)
*/


-- ============================================================
-- CHALLENGE 5: Different Query Patterns
-- ============================================================

/*
EXPERIMENT: Test clustering with different types of queries

Our clustering: CLUSTER BY (order_date, region)
*/

-- Query Pattern A: Filter by date only (no region)
SELECT COUNT(*), AVG(order_amount)
FROM sales_clustered
WHERE order_date >= '2024-10-01'
  AND order_date < '2024-11-01';

/*
Does clustering help? ___________
Why or why not? ___________
*/


-- Query Pattern B: Filter by region only (no date)
SELECT COUNT(*), AVG(order_amount)
FROM sales_clustered
WHERE region = 'US_EAST';

/*
Does clustering help? ___________
Why or why not? ___________
*/


-- Query Pattern C: Filter by neither clustering column
SELECT COUNT(*), AVG(order_amount)
FROM sales_clustered
WHERE product_name LIKE 'Laptop%';

/*
Does clustering help? ___________
Why or why not? ___________
*/


-- Query Pattern D: Aggregation with GROUP BY
SELECT
  region,
  DATE_TRUNC('month', order_date) AS month,
  COUNT(*) AS order_count,
  SUM(order_amount) AS total_revenue
FROM sales_clustered
GROUP BY region, DATE_TRUNC('month', order_date)
ORDER BY region, month;

/*
Does clustering help GROUP BY operations?
Hypothesis: ___________
*/


-- ============================================================
-- CHALLENGE 6: Clustering Maintenance
-- ============================================================

/*
EXPERIMENT: What happens when we insert new data?

Clustering is not free - it requires maintenance as data changes.
*/

-- Insert random new orders
INSERT INTO sales_clustered
SELECT
  'ORD' || LPAD((50000 + SEQ4())::STRING, 6, '0') AS order_id,
  'CUST' || LPAD((UNIFORM(1, 10000, RANDOM()) % 10000)::STRING, 5, '0') AS customer_id,
  DATEADD(day, UNIFORM(0, 30, RANDOM()), CURRENT_DATE()) AS order_date,
  ROUND(UNIFORM(10, 1000, RANDOM()), 2) AS order_amount,
  CASE (UNIFORM(0, 4, RANDOM()))
    WHEN 0 THEN 'US_EAST' WHEN 1 THEN 'US_WEST' WHEN 2 THEN 'EU_NORTH'
    WHEN 3 THEN 'EU_SOUTH' ELSE 'ASIA'
  END AS region,
  CASE (UNIFORM(0, 9, RANDOM()))
    WHEN 0 THEN 'Laptop' WHEN 1 THEN 'Phone' WHEN 2 THEN 'Tablet'
    WHEN 3 THEN 'Monitor' WHEN 4 THEN 'Keyboard' WHEN 5 THEN 'Mouse'
    WHEN 6 THEN 'Headphones' WHEN 7 THEN 'Webcam' WHEN 8 THEN 'Speaker'
    ELSE 'Printer'
  END AS product_name
FROM TABLE(GENERATOR(ROWCOUNT => 5000));

-- Check clustering depth after insert
SELECT SYSTEM$CLUSTERING_DEPTH('sales_clustered', '(order_date, region)') AS clustering_depth_after_insert;

/*
ANALYSIS:
1. Did clustering depth change after inserting 5,000 new rows?
   Before: _________
   After: _________

2. Does Snowflake automatically recluster the table?
   Answer: _________

3. How can you monitor automatic reclustering?
   (Hint: Check AUTOMATIC_CLUSTERING_HISTORY view)
*/

SELECT *
FROM TABLE(INFORMATION_SCHEMA.AUTOMATIC_CLUSTERING_HISTORY(
  DATE_RANGE_START => DATEADD(day, -1, CURRENT_TIMESTAMP()),
  TABLE_NAME => 'SALES_CLUSTERED'
));


-- ============================================================
-- CHALLENGE 7: Cost Analysis
-- ============================================================

/*
EXPERIMENT: Understanding the cost trade-offs of clustering
*/

-- Check table storage and clustering cost
SELECT
  table_name,
  active_bytes / 1024 / 1024 AS storage_mb,
  time_travel_bytes / 1024 / 1024 AS time_travel_mb,
  failsafe_bytes / 1024 / 1024 AS failsafe_mb
FROM TABLE(INFORMATION_SCHEMA.TABLE_STORAGE_METRICS(
  TABLE_NAME => 'SALES_CLUSTERED'
));

/*
COST CONSIDERATIONS:

1. Storage Cost:
   - Clustered vs non-clustered storage is the same
   - No additional storage penalty for clustering

2. Compute Cost for Clustering:
   - Initial clustering: Cost to create clustered table
   - Automatic reclustering: Ongoing cost as data changes
   - Query savings: Lower cost per query (less data scanned)

3. Break-Even Analysis:
   When is clustering worth it?

   IF: (query_cost_savings * query_frequency) > reclustering_cost
   THEN: Clustering is beneficial

   Best for:
   - Large tables (> 1GB)
   - Frequently queried tables
   - Stable data (few updates/inserts)

   Not worth it for:
   - Small tables (< 100MB)
   - Rarely queried tables
   - Highly volatile data (constant changes)
*/


-- ============================================================
-- CHALLENGE 8: Multi-Column Filter Optimization
-- ============================================================

/*
EXPERIMENT: How does clustering handle multiple filter combinations?
*/

-- Test different filter combinations
ALTER SESSION SET QUERY_TAG = 'multi_filter_test';

-- Both clustering columns
SELECT COUNT(*) FROM sales_clustered
WHERE order_date = '2024-05-15' AND region = 'US_EAST';

-- First clustering column only
SELECT COUNT(*) FROM sales_clustered
WHERE order_date = '2024-05-15';

-- Second clustering column only
SELECT COUNT(*) FROM sales_clustered
WHERE region = 'US_EAST';

-- Neither clustering column
SELECT COUNT(*) FROM sales_clustered
WHERE customer_id = 'CUST00100';

ALTER SESSION UNSET QUERY_TAG;

-- Compare partition pruning
SELECT
  query_text,
  partitions_scanned,
  partitions_total
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
WHERE query_tag = 'multi_filter_test'
  AND start_time >= DATEADD(minute, -5, CURRENT_TIMESTAMP())
ORDER BY start_time;

/*
ANALYSIS:
Rank these queries by partition pruning effectiveness:
1. _________________ (best pruning)
2. _________________
3. _________________
4. _________________ (worst pruning)

Pattern observed:
______________________________________________________________
*/


-- ============================================================
-- CHALLENGE 9: Real-World Scenario
-- ============================================================

/*
SCENARIO: You're a data engineer at an e-commerce company.

Current situation:
- sales table with 500 million rows
- 100+ analysts running ad-hoc queries
- Most common query: sales by date range and region
- Table grows by 1 million rows per day
- Analysts complain about slow dashboard loads

TASK: Design an optimal clustering strategy

Your recommendation:
Clustering keys: _______________________________________________
Rationale: _______________________________________________
Expected improvement: _______________________________________________
Risks/trade-offs: _______________________________________________
Monitoring plan: _______________________________________________
*/


-- ============================================================
-- CHALLENGE 10: Creative Experiments
-- ============================================================

/*
Design your own experiments! Some ideas:

1. Cluster by high-cardinality columns (customer_id)
   - What happens to clustering depth?
   - Does it help or hurt?

2. Test with very selective filters (one date)
   - vs broad filters (entire year)
   - Which benefits more from clustering?

3. Compare clustering to other optimization techniques
   - Materialized views
   - Search optimization service
   - Result caching

4. Measure end-to-end dashboard query performance
   - Run a series of related queries
   - Calculate total time with and without clustering

Document your experiments below:
*/

-- YOUR EXPERIMENTS HERE:




-- ============================================================
-- EXPLORATION COMPLETE!
-- ============================================================

SELECT
  '🎓 Advanced Exploration Complete!' AS status,
  'You now have deep understanding of Snowflake clustering!' AS achievement;

/*
KEY LEARNINGS FROM EXPLORATION:

1. Clustering key order matters for query performance
2. Match clustering keys to actual query patterns
3. Single-column clustering can be sufficient for simple patterns
4. Clustering has maintenance costs - use strategically
5. Not every table needs or benefits from clustering
6. Query Profile is essential for validating clustering effectiveness

CONGRATULATIONS! 🎊

You've mastered Snowflake clustering optimization!

Next steps:
- Apply these concepts to your own tables
- Monitor clustering health in production
- Experiment with different strategies
- Share your learnings with your team!
*/
