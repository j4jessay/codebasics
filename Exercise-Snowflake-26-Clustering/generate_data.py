import snowflake.connector
import pandas as pd
from faker import Faker
import random
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv

load_dotenv()
fake = Faker()
random.seed(42)

print("=" * 60)
print("GENERATING SALES DATA FOR SNOWFLAKE")
print("=" * 60)

# Connect to Snowflake
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

# Create database and schema if they don't exist
cursor.execute(f"CREATE DATABASE IF NOT EXISTS {os.getenv('SNOWFLAKE_DATABASE')}")
cursor.execute(f"USE DATABASE {os.getenv('SNOWFLAKE_DATABASE')}")
cursor.execute(f"CREATE SCHEMA IF NOT EXISTS {os.getenv('SNOWFLAKE_SCHEMA')}")

print("\n✓ Connected to Snowflake")
print(f"  Database: {os.getenv('SNOWFLAKE_DATABASE')}")
print(f"  Schema: {os.getenv('SNOWFLAKE_SCHEMA')}")

# Generate sales data
num_records = 50000  # Reduced for faster demo
print(f"\nGenerating {num_records:,} sales records...")

orders = []
regions = ['US_EAST', 'US_WEST', 'EU_NORTH', 'EU_SOUTH', 'ASIA']
products = ['Laptop', 'Phone', 'Tablet', 'Monitor', 'Keyboard', 'Mouse', 'Headphones', 'Webcam', 'Speaker', 'Printer']

for i in range(num_records):
    order = {
        'order_id': f'ORD{i+1:06d}',
        'customer_id': f'CUST{random.randint(1, 10000):05d}',
        'order_date': (datetime(2024, 1, 1) + timedelta(days=random.randint(0, 300))).strftime('%Y-%m-%d'),
        'order_amount': round(random.uniform(10.0, 1000.0), 2),
        'region': random.choice(regions),
        'product_name': f"{random.choice(products)} {fake.word().capitalize()}"
    }
    orders.append(order)
    
    if (i + 1) % 10000 == 0:
        print(f"  Generated {i+1:,} records...")

df = pd.DataFrame(orders)

print(f"\n✓ Data generation complete: {len(df):,} records")
print("\nLoading to Snowflake (this may take a minute)...")

# Create non-clustered table
cursor.execute("""
    CREATE OR REPLACE TABLE sales_non_clustered (
        order_id VARCHAR,
        customer_id VARCHAR,
        order_date DATE,
        order_amount DECIMAL(10,2),
        region VARCHAR,
        product_name VARCHAR
    )
""")

# Insert data using batch inserts (avoids S3 staging issues)
print("Inserting records in batches...")
batch_size = 1000
for i in range(0, len(df), batch_size):
    batch = df.iloc[i:i+batch_size]
    values = []
    for _, row in batch.iterrows():
        # Escape single quotes in product name
        product_name = row['product_name'].replace("'", "''")
        values.append(f"('{row['order_id']}', '{row['customer_id']}', '{row['order_date']}', {row['order_amount']}, '{row['region']}', '{product_name}')")

    insert_sql = f"""
        INSERT INTO sales_non_clustered (order_id, customer_id, order_date, order_amount, region, product_name)
        VALUES {', '.join(values)}
    """
    cursor.execute(insert_sql)

    if (i + batch_size) % 10000 == 0 or (i + batch_size) >= len(df):
        print(f"  Inserted {min(i + batch_size, len(df)):,} / {len(df):,} records...")

print(f"✓ Loaded {len(df):,} records to SALES_NON_CLUSTERED table")
print("\nNow run: docker-compose up run")
print("=" * 60)

cursor.close()
conn.close()
