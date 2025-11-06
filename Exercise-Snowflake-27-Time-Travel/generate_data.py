import snowflake.connector
import pandas as pd
from faker import Faker
import random
import os
import time
from dotenv import load_dotenv

load_dotenv()
fake = Faker()
random.seed(42)

print("=" * 60)
print("GENERATING CUSTOMER DATA FOR TIME TRAVEL EXERCISE")
print("=" * 60)

conn = snowflake.connector.connect(
    account=os.getenv('SNOWFLAKE_ACCOUNT'),
    user=os.getenv('SNOWFLAKE_USER'),
    password=os.getenv('SNOWFLAKE_PASSWORD'),
    warehouse=os.getenv('SNOWFLAKE_WAREHOUSE'),
    database=os.getenv('SNOWFLAKE_DATABASE'),
    schema=os.getenv('SNOWFLAKE_SCHEMA')
)

cursor = conn.cursor()

print("\n✓ Connected to Snowflake")

# Generate customer data
num_customers = 10000  # Reduced for demo
print(f"\nGenerating {num_customers:,} customer records...")

states = ['CA', 'NY', 'TX', 'FL', 'IL', 'PA', 'OH', 'GA', 'NC', 'MI']
statuses = ['active', 'inactive', 'suspended']

customers = []
for i in range(num_customers):
    customer = {
        'customer_id': f'CUST{i+1:05d}',
        'first_name': fake.first_name(),
        'last_name': fake.last_name(),
        'email': fake.email(),
        'state': random.choice(states),
        'signup_date': fake.date_between(start_date='-2y', end_date='today').strftime('%Y-%m-%d'),
        'account_status': random.choice(statuses)
    }
    customers.append(customer)
    
    if (i + 1) % 2000 == 0:
        print(f"  Generated {i+1:,} customers...")

df = pd.DataFrame(customers)

# Count CA customers
ca_count = len(df[df['state'] == 'CA'])
print(f"\n✓ Generated {len(df):,} total customers")
print(f"  California customers: {ca_count:,}")

# Create table if not exists, otherwise truncate to preserve Time Travel history
cursor.execute("SHOW TABLES LIKE 'CUSTOMERS'")
table_exists = len(cursor.fetchall()) > 0

if table_exists:
    print("\n✓ Table exists, truncating to preserve Time Travel history...")
    cursor.execute("TRUNCATE TABLE customers")
else:
    print("\n✓ Creating new table...")
    cursor.execute("""
        CREATE TABLE customers (
            customer_id VARCHAR,
            first_name VARCHAR,
            last_name VARCHAR,
            email VARCHAR,
            state VARCHAR,
            signup_date DATE,
            account_status VARCHAR
        )
    """)

print("✓ Loading data...")

# Insert data in batches using direct SQL (avoids S3 staging issues)
batch_size = 1000
for i in range(0, len(df), batch_size):
    batch = df[i:i+batch_size]
    values = []
    for _, row in batch.iterrows():
        values.append(f"('{row['customer_id']}', '{row['first_name']}', '{row['last_name']}', "
                     f"'{row['email']}', '{row['state']}', '{row['signup_date']}', '{row['account_status']}')")

    insert_sql = f"INSERT INTO customers VALUES {', '.join(values)}"
    cursor.execute(insert_sql)

    if (i + batch_size) % 2000 == 0 or (i + batch_size) >= len(df):
        loaded = min(i + batch_size, len(df))
        print(f"  Loaded {loaded:,} customers...")

print(f"\n✓ Loaded {len(df):,} customers to Snowflake")
print(f"  Table: CUSTOMERS")
print(f"\n⏳ Waiting 15 seconds to establish Time Travel history...")
time.sleep(15)
print(f"✓ Ready! Time Travel history established")
print(f"\nNow run: docker-compose up run")
print("=" * 60)

cursor.close()
conn.close()
