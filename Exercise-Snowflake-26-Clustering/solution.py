import snowflake.connector
import time
import os
from dotenv import load_dotenv

load_dotenv()

print("=" * 70)
print("EXERCISE 26: SNOWFLAKE CLUSTERING - SOLUTION")
print("=" * 70)

conn = snowflake.connector.connect(
    account=os.getenv('SNOWFLAKE_ACCOUNT'),
    user=os.getenv('SNOWFLAKE_USER'),
    password=os.getenv('SNOWFLAKE_PASSWORD'),
    warehouse=os.getenv('SNOWFLAKE_WAREHOUSE'),
    database=os.getenv('SNOWFLAKE_DATABASE'),
    schema=os.getenv('SNOWFLAKE_SCHEMA'),
    ocsp_fail_open=True  # Bypass OCSP certificate validation issues
)

cursor = conn.cursor()

def run_query(query, label):
    print(f"\n[{label}]")
    print(f"Query: {query[:80]}...")
    start_time = time.time()
    cursor.execute(query)
    results = cursor.fetchall()
    elapsed = time.time() - start_time
    print(f"Results: {len(results)} rows")
    print(f"Time: {elapsed:.2f} seconds")
    return elapsed, len(results)

print("\n" + "="*70)
print("STEP 1: QUERY NON-CLUSTERED TABLE")
print("="*70)

test_query = """
    SELECT * FROM sales_non_clustered
    WHERE region = 'US_EAST'
    AND order_date >= '2024-10-01'
    AND order_date < '2024-11-01'
"""

time_non_clustered, count_non_clustered = run_query(test_query, "NON-CLUSTERED TABLE")

print("\n" + "="*70)
print("STEP 2: CREATE CLUSTERED TABLE")
print("="*70)

print("\nCreating table with clustering keys...")
cursor.execute("""
    CREATE OR REPLACE TABLE sales_clustered
    CLUSTER BY (order_date, region)
    AS SELECT * FROM sales_non_clustered
""")
print("✓ Clustered table created")

print("\n" + "="*70)
print("STEP 3: CHECK CLUSTERING DEPTH")
print("="*70)

cursor.execute("""
    SELECT SYSTEM$CLUSTERING_DEPTH('sales_clustered', '(order_date, region)')
""")
depth = cursor.fetchone()[0]
print(f"\nClustering Depth: {depth}")

if depth < 2:
    print("✓ Excellent clustering (depth < 2)")

print("\n" + "="*70)
print("STEP 4: QUERY CLUSTERED TABLE")
print("="*70)

time_clustered, count_clustered = run_query(test_query.replace('sales_non_clustered', 'sales_clustered'), "CLUSTERED TABLE")

print("\n" + "="*70)
print("COMPARISON RESULTS")
print("="*70)

print("\nNon-Clustered Table:")
print(f"  Query Time: {time_non_clustered:.2f} seconds")
print(f"  Results: {count_non_clustered} rows")

print("\nClustered Table:")
print(f"  Query Time: {time_clustered:.2f} seconds")
print(f"  Results: {count_clustered} rows")

improvement = time_non_clustered / time_clustered if time_clustered > 0 else 0
print(f"\n✓ Performance Improvement: {improvement:.1f}x faster")
print("\nClustering enables partition pruning - Snowflake skips partitions")
print("that don't contain data matching your filter conditions.")
print("\nTip: Check Query Profile in Snowflake UI to see the difference!")
print("="*70)

cursor.close()
conn.close()
