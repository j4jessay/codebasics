# Exercise 26: Clustering Keys - Validation Quiz

## Instructions

Complete this quiz after finishing the challenge and reviewing the solution. Answer all questions without looking at the code. This tests your conceptual understanding, not just your ability to write SQL.

---

## Section 1: Core Concepts (10 questions)

### Q1: What is micro-partitioning in Snowflake?
- [ ] A. Manual partitioning strategy defined by users
- [ ] B. Automatic division of tables into small compressed chunks
- [ ] C. A type of index structure
- [ ] D. A storage optimization for small tables only

### Q2: What is partition pruning?
- [ ] A. Deleting old partitions to save space
- [ ] B. Compressing partitions for better storage
- [ ] C. Skipping partitions that don't contain relevant data during query execution
- [ ] D. Reorganizing partitions for better performance

### Q3: What is an excellent clustering depth value?
- [ ] A. Less than 2
- [ ] B. Between 5 and 10
- [ ] C. Greater than 10
- [ ] D. Exactly 0

### Q4: How many clustering keys does Snowflake recommend for most use cases?
- [ ] A. 1
- [ ] B. 2-3
- [ ] C. 5-7
- [ ] D. As many as possible

### Q5: Which SQL clause is used to define clustering keys?
- [ ] A. ORDER BY
- [ ] B. PARTITION BY
- [ ] C. CLUSTER BY
- [ ] D. INDEX ON

### Q6: Does the order of clustering keys matter?
- [ ] A. Yes, the first key is most important
- [ ] B. No, Snowflake automatically optimizes the order
- [ ] C. Only for tables larger than 1TB
- [ ] D. Only when using automatic reclustering

### Q7: What happens to clustering over time as new data is inserted?
- [ ] A. Clustering stays perfect forever
- [ ] B. Clustering quality may degrade and require maintenance
- [ ] C. Clustering automatically improves
- [ ] D. Clustering becomes invalid and must be redefined

### Q8: Where can you see visual evidence of partition pruning?
- [ ] A. In the SQL query results
- [ ] B. In the Query Profile
- [ ] C. In the table DDL
- [ ] D. In the Snowflake account dashboard

### Q9: Which function checks clustering quality?
- [ ] A. CHECK_CLUSTERING()
- [ ] B. SYSTEM$CLUSTERING_DEPTH()
- [ ] C. GET_CLUSTERING_INFO()
- [ ] D. ANALYZE_CLUSTERING()

### Q10: What type of columns make good clustering keys?
- [ ] A. Columns you frequently filter by in WHERE clauses
- [ ] B. Columns with unique values (high cardinality)
- [ ] C. Columns that change frequently
- [ ] D. All columns in the table

---

## Section 2: Practical Application (10 questions)

### Q11: Given a table with these common queries:
```sql
-- Query A (80% of queries)
SELECT * FROM sales WHERE sale_date BETWEEN X AND Y;

-- Query B (15% of queries)
SELECT * FROM sales WHERE region = 'US' AND sale_date BETWEEN X AND Y;

-- Query C (5% of queries)
SELECT * FROM sales WHERE customer_id = 123;
```

What should your clustering keys be?
- [ ] A. (customer_id)
- [ ] B. (sale_date, region)
- [ ] C. (region, sale_date)
- [ ] D. (sale_date, region, customer_id)

### Q12: Your table has clustering depth of 8.5. What does this mean?
- [ ] A. Excellent clustering
- [ ] B. Acceptable clustering
- [ ] C. Poor clustering - consider reclustering or different keys
- [ ] D. Invalid clustering configuration

### Q13: You created a clustered table but see no performance improvement. What's the most likely reason?
- [ ] A. Table is too small (< 100MB)
- [ ] B. Snowflake doesn't support your data type
- [ ] C. Clustering keys don't match your WHERE clause filters
- [ ] D. You need to enable clustering with ALTER TABLE

### Q14: Which table should you cluster?
- [ ] A. 50MB lookup table, rarely queried
- [ ] B. 500GB fact table, thousands of queries per day
- [ ] C. 10MB dimension table, updated every minute
- [ ] D. Temporary staging table, truncated daily

### Q15: You're querying by product_id but clustered by date and region. What happens?
- [ ] A. Query fails with an error
- [ ] B. Query works but clustering doesn't help performance
- [ ] C. Snowflake automatically reclusters for your query
- [ ] D. Performance is still improved due to compression

