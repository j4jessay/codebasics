# Exercise 26: Clustering Keys & Query Performance

## Overview

Learn how Snowflake's clustering keys dramatically improve query performance through partition pruning. You'll create tables with and without clustering, compare their performance, and visualize the difference using Query Profile.

## Learning Objectives

By the end of this exercise, you will:

- Understand Snowflake's micro-partitioning architecture
- Create tables with clustering keys
- Measure clustering quality using `SYSTEM$CLUSTERING_DEPTH`
- Compare query performance between clustered and non-clustered tables
- Use Query Profile to visualize partition pruning
- Analyze query history and performance metrics

## Prerequisites

- Completed main README setup steps (1-5)
- Snowflake account with EXERCISES_DB created
- COMPUTE_WH warehouse running
- Basic SQL knowledge (SELECT, WHERE, CREATE TABLE)

## The Business Problem

Your company has a sales table with 50,000 records. Analysts frequently run queries filtering by:
- **Region** (e.g., "Show me all US_EAST sales")
- **Date Range** (e.g., "Show me October 2024 sales")

Without clustering, Snowflake must scan **most or all** micro-partitions to find relevant data, even if only a small percentage matches the filter criteria. This results in:
- Slow query performance
- Higher compute costs
- Poor user experience

**Your mission:** Use clustering keys to optimize this table and achieve 3-5x performance improvement!

## What You'll Build

1. **Non-clustered table** - `sales_non_clustered` (50,000 records, no optimization)
2. **Clustered table** - `sales_clustered` (same data, optimized with clustering keys)
3. **Performance comparison** - Side-by-side analysis showing the dramatic improvement

## Exercise Structure

### File 1: `1_setup.sql` (5 minutes)
- Generates 50,000 sales records using Snowflake's GENERATOR function
- Creates `sales_non_clustered` table
- Verifies data distribution

**Action:** Copy this file into your "Exercise 26 - Setup" worksheet and run it.

### File 2: `2_challenge.sql` (20 minutes)
- Contains 5 challenging TODOs for you to complete
- Requires writing SQL from scratch (no copy-paste!)
- Includes spaces to record your observations
- Tests your understanding of clustering concepts

**Action:** Copy this into your "Exercise 26 - Challenge" worksheet and complete all TODOs.

### File 3: `3_solution.sql` (5 minutes)
- Complete reference implementation
- Detailed explanations of each step
- Performance comparison queries
- Use this to check your work

**Action:** After completing the challenge, review this solution to compare approaches.

### File 4: `4_advanced_exploration.sql` (Optional, 15 minutes)
- Experiment with different clustering key orders
- Test with different filter conditions
- Explore automatic reclustering
- Monitor clustering maintenance

**Action:** For those who want to go deeper.

### File 5: `validation_quiz.md` (10 minutes)
- Conceptual questions to test understanding
- No coding required
- Self-assessment

**Action:** Complete after finishing the solution to validate your learning.

## Step-by-Step Instructions

### Step 1: Run Setup (5 minutes)

1. Open your "Exercise 26 - Setup" worksheet in Snowflake
2. Copy the entire contents of `1_setup.sql` from this folder
3. Paste into the worksheet
4. Verify context (top right):
   - Role: SYSADMIN
   - Warehouse: COMPUTE_WH
   - Database: EXERCISES_DB
   - Schema: PUBLIC
5. Click "Run All" or press Ctrl+Enter
6. Wait 10-30 seconds for data generation
7. Verify you see "50,000" in the count result

**Expected output:**
```
✓ Database and schema set
✓ Generated 50,000 sales records
✓ Data distribution verified
```

### Step 2: Complete Challenge (20 minutes)

