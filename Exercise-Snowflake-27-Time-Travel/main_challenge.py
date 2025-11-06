import snowflake.connector
from datetime import datetime
import time
import os
from dotenv import load_dotenv

load_dotenv()

print("=" * 70)
print("EXERCISE 27: SNOWFLAKE TIME TRAVEL & ZERO-COPY CLONING")
print("=" * 70)

# Establish connection (provided as scaffolding)
conn = snowflake.connector.connect(
    account=os.getenv('SNOWFLAKE_ACCOUNT'),
    user=os.getenv('SNOWFLAKE_USER'),
    password=os.getenv('SNOWFLAKE_PASSWORD'),
    warehouse=os.getenv('SNOWFLAKE_WAREHOUSE'),
    database=os.getenv('SNOWFLAKE_DATABASE'),
    schema=os.getenv('SNOWFLAKE_SCHEMA')
)

cursor = conn.cursor()

print("\n" + "="*70)
print("STEP 1: CHECK INITIAL DATA")
print("="*70)

cursor.execute("SELECT COUNT(*) FROM customers")
total_customers = cursor.fetchone()[0]
print(f"\nTotal customers: {total_customers:,}")

cursor.execute("SELECT COUNT(*) FROM customers WHERE state = 'CA'")
ca_customers_before = cursor.fetchone()[0]
print(f"California customers: {ca_customers_before:,}")

# Capture timestamp before deletion (provided for your use)
timestamp_before_deletion = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
print(f"Current timestamp: {timestamp_before_deletion}")

# Small delay to ensure timestamp difference
time.sleep(2)

print("\n" + "="*70)
print("STEP 2: SIMULATE ACCIDENTAL DELETION")
print("="*70)

print("\n⚠️  Simulating accidental deletion...")
print("Command: DELETE FROM customers WHERE state = 'CA'")

# TODO 1: Execute the accidental deletion
# - Uncomment the DELETE statement below
# - Execute it using cursor.execute()
# - This will delete all California customers
#
# WARNING: This is intentional! We'll recover the data using Time Travel

# YOUR CODE HERE
print("\n⚠️  TODO 1: Uncomment and execute the DELETE statement")
# cursor.execute("DELETE FROM customers WHERE state = 'CA'")

cursor.execute("SELECT COUNT(*) FROM customers")
total_after_delete = cursor.fetchone()[0]

cursor.execute("SELECT COUNT(*) FROM customers WHERE state = 'CA'")
ca_customers_after = cursor.fetchone()[0]

print(f"\nAfter deletion:")
print(f"  Total customers: {total_after_delete:,}")
print(f"  California customers: {ca_customers_after:,}")
print(f"  Records deleted: {ca_customers_before - ca_customers_after:,}")

print("\n" + "="*70)
print("STEP 3: USE TIME TRAVEL TO VIEW HISTORICAL DATA")
print("="*70)

print("\nUsing Time Travel to see data before deletion...")

# TODO 2: Query historical data using Time Travel
# - Write a query to count CA customers as they existed before deletion
# - Use the AT(TIMESTAMP => ...) clause with timestamp_before_deletion
# - Execute the query and fetch the result
# - Print the count
#
# Hint: SELECT COUNT(*) FROM customers AT(TIMESTAMP => 'your_timestamp'::timestamp) WHERE state = 'CA'
# Note: The timestamp_before_deletion variable is available from earlier

# YOUR CODE HERE
print("\n⚠️  TODO 2: Query historical data using AT(TIMESTAMP => ...) clause")

# cursor.execute(f"""
#     YOUR SQL HERE
# """)
# ca_historical = cursor.fetchone()[0]
# print(f"CA customers before deletion (Time Travel): {ca_historical:,}")
# print("✓ Time Travel lets us see the data as it was!")

print("\n" + "="*70)
print("STEP 4: RECOVER DELETED RECORDS")
print("="*70)

print("\nRecovering deleted California customers...")

# TODO 3: Recover the deleted records
# - Use INSERT INTO customers with SELECT from the historical table
# - Use AT(TIMESTAMP => ...) clause to get data before deletion
# - Filter for state = 'CA'
# - Execute the recovery query
# - Query and print the counts to verify recovery
#
# Hint: INSERT INTO customers SELECT * FROM customers AT(TIMESTAMP => ...) WHERE state = 'CA'
# Note: The original solution doesn't filter by customer_id, so you can insert all CA customers from history

# YOUR CODE HERE
print("\n⚠️  TODO 3: Recover deleted records using INSERT INTO...SELECT with Time Travel")

# cursor.execute(f"""
#     YOUR SQL HERE
# """)
#
# cursor.execute("SELECT COUNT(*) FROM customers")
# total_after_recovery = cursor.fetchone()[0]
#
# cursor.execute("SELECT COUNT(*) FROM customers WHERE state = 'CA'")
# ca_after_recovery = cursor.fetchone()[0]
#
# print(f"\n✓ Recovery complete!")
# print(f"  Total customers: {total_after_recovery:,}")
# print(f"  California customers: {ca_after_recovery:,}")

print("\n" + "="*70)
print("STEP 5: CREATE ZERO-COPY CLONE")
print("="*70)

print("\nCreating test environment clone...")

# TODO 4: Create a zero-copy clone
# - Create a table named customers_test
# - Use the CLONE keyword to clone the customers table
# - Print a success message
#
# Hint: CREATE OR REPLACE TABLE customers_test CLONE customers

# YOUR CODE HERE
print("\n⚠️  TODO 4: Create zero-copy clone using CLONE syntax")

# cursor.execute("""
#     YOUR SQL HERE
# """)
# print("\n✓ Test environment clone created")

# TODO 5: Verify the clone
# - Query the count from customers_test table
# - Print both original and cloned table counts
# - Print a message about zero storage overhead
#
# Remember: Zero-copy clones share the same data files until modifications are made

# YOUR CODE HERE
print("\n⚠️  TODO 5: Verify the clone by counting records")

# cursor.execute("SELECT COUNT(*) FROM customers_test")
# test_count = cursor.fetchone()[0]
#
# cursor.execute("SELECT COUNT(*) FROM customers")
# original_count = cursor.fetchone()[0]
#
# print(f"\nOriginal table: {original_count:,} customers")
# print(f"Cloned table: {test_count:,} customers")
# print(f"\n✓ Same data, zero storage overhead initially!")

print("\n" + "="*70)
print("KEY LEARNINGS")
print("="*70)
print("\n1. Time Travel allows querying data at any historical point")
print("2. AT clause enables disaster recovery in seconds")
print("3. Zero-copy clones provide instant test environments")
print("4. No storage cost until you modify the clone (copy-on-write)")
print("\nThis is why Snowflake's architecture is so powerful!")
print("="*70)

cursor.close()
conn.close()

print("\n" + "="*70)
print("⚠️  CHALLENGE NOT COMPLETED")
print("="*70)
print("Complete all TODOs above to experience Time Travel and Cloning!")
print("="*70)