### Q16: After inserting 1 million rows into a clustered table, what should you do?
- [ ] A. Immediately run RECLUSTER command
- [ ] B. Drop and recreate the table
- [ ] C. Nothing - Snowflake handles automatic reclustering
- [ ] D. Redefine the clustering keys

### Q17: Your non-clustered query scans 500/500 partitions. After clustering, it scans 10/500. What's the improvement?
- [ ] A. 2x reduction
- [ ] B. 10x reduction
- [ ] C. 50x reduction
- [ ] D. 98% reduction in partitions scanned

### Q18: Which query benefits MOST from clustering by (order_date, region)?
- [ ] A. `WHERE customer_id = 123`
- [ ] B. `WHERE order_date = '2024-01-15'`
- [ ] C. `WHERE product_name LIKE '%Laptop%'`
- [ ] D. `WHERE order_amount > 1000`

### Q19: You have two clustering key options: (date, region) or (region, date). Queries mostly filter by date. Which is better?
- [ ] A. (date, region) - most selective column first
- [ ] B. (region, date) - least selective column first
- [ ] C. Doesn't matter - same performance
- [ ] D. Use (date) only - single key is always better

### Q20: What's the trade-off of clustering?
- [ ] A. Increased storage cost
- [ ] B. Slower INSERT operations
- [ ] C. Compute cost for maintaining clustering
- [ ] D. Requires manual maintenance every day

---

## Section 3: Query Profile Interpretation (5 questions)

### Q21: Query Profile shows "Partitions scanned: 450/500". What does this mean?
- [ ] A. 450 partitions were created and 500 were scanned
- [ ] B. 450 partitions contained relevant data out of 500 total
- [ ] C. 50 partitions were pruned
- [ ] D. Both B and C are correct

### Q22: Where do you find the Query ID to open Query Profile?
- [ ] A. In the SQL query text
- [ ] B. At the top of the worksheet
- [ ] C. As a blue underlined link at the bottom of the results
- [ ] D. In the Snowflake account settings

### Q23: Query Profile shows execution time of 1200ms for non-clustered and 300ms for clustered. What's the speedup?
- [ ] A. 2x faster
- [ ] B. 3x faster
- [ ] C. 4x faster
- [ ] D. 900ms faster (speedup is measured in time, not ratio)

