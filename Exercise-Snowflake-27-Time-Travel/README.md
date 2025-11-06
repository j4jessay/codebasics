# Exercise 27: Snowflake - Time Travel & Zero-Copy Cloning

## Quick Start

**Mac/Linux:**
```bash
# Step 1: Set your Snowflake credentials
cp .env.example .env
# Edit .env with your credentials (sign up at https://signup.snowflake.com/)

# Step 2: Run setup
chmod +x setup.sh
./setup.sh                          # Generates customer data in Snowflake
# Complete TODOs in main_challenge.py
docker compose up run               # Test your solution
docker compose up solution          # Compare with reference solution
```

**Windows PowerShell:**
```powershell
# Step 1: Set your Snowflake credentials
Copy-Item .env.example .env
# Edit .env with your credentials (sign up at https://signup.snowflake.com/)

# Step 2: Run setup
.\setup.ps1                         # Generates customer data in Snowflake
# Complete TODOs in main_challenge.py
docker compose up run               # Test your solution
docker compose up solution          # Compare with reference solution
```

## What You'll Learn

- Use Time Travel to query historical data
- Recover accidentally deleted records using AT and BEFORE clauses
- Create zero-copy clones for test environments
- Understand copy-on-write mechanism
- Query data at specific points in time

## The Problem

A junior analyst accidentally ran `DELETE FROM customers WHERE state = 'CA'` in production, deleting 5,000 customer records. The dashboard is broken and the business team is panicking. You need to recover the data quickly using Snowflake's Time Travel feature!

## Your Task

Open `main_challenge.py` and complete the TODOs to recover deleted data using Time Travel:

1. **TODO 1:** Execute the accidental deletion
   - Uncomment the DELETE statement
   - Remove CA customers from the table
   - Verify the deletion occurred

2. **TODO 2:** Use Time Travel to view historical data
   - Query the customers table using AT(TIMESTAMP => ...) clause
   - Count CA customers as they existed before deletion
   - Use the timestamp captured before deletion

3. **TODO 3:** Recover deleted records
   - Use INSERT INTO with SELECT from historical data
   - Filter for CA customers and exclude existing customer_ids
   - Verify all records are recovered

4. **TODO 4:** Create a zero-copy clone
   - Create customers_test table using CLONE syntax
   - Understand that no additional storage is used initially

5. **TODO 5:** Verify the clone
   - Count records in both original and cloned tables
   - Confirm they match
   - Print the results

After completing these steps, you'll understand how Snowflake's Time Travel makes disaster recovery incredibly easy!

## Expected Results

With 10,000 customer records loaded:
- ~5,000 CA customers deleted
- Successfully recover all deleted records using Time Travel
- Zero-copy clone created instantly with no storage overhead
- Total recovery time: seconds, not hours

**Note**: Data generation is **required**. The setup script loads 10,000 customer records into Snowflake.

## Key Concepts

**Time Travel**: Query data as it existed at any point within the retention period (default: 1 day for Standard Edition, up to 90 days for Enterprise)

**Zero-Copy Cloning**: Create a copy of a table/schema/database that shares the underlying data files until modifications are made (copy-on-write)

## Troubleshooting

### Data Not Loading?
If `./setup.sh` fails to load data:

1. **Check Snowflake Connection**:
   ```sql
   -- Log into Snowflake UI and verify:
   SELECT COUNT(*) FROM EXERCISES_DB.PUBLIC.CUSTOMERS;
   -- Should show 10,000 records
   ```

2. **Network/Firewall Issues**:
   - Ensure Docker can access Snowflake
   - Check credentials in .env file
   - Verify warehouse is running

3. **Verify Data Loaded Successfully**:
   ```bash
   docker compose run solution python -c "
   import snowflake.connector
   import os
   from dotenv import load_dotenv
   load_dotenv()
   conn = snowflake.connector.connect(
       account=os.getenv('SNOWFLAKE_ACCOUNT'),
       user=os.getenv('SNOWFLAKE_USER'),
       password=os.getenv('SNOWFLAKE_PASSWORD'),
       warehouse=os.getenv('SNOWFLAKE_WAREHOUSE'),
       database=os.getenv('SNOWFLAKE_DATABASE'),
       schema=os.getenv('SNOWFLAKE_SCHEMA')
   )
   cursor = conn.cursor()
   cursor.execute('SELECT COUNT(*) FROM CUSTOMERS')
   print(f'Records loaded: {cursor.fetchone()[0]:,}')
   "
   ```

Expected output: `Records loaded: 10,000`
