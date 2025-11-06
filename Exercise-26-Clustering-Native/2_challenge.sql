-- ============================================================
-- EXERCISE 26: CLUSTERING KEYS & QUERY PERFORMANCE
-- FILE: 2_challenge.sql
-- ============================================================
--
-- INSTRUCTIONS:
-- 1. Make sure you ran 1_setup.sql first!
-- 2. Copy this entire file into your "Exercise 26 - Challenge" worksheet
-- 3. Complete each TODO by writing SQL from scratch
-- 4. Record your observations in the spaces provided
-- 5. Don't skip to the solution - the learning is in the struggle!
--
-- ============================================================

USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE EXERCISES_DB;
USE SCHEMA PUBLIC;

-- ============================================================
-- TODO 1: ANALYZE NON-CLUSTERED TABLE PERFORMANCE
-- ============================================================
/*
CHALLENGE:
Write a query to find all sales for US_EAST region in October 2024.
This will be your baseline for comparing clustering performance.

REQUIREMENTS:
1. Set a query tag to 'exercise_non_clustered' for tracking
2. SELECT all columns (*) from sales_non_clustered
3. Filter WHERE region = 'US_EAST'
4. Filter WHERE order_date is in October 2024 (>= '2024-10-01' AND < '2024-11-01')

LEARNING OBJECTIVES:
- Understand how non-clustered tables scan most/all partitions
- Learn to use query tags for tracking
- Practice with Query Profile

HINTS:
- Use: ALTER SESSION SET QUERY_TAG = 'your_tag';
- Date filtering: WHERE date >= '2024-10-01' AND date < '2024-11-01'

AFTER RUNNING:
1. Note the execution time shown at bottom right
2. Click the blue Query ID link to open Query Profile
3. Look for "Partitions scanned" vs "Partitions total"
4. Record these numbers below!
*/

-- YOUR CODE HERE (Step 1: Set query tag):



-- YOUR CODE HERE (Step 2: Write the query):




/*
RECORD YOUR OBSERVATIONS:

Execution Time: ________________ ms

Query Profile Analysis:
- Partitions Scanned: ________________
- Partitions Total: ________________
- Scan Percentage: ________________ %

Row Count Returned: ________________

What did you notice in Query Profile?
______________________________________________________________
______________________________________________________________
*/


-- ============================================================
-- TODO 2: CREATE CLUSTERED TABLE - DESIGN DECISION
-- ============================================================
/*
CHALLENGE:
Create a properly clustered table based on our query patterns.

BUSINESS CONTEXT:
Analysts primarily query by:
1. Date ranges (e.g., "last month", "Q3 2024", "October 2024")
2. Specific regions (e.g., "US_EAST", "ASIA")

CRITICAL THINKING QUESTIONS (Answer BEFORE coding):

Question 1: Which columns should be clustering keys?
Possible options: order_id, customer_id, order_date, order_amount, region, product_name

Your answer: ______________________________________________

Why? ______________________________________________


Question 2: Does the ORDER of clustering keys matter?
Should it be (order_date, region) or (region, order_date)?

Your answer: ______________________________________________

Why? ______________________________________________


Question 3: Should we include more columns like product_name or customer_id?

Your answer: ______________________________________________

Why? ______________________________________________


REQUIREMENTS:
1. CREATE OR REPLACE TABLE named 'sales_clustered'
2. Use CLUSTER BY clause with your chosen columns
3. Copy ALL data from sales_non_clustered
4. Use proper syntax: CREATE TABLE ... CLUSTER BY (...) AS SELECT ...

HINT:
Think about which filter is applied FIRST and is most selective.
The first clustering key should be the most commonly filtered column.
*/

-- YOUR CODE HERE:




/*
RECORD YOUR DECISION:

My clustering keys: CLUSTER BY ( _____________, _____________ )

Rationale for column choice:
______________________________________________________________
______________________________________________________________

Rationale for column order:
______________________________________________________________
______________________________________________________________
*/


-- ============================================================
-- TODO 3: MEASURE CLUSTERING QUALITY
-- ============================================================
/*
CHALLENGE:
Use Snowflake's system function to check how well your table is clustered.

LEARNING OBJECTIVE:
Understand clustering depth and what it means for query performance.

REQUIREMENTS:
1. Use SYSTEM$CLUSTERING_DEPTH function
2. Pass your table name (as string: 'sales_clustered')
3. Pass your clustering keys (as string: '(col1, col2)')
4. Execute the query
5. Interpret the result

SYNTAX HINT:
SELECT SYSTEM$CLUSTERING_DEPTH('table_name', '(column1, column2)') AS clustering_depth;

INTERPRETATION GUIDE:
- Depth < 2: Excellent clustering (your data is well-organized)
- Depth 2-5: Acceptable clustering (room for improvement)
- Depth > 5: Poor clustering (consider different keys or reclustering)

WHY IT MATTERS:
Lower clustering depth = more efficient partition pruning = faster queries
*/