### Q24: In Query Profile, pruned partitions are shown as:
- [ ] A. Red bars
- [ ] B. Green bars
- [ ] C. Gray/not visible (they're skipped)
- [ ] D. Blue bars

### Q25: What's the most important metric in Query Profile for understanding clustering effectiveness?
- [ ] A. Total execution time
- [ ] B. Partitions scanned vs partitions total
- [ ] C. Bytes scanned
- [ ] D. Number of rows returned

---

## Section 4: Advanced Concepts (10 questions)

### Q26: Can you change clustering keys on an existing table?
- [ ] A. No - must drop and recreate the table
- [ ] B. Yes - use ALTER TABLE ... CLUSTER BY
- [ ] C. Yes - but only by adding keys, not changing them
- [ ] D. Yes - but it requires downtime

### Q27: What happens if you cluster by a high-cardinality column like customer_id (millions of unique values)?
- [ ] A. Excellent performance for all queries
- [ ] B. Poor clustering depth and limited pruning benefit
- [ ] C. Snowflake rejects the clustering key
- [ ] D. Works perfectly for small tables only

### Q28: Automatic reclustering is:
- [ ] A. Always free - no compute cost
- [ ] B. Disabled by default - must enable manually
- [ ] C. Enabled by default but consumes compute credits
- [ ] D. Only available in Enterprise Edition

### Q29: Which INFORMATION_SCHEMA view shows query history and performance metrics?
- [ ] A. TABLES
- [ ] B. COLUMNS
- [ ] C. QUERY_HISTORY()
- [ ] D. WAREHOUSE_LOAD_HISTORY()

### Q30: You query by date and region, but your table also has country, state, and city columns. Should you cluster by all five?
- [ ] A. Yes - more clustering is always better
- [ ] B. No - stick to 2-3 most commonly filtered columns
- [ ] C. Yes - but only if table is larger than 1TB
- [ ] D. No - only cluster by the single most selective column

### Q31: What's the relationship between clustering and compression?
- [ ] A. Clustering replaces compression
- [ ] B. Clustering and compression are independent features
- [ ] C. Better clustering often leads to better compression
- [ ] D. Clustering disables compression

### Q32: When does clustering NOT help query performance?
- [ ] A. When you filter by clustering key columns
- [ ] B. When you filter by non-clustering key columns
- [ ] C. When table is large (> 1GB)
- [ ] D. When queries have date range filters

### Q33: What does SYSTEM$CLUSTERING_INFORMATION return that SYSTEM$CLUSTERING_DEPTH doesn't?
- [ ] A. Nothing - they're the same function
- [ ] B. Detailed JSON with partition depth histogram
- [ ] C. List of all partitions in the table
- [ ] D. Automatic reclustering schedule

### Q34: You clustered by (date, region) but most queries filter by (region, date). Performance is:
- [ ] A. Terrible - query will fail
- [ ] B. Poor - no partition pruning at all
- [ ] C. Good - Snowflake still benefits from both columns
- [ ] D. Identical - column order doesn't matter in WHERE clause

### Q35: What's the best way to monitor clustering health in production?
- [ ] A. Run SYSTEM$CLUSTERING_DEPTH daily
- [ ] B. Check Query Profile for every query
- [ ] C. Use AUTOMATIC_CLUSTERING_HISTORY view
- [ ] D. All of the above

---

## Section 5: Real-World Scenarios (5 questions)

### Q36: Your dashboard loads slowly. Table has 10 billion rows. Most queries filter by date. What's your first optimization step?
- [ ] A. Add more warehouses
- [ ] B. Create a materialized view
- [ ] C. Add clustering by date column
- [ ] D. Partition the table manually

### Q37: After adding clustering, queries are faster but your Snowflake bill increased. Why?
- [ ] A. Clustering failed - need to troubleshoot
- [ ] B. Automatic reclustering is consuming compute credits
- [ ] C. Clustering increases storage costs
- [ ] D. This is impossible - clustering always reduces costs

### Q38: Analysts complain: "Some queries are fast, others are slow on the same table." Table is clustered by (date, region). What's happening?
- [ ] A. Warehouse is undersized
- [ ] B. Some queries match clustering keys, others don't
- [ ] C. Table needs reclustering
- [ ] D. Snowflake is having performance issues

### Q39: You have three tables: 50GB fact table, 500MB dimension table, 10MB lookup table. Which should you cluster?
- [ ] A. All three for consistency
- [ ] B. Only the 50GB fact table
- [ ] C. Only the lookup table (most frequently joined)
- [ ] D. Dimension and fact tables, but not lookup

### Q40: Your clustering depth increased from 1.5 to 6.0 over one month. What should you do?
- [ ] A. Nothing - this is normal
- [ ] B. Investigate automatic reclustering settings
- [ ] C. Change clustering keys
- [ ] D. Drop and recreate the table

---

## Answer Key

### Section 1: Core Concepts
1. B | 2. C | 3. A | 4. B | 5. C | 6. A | 7. B | 8. B | 9. B | 10. A

### Section 2: Practical Application
11. B | 12. C | 13. C | 14. B | 15. B | 16. C | 17. D | 18. B | 19. A | 20. C

### Section 3: Query Profile
21. D | 22. C | 23. C | 24. C | 25. B

### Section 4: Advanced Concepts
26. B | 27. B | 28. C | 29. C | 30. B | 31. C | 32. B | 33. B | 34. C | 35. D

### Section 5: Real-World Scenarios
36. C | 37. B | 38. B | 39. B | 40. B

---

## Scoring

**36-40 correct:** 🏆 Clustering Expert! You have mastered Snowflake clustering optimization.

**30-35 correct:** 🌟 Strong Understanding! You're ready to apply clustering in production.

**24-29 correct:** 📚 Good Foundation! Review the solution and documentation for areas you missed.

**18-23 correct:** 🔄 Needs Review! Go through the challenge and solution again carefully.

**Below 18:** 📖 Start Over! Re-do the exercise and focus on understanding, not just completing.

---

## Key Takeaways

If you completed this quiz, you should understand:

✅ Micro-partitioning and how Snowflake organizes data
✅ How clustering keys enable partition pruning
✅ How to choose appropriate clustering keys for your queries
✅ How to measure and interpret clustering quality
✅ When clustering helps (and when it doesn't)
✅ The cost/benefit trade-offs of clustering
✅ How to use Query Profile to validate clustering effectiveness
✅ Best practices for clustering in production

**Congratulations on completing Exercise 26! 🎉**
