# Exercise 27: Time Travel & Zero-Copy Cloning

## Overview

Learn Snowflake's Time Travel feature for disaster recovery and Zero-Copy Cloning for instant test environments. You'll simulate an accidental data deletion, recover it in seconds using Time Travel, and create instant table copies with no storage overhead.

## Learning Objectives

By the end of this exercise, you will:

- Understand Snowflake's Time Travel feature and retention periods
- Use AT and BEFORE clauses to query historical data
- Recover accidentally deleted data in seconds
- Create zero-copy clones for testing and development
- Understand copy-on-write mechanics
- Appreciate why Snowflake's architecture is unique

## Prerequisites

- Completed main README setup steps (1-5)
- Snowflake account with EXERCISES_DB created
- COMPUTE_WH warehouse running
- Basic SQL knowledge (SELECT, INSERT, DELETE)

## The Business Problem

**Disaster scenario:** A junior analyst accidentally ran this command in production:

```sql
DELETE FROM customers WHERE state = 'CA';
```

**Result:** 1,000 California customers deleted! Dashboards are broken, the business team is panicking, and traditional databases would require:
- Finding the latest backup (hours old)
- Restoring to a staging environment
- Identifying and extracting just the deleted records
- Importing back to production
- **Total time: 2-4 hours minimum**

**With Snowflake Time Travel: 30 seconds!**

## What You'll Build

1. **Customer table** - 10,000 customer records across 10 US states
2. **Simulate deletion** - "Accidentally" delete all California customers
3. **Time Travel recovery** - Query historical data and recover deleted records
4. **Zero-copy clone** - Create instant test environment with no storage cost

## Exercise Structure

### File 1: `1_setup.sql` (3 minutes)
- Generates 10,000 customer records
- Creates `customers` table
- Establishes Time Travel history

**Action:** Copy to "Exercise 27 - Setup" worksheet and run.

### File 2: `2_challenge.sql` (15 minutes)
- Contains 5 challenging TODOs
- Simulates disaster and teaches recovery
- Requires understanding Time Travel syntax
- Includes reflection questions

**Action:** Copy to "Exercise 27 - Challenge" worksheet and complete TODOs.

### File 3: `3_solution.sql` (3 minutes)
- Complete reference implementation
- Uses BEFORE clause with query ID
- Detailed explanations

**Action:** Review after completing challenge.

### File 4: `4_advanced_exploration.sql` (Optional, 10 minutes)
- Experiment with different Time Travel scenarios
- Test retention periods
- Explore zero-copy clone behavior

**Action:** For deeper learning.

### File 5: `validation_quiz.md` (5 minutes)
- Test your Time Travel knowledge
- Conceptual questions

**Action:** Validate your understanding.

## Step-by-Step Instructions

### Step 1: Run Setup (3 minutes)

1. Open "Exercise 27 - Setup" worksheet
2. Copy entire `1_setup.sql` content
3. Verify context: SYSADMIN | COMPUTE_WH | EXERCISES_DB | PUBLIC
4. Click "Run All"
5. Wait 15-20 seconds (includes time for Time Travel history)
6. Verify 10,000 customers created

### Step 2: Complete Challenge (15 minutes)

1. Open "Exercise 27 - Challenge" worksheet
2. Copy `2_challenge.sql` content
3. Complete all 5 TODOs:
   - TODO 1: Check initial state
   - TODO 2: Execute "accidental" deletion
   - TODO 3: Use Time Travel to view historical data
   - TODO 4: Recover deleted records
   - TODO 5: Create and verify zero-copy clone

**Critical:** Make sure to capture timestamps BEFORE deletion!

### Step 3: Review Solution (3 minutes)

1. Open "Exercise 27 - Solution" worksheet
2. Copy `3_solution.sql`
3. Compare with your approach
4. Note the use of query IDs vs timestamps

### Step 4: Validate Learning (5 minutes)

