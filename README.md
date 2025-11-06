# Snowflake Data Engineering Exercises - Native Platform Edition

> Learn Snowflake by working directly in the Snowflake platform - no Docker, no Python, just pure SQL and Snowflake features.

## What You'll Learn

- Snowflake UI (Snowsight) navigation and features
- Query Profile for performance analysis
- Micro-partitioning and clustering visualization
- Time Travel disaster recovery
- Zero-copy cloning
- Snowflake-specific SQL functions (GENERATOR, UNIFORM, SYSTEM$)
- Warehouse management and cost monitoring
- Query history and metadata analysis

## Getting Started

### Step 1: Create Your Snowflake Account (10 minutes)

**1.1 Sign Up for Free Trial**
- Go to: https://signup.snowflake.com/
- Click "START FOR FREE"
- Fill in your details:
  - Email (use your real email - you'll need to verify)
  - First Name, Last Name
  - Company (can be "Personal Learning" if individual)
  - Country

**1.2 Choose Your Cloud Provider**
- Select any option (doesn't matter for these exercises):
  - AWS (Amazon Web Services)
  - Azure (Microsoft)
  - GCP (Google Cloud)
- Select a region close to you (for faster performance)
- Click "GET STARTED"

**1.3 Verify Your Email**
- Check your email inbox
- Click the verification link
- This activates your account

**1.4 Create Your Credentials**
- Choose a username (e.g., your first name + last name)
- Create a strong password
- Save these credentials securely - you'll need them!

**1.5 Complete Setup**
- Snowflake will create your account (takes 1-2 minutes)
- You'll see "Your account is ready" message
- Click "Continue" or "Go to Snowsight"

**1.6 First Login**
- You'll land on the Snowflake home page (Snowsight)
- Look around - don't worry if it looks overwhelming!

---

### Step 2: Initial Snowflake Setup (5 minutes)

**2.1 Understand Your Default Setup**

Snowflake automatically creates:
- **Warehouse:** `COMPUTE_WH` (your compute engine)
- **Database:** `SNOWFLAKE_SAMPLE_DATA` (demo data - we won't use this)
- **Role:** Your user has `ACCOUNTADMIN` role

**2.2 Create Your Warehouse (if needed)**

- Click "Admin" → "Warehouses" in left sidebar
- If you see `COMPUTE_WH` listed, you're good! Skip to 2.3
- If not, click "+ Warehouse" button:
  - Name: `COMPUTE_WH`
  - Size: X-Small
  - Auto Suspend: 1 minute
  - Auto Resume: Enabled (checked)
  - Click "Create Warehouse"

**2.3 Navigate to Worksheets**

- Click "Projects" → "Worksheets" in left sidebar
- You'll see a blank worksheet or welcome screen
- This is where you'll do all your work!

---

### Step 3: Create Your Exercise Database (2 minutes)

**3.1 Open a New Worksheet**
- Click "+ Worksheet" button (top right)
- You'll see a blank SQL editor

**3.2 Set Up Database and Schema**

Copy and paste this code, then click "Run All":

```sql
-- Use admin role for setup
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- Create your exercise database
CREATE DATABASE IF NOT EXISTS EXERCISES_DB
  COMMENT = 'Database for Snowflake learning exercises';

-- Grant permissions to SYSADMIN role
GRANT OWNERSHIP ON DATABASE EXERCISES_DB TO ROLE SYSADMIN;
GRANT OWNERSHIP ON SCHEMA EXERCISES_DB.PUBLIC TO ROLE SYSADMIN;

-- Switch to SYSADMIN for daily work
USE ROLE SYSADMIN;
USE DATABASE EXERCISES_DB;
USE SCHEMA PUBLIC;

-- Verify setup
SELECT CURRENT_DATABASE() AS database_name,
       CURRENT_SCHEMA() AS schema_name,
       CURRENT_ROLE() AS role_name,
       CURRENT_WAREHOUSE() AS warehouse_name;
```

**3.3 Verify Success**

You should see output showing:
```
DATABASE_NAME: EXERCISES_DB
SCHEMA_NAME: PUBLIC
ROLE_NAME: SYSADMIN
WAREHOUSE_NAME: COMPUTE_WH
```

---

### Step 4: Create Your Exercise Worksheets (3 minutes)

You'll create separate worksheets for each exercise.

**For Exercise 26 (Clustering):**

1. Click "+ Worksheet" button
2. Double-click "Worksheet" title at top
3. Rename to: `Exercise 26 - Setup`
4. Repeat to create:
   - `Exercise 26 - Challenge`
   - `Exercise 26 - Solution`

**For Exercise 27 (Time Travel):**

1. Create three more worksheets:
   - `Exercise 27 - Setup`
   - `Exercise 27 - Challenge`
   - `Exercise 27 - Solution`

**Your worksheet list should now show:**
```
📄 Exercise 26 - Setup
📄 Exercise 26 - Challenge
📄 Exercise 26 - Solution
📄 Exercise 27 - Setup
📄 Exercise 27 - Challenge
📄 Exercise 27 - Solution
```

---

### Step 5: Important Settings To Know

**Context (Top Right of Each Worksheet):**

Every worksheet has these dropdowns:
```
[Role: SYSADMIN ▼] [Warehouse: COMPUTE_WH ▼] [Database: EXERCISES_DB ▼] [Schema: PUBLIC ▼]
```

**Always verify these are set correctly before running queries!**

**Standard Context for All Exercises:**
- **Role:** SYSADMIN
- **Warehouse:** COMPUTE_WH
- **Database:** EXERCISES_DB
- **Schema:** PUBLIC

---

### Step 6: Choose Your Exercise

| Exercise | Topic | Time | Difficulty | Start Here |
|----------|-------|------|------------|------------|
| [Exercise 27](Exercise-27-Time-Travel-Native/) | Time Travel & Cloning | 25 min | ⭐ Beginner | **Start here if new to Snowflake** |
| [Exercise 26](Exercise-26-Clustering-Native/) | Clustering & Performance | 30 min | ⭐⭐ Intermediate | Do this second |

**Recommended order:**
1. Start with Exercise 27 (easier concepts, immediate "wow" factor)
2. Then do Exercise 26 (more complex, performance optimization)

---

## Understanding the Exercise Structure

Each exercise folder contains:

**1. README.md**
- Exercise overview and learning objectives
- Step-by-step instructions
- What to expect

**2. 1_setup.sql**
- Run this FIRST to generate test data
- Just copy-paste and run
- Creates tables in your EXERCISES_DB

**3. 2_challenge.sql**
- YOUR hands-on work
- Contains TODOs you must complete
- Requires thinking and problem-solving
- Spaces to record your observations

**4. 3_solution.sql**
- Reference solution to check your work
- Detailed explanations
- Compare with your approach

**5. 4_advanced_exploration.sql** (Optional)
- Bonus challenges
- Advanced concepts
- Experimentation playground

**6. validation_quiz.md**
- Self-check questions
- Test your understanding
- No coding, just concepts

---

## Exercise Workflow

**For each exercise, follow this pattern:**

1. **Open README.md** (on GitHub) → Read the overview
2. **Open "Exercise X - Setup" worksheet** → Copy 1_setup.sql → Run it
3. **Open "Exercise X - Challenge" worksheet** → Copy 2_challenge.sql → Complete TODOs
4. **Open "Exercise X - Solution" worksheet** → Copy 3_solution.sql → Compare
5. **Open validation_quiz.md** (on GitHub) → Check your understanding

---

## Database & Schema Names Used

**Throughout all exercises:**

| Component | Name | Purpose |
|-----------|------|---------|
| **Database** | `EXERCISES_DB` | Contains all exercise tables |
| **Schema** | `PUBLIC` | Default schema for all tables |
| **Warehouse** | `COMPUTE_WH` | Compute engine (X-Small size) |
| **Role** | `SYSADMIN` | Your working role |

**Exercise 26 Tables:**
- `sales_non_clustered` - Table without clustering keys
- `sales_clustered` - Table with clustering (you create this)

**Exercise 27 Tables:**
- `customers` - Customer table for Time Travel exercise
- `customers_test` - Cloned table (you create this)

---

## Cost Estimate

**Total cost for both exercises:** < $0.20 USD

**Breakdown:**
- Exercise 26: ~$0.10 (30 min on X-Small warehouse)
- Exercise 27: ~$0.08 (25 min on X-Small warehouse)

**Tips to minimize costs:**
- Set warehouse auto-suspend to 1 minute
- Stop warehouse when done: `ALTER WAREHOUSE COMPUTE_WH SUSPEND;`
- Free trial includes $400 credits - more than enough!

---

## Important Snowflake Concepts

**Before starting, understand these basics:**

**Warehouse:**
- Your compute engine (like a server)
- Costs money while running
- Auto-suspends when idle (saves money)
- X-Small is perfect for learning

**Database:**
- Container for schemas and tables
- Like a folder for organizing data
- We use: `EXERCISES_DB`

**Schema:**
- Container for tables within a database
- We use: `PUBLIC` (default schema)

**Role:**
- Determines your permissions
- `ACCOUNTADMIN` = full access (use for setup only)
- `SYSADMIN` = development work (use for exercises)

**Query Profile:**
- Visual execution plan for queries
- Click any blue Query ID link to open it
- Shows performance metrics, partition scanning
- This is KEY for Exercise 26!

---

## Troubleshooting Common Issues

**"Insufficient privileges to operate on schema"**
- Solution: Make sure you ran the setup code in Step 3
- Or: Use `ACCOUNTADMIN` role for that query

**"Warehouse not found: COMPUTE_WH"**
- Solution: Create warehouse (see Step 2.2)
- Or: Use a different warehouse name in your queries

**"Object does not exist" error**
- Solution: Check your context (Database/Schema dropdowns)
- Make sure you're using `EXERCISES_DB` database
- Run the setup SQL first before challenge SQL

**Worksheet dropdowns are empty**
- Solution: Create the database first using SQL (Step 3)
- Then refresh the page
- Dropdowns will populate

**Can't find Query Profile**
- Solution: After running a query, look for blue underlined Query ID
- Click it to open Query Profile in new tab
- Located at bottom of results panel

**Warehouse is suspended / won't start**
- Solution: Click warehouse dropdown → Select COMPUTE_WH
- It will auto-resume (takes ~5 seconds)

---

## Tips for Success

**✅ DO:**
- Read README files carefully before starting
- Record your observations in the challenge worksheets
- Use Query Profile to visualize performance (Exercise 26)
- Experiment and try different approaches
- Complete validation quizzes to test understanding

**❌ DON'T:**
- Copy-paste solution without understanding
- Skip the setup SQL files
- Ignore Query Profile analysis
- Rush through TODOs
- Forget to suspend warehouse when done

---

## Learning Path

**Complete Beginner to Snowflake?**
1. Complete Step 1-5 above (setup)
2. Start with Exercise 27 (Time Travel)
3. Then do Exercise 26 (Clustering)
4. Try advanced exploration files

**Some SQL Experience?**
1. Complete Step 1-5 above (setup)
2. Do both exercises in any order
3. Focus on Query Profile in Exercise 26
4. Complete bonus challenges

**Want to Go Deeper?**
1. Complete both exercises
2. Do all advanced exploration challenges
3. Modify exercises with your own data
4. Explore Snowflake documentation

---

## Need Help?

**Resources:**
- Snowflake Documentation: https://docs.snowflake.com/
- Snowflake Community: https://community.snowflake.com/
- Exercise-specific README files in each folder
- Validation quizzes to check understanding

**Found a bug or have suggestions?**
- Open an issue on GitHub
- Submit a pull request
- Help improve these exercises for others!

---

## Next Steps

**Ready to start?**

1. ✅ Complete Steps 1-5 above (if you haven't already)
2. ✅ Choose Exercise 27 or 26
3. ✅ Open the exercise folder
4. ✅ Read the exercise README.md
5. ✅ Start with 1_setup.sql

**Let's learn Snowflake! 🚀**
