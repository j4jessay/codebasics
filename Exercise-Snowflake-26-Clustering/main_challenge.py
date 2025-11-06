import snowflake.connector
import time
import os
from dotenv import load_dotenv

load_dotenv()

print("=" * 70)
print("EXERCISE 26: SNOWFLAKE CLUSTERING KEYS & QUERY PERFORMANCE")
print("=" * 70)

# Establish connection and create cursor (provided as scaffolding)
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
    """Run a query and measure execution time."""
    # TODO: Implement this helper function
    # - Print the label and query (first 80 chars)
    # - Measure start time using time.time()
    # - Execute the query using cursor.execute()
    # - Fetch all results using cursor.fetchall()
    # - Calculate elapsed time
    # - Print number of rows and time
    # - Return (elapsed_time, row_count)

    # YOUR CODE HERE
    print(f"\n⚠️  run_query() not implemented for: {label}")
    return 0, 0

print("\n" + "="*70)
print("STEP 1: QUERY NON-CLUSTERED TABLE")
print("="*70)

# TODO 1: Write and execute a query on the non-clustered table
# - SELECT * FROM sales_non_clustered table
# - WHERE region = 'US_EAST'
# - AND order_date >= '2024-10-01' AND order_date < '2024-11-01'
# - Store query in test_query_non_clustered variable
# - Execute using run_query() and store results in time_non_clustered, count_non_clustered
#
# This query will scan many partitions without clustering

# YOUR CODE HERE
print("\n⚠️  TODO 1: Write and execute query for non-clustered table")

# test_query_non_clustered = ""  # Replace with your SQL query
# time_non_clustered, count_non_clustered = run_query(test_query_non_clustered, "NON-CLUSTERED TABLE")

print("\n" + "="*70)
print("STEP 2: CREATE CLUSTERED TABLE")
print("="*70)

print("\nCreating table with clustering keys...")

# TODO 2: Create a clustered table
# - CREATE OR REPLACE TABLE sales_clustered
# - Use CLUSTER BY (order_date, region)
# - Copy all data from sales_non_clustered (AS SELECT * FROM ...)
# - Execute using cursor.execute()
# - Print success message
#
# Hint: Clustering keys should match your most common filter columns

# YOUR CODE HERE
print("⚠️  TODO 2: Create clustered table with CLUSTER BY clause")

# cursor.execute("""
#     YOUR SQL HERE
# """)
# print("✓ Clustered table created")

print("\n" + "="*70)
print("STEP 3: CHECK CLUSTERING DEPTH")
print("="*70)

print("\nChecking clustering quality...")

# TODO 3: Check clustering depth
# - Use SYSTEM$CLUSTERING_DEPTH('sales_clustered', '(order_date, region)')
# - Execute query using cursor.execute()
# - Fetch the result using cursor.fetchone()[0]
# - Print the clustering depth
# - If depth < 2, print "✓ Excellent clustering"
# - Otherwise print "⚠ Clustering could be improved"
#
# Clustering depth < 2 means data is well-organized

# YOUR CODE HERE
print("⚠️  TODO 3: Check clustering depth using SYSTEM$CLUSTERING_DEPTH")

# cursor.execute("""
#     YOUR SQL HERE
# """)
# depth = cursor.fetchone()[0]
# print(f"Clustering Depth: {depth}")
#
# if depth < 2:
#     print("✓ Excellent clustering (depth < 2)")
# else:
#     print("⚠ Clustering could be improved")

print("\n" + "="*70)
print("STEP 4: QUERY CLUSTERED TABLE")
print("="*70)

# TODO 4: Query the clustered table
# - Write the same query as TODO 1, but for sales_clustered table
# - Execute using run_query()
# - Store results in time_clustered, count_clustered
# - This should be much faster due to partition pruning

# YOUR CODE HERE
print("⚠️  TODO 4: Query the clustered table (same query as TODO 1)")

# test_query_clustered = ""  # Replace with your SQL query
# time_clustered, count_clustered = run_query(test_query_clustered, "CLUSTERED TABLE")

print("\n" + "="*70)
print("STEP 5: COMPARE RESULTS")
print("="*70)

# TODO 5: Compare and display results
# - Print non-clustered table: query time and result count
# - Print clustered table: query time and result count
# - Calculate improvement: time_non_clustered / time_clustered
# - Print improvement factor (e.g., "5.2x faster")
# - Add tip about Query Profile in Snowflake UI
#
# This demonstrates the power of clustering for query optimization

# YOUR CODE HERE
print("⚠️  TODO 5: Display comparison and calculate performance improvement")

# print("\nNon-Clustered Table:")
# print(f"  Query Time: {time_non_clustered:.2f} seconds")
# print(f"  Results: {count_non_clustered} rows")
#
# print("\nClustered Table:")
# print(f"  Query Time: {time_clustered:.2f} seconds")
# print(f"  Results: {count_clustered} rows")
#
# improvement = time_non_clustered / time_clustered if time_clustered > 0 else 0
# print(f"\n✓ Performance Improvement: {improvement:.1f}x faster")
# print("\nClustering enables partition pruning - Snowflake skips partitions")
# print("that don't contain data matching your filter conditions.")
# print("\nTip: Check Query Profile in Snowflake UI to see the difference!")
# print("="*70)

cursor.close()
conn.close()

print("\n" + "="*70)
print("⚠️  CHALLENGE NOT COMPLETED")
print("="*70)
print("Complete all TODOs above to see clustering in action!")
print("="*70)
