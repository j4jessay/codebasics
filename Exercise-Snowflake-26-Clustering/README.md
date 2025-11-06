# Exercise 26: Snowflake - Clustering Keys & Query Performance

## Quick Start

**Mac/Linux:**
```bash
# Step 1: Set your Snowflake credentials
cp .env.example .env
# Edit .env with your credentials (sign up at https://signup.snowflake.com/)

# Step 2: Run setup
chmod +x setup.sh
./setup.sh                          # Generates sales data in Snowflake
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
.\setup.ps1                         # Generates sales data in Snowflake
# Complete TODOs in main_challenge.py
docker compose up run               # Test your solution
docker compose up solution          # Compare with reference solution
```

## What You'll Learn

- Understand Snowflake's micro-partitioning
- Create tables with clustering keys
- Monitor clustering depth with SYSTEM$CLUSTERING_DEPTH
- Compare query performance with partition pruning
- Use Query Profile to analyze partition scans

## The Problem

Your sales table has 5 million records. Analysts run queries like "Show me all sales from US_EAST in October 2024." Without clustering, Snowflake scans most micro-partitions even though only a small subset contains relevant data, resulting in slow queries.

## Your Task

Open `main_challenge.py` and complete the TODOs to optimize query performance with clustering:

1. **TODO 1:** Write a query to test the non-clustered table
   - Query sales_non_clustered table
   - Filter by region='US_EAST' and October 2024 dates
   - Measure execution time

2. **TODO 2:** Create a clustered table
   - Use CLUSTER BY clause with (order_date, region)
   - Copy data from non-clustered table

3. **TODO 3:** Check clustering depth
   - Use SYSTEM$CLUSTERING_DEPTH function
   - Verify clustering quality (depth < 2 is excellent)

4. **TODO 4:** Query the clustered table
   - Run the same query on sales_clustered table
   - Measure execution time

5. **TODO 5:** Compare and display results
   - Calculate performance improvement
   - Show time difference between clustered and non-clustered

After completing these steps, you'll see how clustering dramatically improves query performance through partition pruning!

## Expected Results

With 50,000 records loaded:
- Non-clustered: Slower queries, scans many partitions
- Clustered: Faster queries, scans only relevant partitions
- Improvement: 3-5x performance boost with partition pruning

**Note**: Data generation is **required** for meaningful results. The setup script loads 50,000 sales records into Snowflake.

## Troubleshooting

### Data Not Loading?
If `./setup.sh` fails to load data:

1. **Check Snowflake Connection**:
   ```sql
   -- Log into Snowflake UI and verify:
   SELECT COUNT(*) FROM EXERCISES_DB.PUBLIC.SALES_NON_CLUSTERED;
   -- Should show 50,000 records
   ```

2. **Network/Firewall Issues**:
   - Ensure Docker can access Snowflake's S3 storage
   - Check if your network blocks AWS S3 connections
   - Try running from a different network if blocked

3. **Manual Data Load** (if automated fails):
   - Generate CSV locally: `docker compose run generate-data python -c "import generate_data"`
   - Upload via Snowflake UI (Worksheets → Load Data)

### Verify Data Loaded Successfully
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
cursor.execute('SELECT COUNT(*) FROM SALES_NON_CLUSTERED')
print(f'Records loaded: {cursor.fetchone()[0]:,}')
"
```

Expected output: `Records loaded: 50,000`