1. Open your "Exercise 26 - Challenge" worksheet
2. Copy the entire contents of `2_challenge.sql`
3. Read each TODO carefully
4. Write your SQL solutions (don't skip to the solution!)
5. Run each query as you complete it
6. **Important:** For TODO 1 and TODO 4, click the blue Query ID link to open Query Profile
7. Record your observations in the spaces provided

**Key Challenge Points:**

**TODO 1:** Query non-clustered table
- Write a query filtering US_EAST region + October 2024
- Note execution time
- **Open Query Profile** - this is critical!
- Record partitions scanned

**TODO 2:** Create clustered table
- Think about which columns to use as clustering keys
- Consider the order of columns
- Write the CREATE TABLE with CLUSTER BY clause

**TODO 3:** Check clustering quality
- Use SYSTEM$CLUSTERING_DEPTH function
- Interpret the result (< 2 is excellent)

**TODO 4:** Query clustered table
- Run the same query as TODO 1
- Compare performance
- **Open Query Profile** again - see the difference!

**TODO 5:** Analyze query history
- Write a query using INFORMATION_SCHEMA.QUERY_HISTORY()
- Compare both queries side-by-side
- Calculate improvement ratio

### Step 3: Review Solution (5 minutes)

1. Open your "Exercise 26 - Solution" worksheet
2. Copy the contents of `3_solution.sql`
3. Compare with your approach
4. Note any differences
5. Run the solution to see expected results

**Questions to ask yourself:**
- Did my clustering keys match the solution?
- Was my performance improvement similar?
- Did I interpret Query Profile correctly?
- What would I do differently?

### Step 4: Validate Learning (10 minutes)

1. Open `validation_quiz.md` file
2. Answer all questions without looking at the solution
3. Check your answers
4. Review any concepts you're unsure about

### Step 5: Advanced Exploration (Optional, 15 minutes)

1. Open `4_advanced_exploration.sql`
2. Try the bonus challenges
3. Experiment with different scenarios
4. Test edge cases

## What to Expect: Performance Results

With the test dataset (50,000 records):

**Non-clustered query:**
- Execution time: 800-1200ms
- Partitions scanned: 400-500 (nearly all)
- Partition scan percentage: 95-100%

**Clustered query:**
- Execution time: 200-400ms
- Partitions scanned: 10-30 (just the relevant ones)
- Partition scan percentage: 2-5%

**Improvement:**
- **3-5x faster** query execution
- **95%+ reduction** in partitions scanned
- **Lower compute costs** due to less data scanning

## Key Concepts Explained

### Micro-Partitioning
- Snowflake automatically divides tables into small chunks (50-500 MB each)
- Each micro-partition stores a subset of rows
- Partitions are immutable and compressed

### Clustering Keys
- Columns you specify to organize micro-partitions
- Data with similar values is grouped together
- Enables partition pruning during queries

### Partition Pruning
- Snowflake skips partitions that don't contain relevant data
- Happens automatically when clustering keys match WHERE clause filters
- Visible in Query Profile as "pruned" partitions

### Clustering Depth
- Measure of how well-clustered your table is
- Lower is better (< 2 is excellent, 2-5 is acceptable, > 5 is poor)
- Check with: `SYSTEM$CLUSTERING_DEPTH('table', '(col1, col2)')`

### Query Profile
- Visual representation of query execution
- Shows partition scanning, execution time, data processed
- **Most important tool for understanding performance**
- Access by clicking any blue Query ID link

## Common Pitfalls

❌ **Don't:**
- Skip Query Profile analysis - this is where the learning happens!
- Copy-paste solutions without understanding
- Use too many clustering keys (3-4 is maximum, 2 is typical)
- Cluster on columns you never filter by
- Forget to check clustering depth

✅ **Do:**
- Read Query Profile for both clustered and non-clustered queries
- Choose clustering keys that match your most common filters
- Put the most selective column first in clustering key
- Test with realistic queries
- Monitor clustering maintenance costs in production

## Troubleshooting

**"Table already exists" error**
- The setup script uses `CREATE OR REPLACE` so this shouldn't happen
- If it does, run: `DROP TABLE IF EXISTS sales_non_clustered;` first

**"Insufficient privileges" error**
- Make sure you're using SYSADMIN role (top right dropdown)
- Or run the setup code from main README Step 3 again

**Query Profile shows no difference**
- Make sure you're using the correct filter conditions
- Verify clustering keys match your WHERE clause columns
- Check that clustering depth < 2

**Data generation is slow**
- Normal for first run (warehouse may be starting)
- Should take 10-30 seconds
- If > 1 minute, check warehouse is running

**Can't find Query ID link**
- Look at the bottom of the results panel
- It's a blue underlined text (looks like: "01aabc23-0001-...")
- Click it to open Query Profile in a new tab

## Time and Cost

**Estimated Time:**
- Setup: 5 minutes
- Challenge: 20 minutes
- Solution review: 5 minutes
- Validation: 10 minutes
- **Total: 40 minutes**

**Estimated Cost:**
- X-Small warehouse: ~$0.10 for 30-40 minutes
- Your free trial includes $400 credits

## What's Next?

After completing this exercise:

1. ✅ Complete Exercise 27 (Time Travel) if you haven't already
2. ✅ Try the advanced exploration challenges
3. ✅ Experiment with your own datasets
4. ✅ Read Snowflake documentation on clustering
5. ✅ Share your results and learnings!

## Need Help?

- Review the main README troubleshooting section
- Check Snowflake documentation: https://docs.snowflake.com/en/user-guide/tables-clustering-keys
- Ask questions in Snowflake Community
- Review the solution file for guidance

---

**Ready to optimize some queries? Open `1_setup.sql` and let's get started! 🚀**
