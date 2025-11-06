import snowflake.connector
from datetime import datetime
import time
import os
from dotenv import load_dotenv

load_dotenv()

print("=" * 70)
print("EXERCISE 27: SNOWFLAKE TIME TRAVEL - SOLUTION")
print("=" * 70)

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

# Get the Query ID from the initial count - this is the state before deletion
cursor.execute("SELECT COUNT(*) FROM customers WHERE state = 'CA'")
ca_customers_before_result = cursor.fetchone()
ca_customers_before = ca_customers_before_result[0]

# Capture the query ID to use for Time Travel
query_id_before_deletion = cursor.sfqid
print(f"Query ID captured: {query_id_before_deletion}")

timestamp_before_deletion = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
print(f"Current timestamp: {timestamp_before_deletion}")

time.sleep(3)  # Small delay to create time separation

print("\n" + "="*70)
print("STEP 2: SIMULATE ACCIDENTAL DELETION")
print("="*70)

print("\n⚠️  Deleting California customers...")
cursor.execute("DELETE FROM customers WHERE state = 'CA'")

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

print(f"\nUsing Time Travel with query ID to see data before deletion...")
cursor.execute(f"""
    SELECT COUNT(*) FROM customers
    BEFORE(STATEMENT => '{query_id_before_deletion}')
    WHERE state = 'CA'
""")
ca_historical = cursor.fetchone()[0]
print(f"\nCA customers before deletion (Time Travel): {ca_historical:,}")
print("✓ Time Travel lets us see the data as it was!")

print("\n" + "="*70)
print("STEP 4: RECOVER DELETED RECORDS")
print("="*70)

print("\nRecovering deleted records using Time Travel...")
cursor.execute(f"""
    INSERT INTO customers
    SELECT * FROM customers
    BEFORE(STATEMENT => '{query_id_before_deletion}')
    WHERE state = 'CA'
""")

cursor.execute("SELECT COUNT(*) FROM customers")
total_after_recovery = cursor.fetchone()[0]

cursor.execute("SELECT COUNT(*) FROM customers WHERE state = 'CA'")
ca_after_recovery = cursor.fetchone()[0]

print(f"\n✓ Recovery complete!")
print(f"  Total customers: {total_after_recovery:,}")
print(f"  California customers: {ca_after_recovery:,}")

print("\n" + "="*70)
print("STEP 5: CREATE ZERO-COPY CLONE")
print("="*70)

cursor.execute("CREATE OR REPLACE TABLE customers_test CLONE customers")
print("\n✓ Test environment clone created")

cursor.execute("SELECT COUNT(*) FROM customers_test")
test_count = cursor.fetchone()[0]

print(f"\nOriginal table: {total_after_recovery:,} customers")
print(f"Cloned table: {test_count:,} customers")
print(f"\n✓ Same data, zero storage overhead initially!")

print("\n" + "="*70)
print("KEY LEARNINGS")
print("="*70)
print("\n1. Time Travel saved the day - recovered {ca_after_recovery:,} deleted records")
print("2. AT clause lets you query any historical point")
print("3. Zero-copy clones provide instant test environments")
print("4. No storage cost until you modify the clone")
print("\nThis is why Snowflake's architecture is so powerful!")
print("="*70)

cursor.close()
conn.close()
