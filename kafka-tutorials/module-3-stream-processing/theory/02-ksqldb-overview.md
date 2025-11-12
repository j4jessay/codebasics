# ksqlDB Overview

## 📖 Reading Time: 8 minutes

---

## What is ksqlDB?

**ksqlDB** is a database purpose-built for stream processing. It lets you process Kafka streams using SQL queries.

**Think of it as:** SQL for real-time data

---

## Why ksqlDB?

### Traditional Approach (Writing Code)

```java
// Kafka Streams API (complex!)
KStream<String, Order> orders = builder.stream("orders");
KStream<String, Order> highValue = orders.filter(
    (key, order) -> order.getAmount() > 1000
);
highValue.to("high-value-orders");
```

**Problems:**
- Requires Java/Scala knowledge
- Compile, package, deploy
- Maintain application code

---

### ksqlDB Approach (SQL)

```sql
-- Simple SQL!
CREATE STREAM high_value_orders AS
SELECT * FROM orders
WHERE amount > 1000;
```

**Benefits:**
- ✅ Use familiar SQL
- ✅ No compilation needed
- ✅ Interactive queries
- ✅ Rapid prototyping

---

## ksqlDB Architecture

```
┌─────────────────────────────────────┐
│         ksqlDB Server               │
│  (Processes SQL queries)            │
│                                     │
│  ┌───────────────────────────────┐ │
│  │   Query Engine                │ │
│  │   (Parses SQL, executes)      │ │
│  └───────────┬───────────────────┘ │
│              │                      │
└──────────────┼──────────────────────┘
               │
               ▼
        ┌──────────────┐
        │    Kafka     │
        │  (Topics)    │
        └──────────────┘
               ▲
               │
        ┌──────┴───────┐
        │  ksqlDB CLI  │
        │  (Your SQL)  │
        └──────────────┘
```

**Components:**
1. **ksqlDB Server:** Executes queries, interacts with Kafka
2. **ksqlDB CLI:** Interactive terminal for running queries
3. **Kafka:** Underlying event store

---

## How ksqlDB Works

### Step 1: Define a Stream

```sql
CREATE STREAM orders (
  order_id VARCHAR,
  customer_id VARCHAR,
  amount DOUBLE
) WITH (
  KAFKA_TOPIC='orders',
  VALUE_FORMAT='JSON'
);
```

This tells ksqlDB: "There's a Kafka topic called `orders` with this structure."

---

### Step 2: Query the Stream

```sql
-- View raw data
SELECT * FROM orders EMIT CHANGES;
```

Output:
```
+----------+-------------+--------+
| ORDER_ID | CUSTOMER_ID | AMOUNT |
+----------+-------------+--------+
| O001     | C123        | 50.00  |
| O002     | C456        | 150.00 |
| O003     | C123        | 75.00  |
```

**EMIT CHANGES:** Shows results continuously as new events arrive

---

### Step 3: Create Derived Stream

```sql
CREATE STREAM high_value_orders AS
SELECT * FROM orders
WHERE amount > 100;
```

This creates a **new Kafka topic** with filtered events!

---

## Streams vs Tables (Quick Intro)

### Stream: Sequence of Events

```sql
CREATE STREAM orders ...
```

**Represents:** A sequence of immutable events

**Example:** Order placed, order shipped, order delivered

**Query:** `SELECT * FROM orders EMIT CHANGES;`

---

### Table: Current State

```sql
CREATE TABLE customer_totals AS
SELECT customer_id, SUM(amount) AS total
FROM orders
GROUP BY customer_id;
```

**Represents:** Current aggregated state

**Example:** Total spent per customer (updates as new orders arrive)

**Query:** `SELECT * FROM customer_totals;`

---

## Data Formats

ksqlDB supports multiple formats:

| Format | Use Case | Example |
|--------|----------|---------|
| **JSON** | Human-readable, common | `{"id": "O001", "amount": 50}` |
| **AVRO** | Schema evolution, compact | Binary format |
| **PROTOBUF** | High performance | Binary format |
| **DELIMITED** | CSV-like | `O001,50.00,C123` |

**For this tutorial:** We'll use JSON (simplest)

---

## ksqlDB Query Types

### 1. Push Queries (Continuous)

```sql
SELECT * FROM orders EMIT CHANGES;
```

**Behavior:** Runs continuously, shows new events as they arrive

**Use case:** Monitoring, live dashboards

---

### 2. Pull Queries (Point-in-Time)

```sql
SELECT * FROM customer_totals WHERE customer_id = 'C123';
```

**Behavior:** Returns current value and terminates

**Use case:** Lookup current state