-- YOUR CODE HERE:




/*
RECORD YOUR RESULT:

Clustering Depth: ________________

Quality Assessment:
☐ Excellent (< 2)
☐ Acceptable (2-5)
☐ Poor (> 5)

If depth > 2, what would you change?
______________________________________________________________
______________________________________________________________

Why is clustering depth important for query performance?
______________________________________________________________
______________________________________________________________
*/


-- ============================================================
-- TODO 4: QUERY CLUSTERED TABLE & COMPARE PERFORMANCE
-- ============================================================
/*
CHALLENGE:
Run the EXACT SAME query as TODO 1, but on the clustered table.

REQUIREMENTS:
1. Set query tag to 'exercise_clustered'
2. Use SAME filters as TODO 1 (region='US_EAST', October 2024)
3. Query sales_clustered table (not sales_non_clustered!)
4. Open Query Profile and compare with TODO 1

CRITICAL: Make sure the query is IDENTICAL except for the table name!
This ensures a fair comparison.
*/

-- YOUR CODE HERE (Step 1: Set query tag):



-- YOUR CODE HERE (Step 2: Write the query - same as TODO 1 but different table):




/*
RECORD YOUR OBSERVATIONS:

Execution Time: ________________ ms

Query Profile Analysis:
- Partitions Scanned: ________________
- Partitions Total: ________________
- Scan Percentage: ________________ %

Row Count Returned: ________________ (should match TODO 1)

PERFORMANCE COMPARISON:

Non-Clustered (TODO 1) vs Clustered (TODO 4):

Execution Time:
- Non-clustered: ________ ms
- Clustered: ________ ms
- Speedup: ________ x faster

Partitions Scanned:
- Non-clustered: ________ partitions
- Clustered: ________ partitions
- Reduction: ________ fewer partitions

What patterns do you see in Query Profile?
______________________________________________________________
______________________________________________________________

Why is clustering faster?
______________________________________________________________
______________________________________________________________
*/


-- ============================================================
-- TODO 5: QUERY HISTORY ANALYSIS
-- ============================================================
/*
CHALLENGE:
Write a SQL query to analyze and compare both queries using Snowflake's
query history metadata.

LEARNING OBJECTIVE:
Learn to use INFORMATION_SCHEMA.QUERY_HISTORY() for performance analysis.

REQUIREMENTS:
1. Query the INFORMATION_SCHEMA.QUERY_HISTORY() table function
2. Filter for queries with your query tags from TODO 1 and TODO 4
3. Filter for queries run in the last 1 hour
4. Display these columns:
   - query_tag
   - execution_time (convert from milliseconds to seconds)
   - partitions_scanned
   - partitions_total
   - Calculate: scan_percentage = (partitions_scanned / partitions_total * 100)
5. Order by query_tag

BONUS CHALLENGE:
Calculate the improvement ratio (non_clustered_time / clustered_time)

SYNTAX HINTS:
- Table function: TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
- Time conversion: execution_time / 1000 AS execution_seconds
- Date filtering: WHERE start_time >= DATEADD(hour, -1, CURRENT_TIMESTAMP())
- Query tag filter: WHERE query_tag IN ('tag1', 'tag2')
*/

-- YOUR CODE HERE:




/*
BONUS: Calculate improvement ratio using a subquery or CTE
*/

-- YOUR BONUS CODE HERE (Optional):




/*
ANALYSIS QUESTIONS:

1. What percentage of partitions were scanned in non-clustered table?
Answer: ________________ %

2. What percentage in clustered table?
Answer: ________________ %

3. By what factor did clustering reduce partition scanning?
Answer: ________________ x reduction

4. Why didn't clustering scan 0% of partitions? (Why not even better?)
Answer: ______________________________________________________________
______________________________________________________________

5. What would happen if we queried by product_name instead of region?
Answer: ______________________________________________________________
______________________________________________________________

6. When would clustering NOT help query performance?
Answer: ______________________________________________________________
______________________________________________________________
*/


-- ============================================================
-- CHALLENGE COMPLETE!
-- ============================================================

SELECT
  '🎉 Challenge Complete!' AS status,
  'Compare your solution with 3_solution.sql' AS next_step,
  'Review validation_quiz.md to test your understanding' AS final_step;

/*
REFLECTION QUESTIONS:

1. What was the most surprising thing you learned?
______________________________________________________________
______________________________________________________________

2. How would you explain clustering to a non-technical person?
______________________________________________________________
______________________________________________________________

3. What questions do you still have?
______________________________________________________________
______________________________________________________________

NEXT STEPS:
☐ Review your answers above
☐ Open 3_solution.sql and compare your approach
☐ Open Query Profile again and study the differences
☐ Complete validation_quiz.md
☐ Try 4_advanced_exploration.sql for bonus challenges

Congratulations on completing the clustering challenge!
*/