1. Open `validation_quiz.md`
2. Complete all questions
3. Check your score

## What to Expect: Results

**Initial State:**
- Total customers: 10,000
- CA customers: ~963 (varies due to random distribution)

**After Deletion:**
- Total customers: ~9,037
- CA customers: 0
- Status: DISASTER! 😱

**After Time Travel Recovery:**
- Total customers: 10,000 (restored!)
- CA customers: ~963 (back!)
- Recovery time: **30 seconds**
- Status: CRISIS AVERTED! 🎉

**Zero-Copy Clone:**
- Clone creation time: **< 1 second**
- Additional storage cost: **$0.00** (initially)
- Full table copy: **10,000 rows available immediately**

## Key Concepts Explained

### Time Travel
- Feature that allows querying data as it existed at any point in the past
- Standard Edition: 1 day retention (24 hours)
- Enterprise Edition: Up to 90 days retention
- No additional storage until data changes
- Essential for disaster recovery and auditing

### Time Travel Syntax

**AT Clause** - Query at specific timestamp:
```sql
SELECT * FROM table AT(TIMESTAMP => '2024-11-01 10:30:00'::TIMESTAMP)
```

**BEFORE Clause** - Query before a specific statement:
```sql
SELECT * FROM table BEFORE(STATEMENT => 'query_id')
```

### Zero-Copy Cloning
- Creates instant copy of table/schema/database
- Shares underlying data files initially
- No storage cost until modifications are made
- Copy-on-write: Changed data creates new storage

### Copy-on-Write Mechanics
1. Clone created → Points to same data files as original
2. Query clone → Reads shared data files (no extra cost)
3. Modify clone → Only changed blocks are copied
4. Storage cost → Only for the changed data

## Common Pitfalls

❌ **Don't:**
- Forget to capture timestamp before deletion
- Confuse AT and BEFORE clauses
- Expect Time Travel to work on just-created tables (need history)
- Think clones are free forever (they cost when modified)
- Use Time Travel as a replacement for backups

✅ **Do:**
- Capture timestamps or query IDs BEFORE operations
- Understand your retention period (1 day vs 90 days)
- Use BEFORE clause with query IDs for precision
- Test Time Travel in dev before relying on it in prod
- Remember clones are snapshots, not live replicas

## Troubleshooting

**"No historical data available" error**
- Table was just created - need to wait for history
- Data modification must have occurred
- Retention period may have expired

**Time Travel query returns wrong number of rows**
- Check your timestamp accuracy
- Verify you're using correct timezone
- Try using query ID instead of timestamp

**Clone shows different data than original**
- This is normal if either table was modified after cloning
- Clones are point-in-time snapshots, not live replicas

**Can't find query ID**
- After running a query, check bottom of results panel
- Look for blue underlined text
- Or query INFORMATION_SCHEMA.QUERY_HISTORY()

## Time and Cost

**Estimated Time:**
- Setup: 3 minutes
- Challenge: 15 minutes
- Solution review: 3 minutes
- Validation: 5 minutes
- **Total: 26 minutes**

**Estimated Cost:**
- X-Small warehouse: ~$0.08 for 25 minutes
- Your free trial includes $400 credits

## What's Next?

After completing this exercise:

1. ✅ Complete Exercise 26 (Clustering) if you haven't already
2. ✅ Try advanced Time Travel scenarios
3. ✅ Experiment with schema and database clones
4. ✅ Read about Fail-safe (additional 7 days protection)
5. ✅ Learn about undrop commands

## Need Help?

- Review main README troubleshooting section
- Check Snowflake documentation: https://docs.snowflake.com/en/user-guide/data-time-travel
- Time Travel reference: https://docs.snowflake.com/en/sql-reference/constructs/at-before
- Zero-copy cloning: https://docs.snowflake.com/en/user-guide/tables-storage-considerations

---

**Ready to travel through time? Open `1_setup.sql` and let's begin! ⏰**