---

## Common ksqlDB Operations

### Filtering

```sql
SELECT * FROM vehicle_stream
WHERE speed_kmph > 80;
```

---

### Projection (Select Columns)

```sql
SELECT vehicle_id, speed_kmph FROM vehicle_stream;
```

---

### Transformation

```sql
SELECT 
  vehicle_id,
  speed_kmph,
  speed_kmph * 0.621371 AS speed_mph
FROM vehicle_stream;
```

---

### Aggregation

```sql
SELECT 
  vehicle_id,
  COUNT(*) AS event_count,
  AVG(speed_kmph) AS avg_speed
FROM vehicle_stream
WINDOW TUMBLING (SIZE 1 MINUTE)
GROUP BY vehicle_id
EMIT CHANGES;
```

---

## ksqlDB Commands

### Show Available Resources

```sql
-- List streams
SHOW STREAMS;

-- List tables
SHOW TABLES;

-- List topics
SHOW TOPICS;

-- Describe a stream
DESCRIBE vehicle_stream;
```

---

### Create Stream

```sql
CREATE STREAM stream_name (
  field1 TYPE,
  field2 TYPE
) WITH (
  KAFKA_TOPIC='topic_name',
  VALUE_FORMAT='JSON'
);
```

---

### Drop Stream

```sql
DROP STREAM stream_name DELETE TOPIC;
```

**DELETE TOPIC:** Also deletes the underlying Kafka topic

---

## Example: Vehicle Telemetry Processing

### Raw Data in Kafka

```json
{"vehicle_id": "V001", "speed_kmph": 95, "fuel_percent": 75}
{"vehicle_id": "V002", "speed_kmph": 60, "fuel_percent": 12}
{"vehicle_id": "V001", "speed_kmph": 85, "fuel_percent": 74}
```

---

### ksqlDB Processing

```sql
-- 1. Create base stream
CREATE STREAM vehicle_stream (
  vehicle_id VARCHAR,
  speed_kmph DOUBLE,
  fuel_percent DOUBLE
) WITH (
  KAFKA_TOPIC='vehicle.telemetry',
  VALUE_FORMAT='JSON'
);

-- 2. Filter speeding vehicles
CREATE STREAM speeding_stream AS
SELECT * FROM vehicle_stream
WHERE speed_kmph > 80;

-- 3. Filter low fuel
CREATE STREAM lowfuel_stream AS
SELECT * FROM vehicle_stream
WHERE fuel_percent < 15;
```

---

### Result

New Kafka topics created automatically:
- `SPEEDING_STREAM` → Speeding events only
- `LOWFUEL_STREAM` → Low fuel events only

Other applications can consume these topics!

---

## Benefits of ksqlDB

### 1. Simplicity

**Without ksqlDB:**
- Write Java/Scala code
- Compile, package JAR
- Deploy to cluster
- Monitor application

**With ksqlDB:**
- Write SQL query
- Execute immediately
- Done!

---

### 2. Interactive Development

```sql
-- Try a query
SELECT * FROM orders WHERE amount > 100 EMIT CHANGES;

-- See results immediately
-- Adjust and retry
```

**Rapid feedback loop**

---

### 3. Built on Kafka

- Inherits Kafka's scalability
- Fault-tolerant
- Distributed processing
- No separate cluster needed

---

### 4. Continuous Queries

Queries run **forever**, processing all future events:

```sql
CREATE STREAM alerts AS
SELECT * FROM sensors WHERE temperature > 100;
```

This runs 24/7, detecting alerts in real-time!

---

## Limitations

### What ksqlDB is NOT

❌ **Not a general-purpose database**
- Use PostgreSQL/MySQL for CRUD operations

❌ **Not for complex joins across long time periods**
- Use data warehouse for historical analysis

❌ **Not for machine learning**
- Use Spark MLlib, TensorFlow

✅ **Best for:** Real-time filtering, aggregations, transformations

---

## Key Takeaways

1. **ksqlDB** = SQL for Kafka streams

2. **Write SQL**, not code (Java/Scala)

3. **Interactive queries** - see results immediately

4. **Continuous processing** - queries run forever

5. **Creates new topics** automatically

6. **Built on Kafka** - inherits scalability

---

## What's Next?

Now let's dive deeper into streams and tables!

**→ Next: [Streams vs Tables](03-streams-vs-tables.md)**

---

## 🤔 Self-Check Questions

1. What is the main benefit of ksqlDB over writing Kafka Streams code?
2. What does `EMIT CHANGES` do?
3. What happens when you create a derived stream in ksqlDB?
4. Name two data formats supported by ksqlDB.

---
