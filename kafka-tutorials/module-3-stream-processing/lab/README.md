# Module 3 Lab: Stream Processing with ksqlDB

## ⏱️ Duration: 60 minutes

---

## 🎯 Lab Objectives

By the end of this lab, you will:

- ✅ Set up ksqlDB Server and CLI with Docker
- ✅ Create a base stream from a Kafka topic
- ✅ Write filtering queries to detect speeding and low fuel
- ✅ Create aggregation queries for real-time statistics
- ✅ Query streams continuously to see live data

---

## 🛠️ Setup (10 minutes)

### Step 1: Ensure Producer is Running

You need vehicle telemetry data flowing to Kafka.

**Check if producer is running:**
```bash
docker ps | grep producer
```

**If not running, start it from Module 2:**
```bash
cd ../../module-2-producers-consumers/lab
python producer-vehicle.py
```

Keep it running in a separate terminal!

---

### Step 2: Start ksqlDB Services

Navigate to Module 3 lab directory:
```bash
cd kafka-tutorials/module-3-stream-processing/lab
```

Start Kafka + ksqlDB:
```bash
docker compose up -d
```

**Expected output:**
```
✔ Container zookeeper      Started
✔ Container kafka          Started
✔ Container ksqldb-server  Started
✔ Container ksqldb-cli     Started
```

**⏱️ Wait Time:** 30-60 seconds for ksqlDB Server to initialize

---

### Step 3: Verify Services

```bash
docker ps
```

You should see 4 containers:
- zookeeper
- kafka
- ksqldb-server
- ksqldb-cli

---

### Step 4: Access ksqlDB CLI

```bash
docker exec -it ksqldb-cli ksql http://ksqldb-server:8088
```

**Expected output:**
```
                  ===========================================
                  =       _              _ ____  ____       =
                  =      | | _____  __ _| |  _ \| __ )      =
                  =      | |/ / __|/ _` | | | | |  _ \      =
                  =      |   <\__ \ (_| | | |_| | |_) |     =
                  =      |_|\_\___/\__, |_|____/|____/      =
                  =                   |_|                   =
                  =  Event Streaming Database purpose-built =
                  =        for stream processing apps       =
                  ===========================================

Server Status: RUNNING

ksql>
```

**✅ Success Checkpoint:** You're now in the ksqlDB CLI!

---

## 📝 Exercise 1: Create Base Stream (10 minutes)

### What You'll Do

Create a stream that reads from the `vehicle.telemetry` Kafka topic.

### Commands

**In ksqlDB CLI:**

```sql
SET 'auto.offset.reset' = 'earliest';

CREATE STREAM vehicle_stream (
  vehicle_id VARCHAR,
  timestamp_utc VARCHAR,
  location STRUCT<lat DOUBLE, lon DOUBLE>,
  speed_kmph DOUBLE,
  fuel_percent DOUBLE,
  engine_temp_c DOUBLE,
  status VARCHAR
) WITH (
  KAFKA_TOPIC='vehicle.telemetry',
  VALUE_FORMAT='JSON',
  PARTITIONS=1
);
```

**Expected output:**
```
 Message
----------------
 Stream created
----------------
```

---

### Verify Stream

```sql
-- Show all streams
SHOW STREAMS;

-- Describe the stream
DESCRIBE vehicle_stream;
```

---

### View Live Data

```sql
SELECT * FROM vehicle_stream EMIT CHANGES LIMIT 5;
```

**Expected output:**
```
+----------+--------------------+---------+------------+---------+
|VEHICLE_ID|TIMESTAMP_UTC       |SPEED_KM |FUEL_PERCENT|ENGINE_  |
|          |                    |PH       |            |TEMP_C   |
+----------+--------------------+---------+------------+---------+
|VEH-0001  |2024-11-10T10:00:00Z|65.34    |75.5        |88.2     |
|VEH-0002  |2024-11-10T10:00:01Z|55.12    |80.3        |85.1     |
...
```

**Press Ctrl+C to stop the query**

**✅ Success Checkpoint:** You see vehicle telemetry data flowing!

---

## 🚗 Exercise 2: Detect Speeding Vehicles (15 minutes)

### What You'll Do

Create a filtered stream that only shows vehicles exceeding 80 km/h.

### Commands

```sql
CREATE STREAM speeding_stream
WITH (
  KAFKA_TOPIC='vehicle.speeding',
  VALUE_FORMAT='JSON',
  PARTITIONS=1
) AS
SELECT
  vehicle_id,
  speed_kmph,
  timestamp_utc,
  location,
  'SPEEDING_ALERT' AS alert_type
FROM vehicle_stream
WHERE speed_kmph > 80
EMIT CHANGES;
```

**Expected output:**
```
 Message
--------------------------------------
 Created query with ID CSAS_SPEEDING_STREAM_0
 Stream created and running
--------------------------------------
```

---

### View Speeding Alerts

```sql
SELECT * FROM speeding_stream EMIT CHANGES LIMIT 5;
```

**Expected output (only when vehicles speed):**
```
+----------+----------+------------+
|VEHICLE_ID|SPEED_KMPH|ALERT_TYPE  |
+----------+----------+------------+
|VEH-0003  |95.67     |SPEEDING_ALERT|
|VEH-0005  |87.23     |SPEEDING_ALERT|
...
```

**⚡ Key Insight:** Only speeding events appear! ksqlDB filters in real-time.

---

### Check New Topic Created

**In a new terminal:**
```bash
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list
```

You should see:
- `vehicle.telemetry` (original)
- `vehicle.speeding` (new - created by ksqlDB!)

**✅ Success Checkpoint:** Speeding stream is filtering events!

---

## ⛽ Exercise 3: Detect Low Fuel (10 minutes)

### What You'll Do

Create another filtered stream for low fuel alerts (< 15%).

### Commands

**In ksqlDB CLI:**

```sql
CREATE STREAM lowfuel_stream
WITH (
  KAFKA_TOPIC='vehicle.lowfuel',
  VALUE_FORMAT='JSON',
  PARTITIONS=1
) AS
SELECT
  vehicle_id,
  fuel_percent,
  timestamp_utc,
  location,
  'LOW_FUEL_ALERT' AS alert_type
FROM vehicle_stream
WHERE fuel_percent < 15
EMIT CHANGES;
```

---

### View Low Fuel Alerts

```sql
SELECT * FROM lowfuel_stream EMIT CHANGES;
```

**Expected output (when fuel is low):**
```
+----------+------------+--------------+
|VEHICLE_ID|FUEL_PERCENT|ALERT_TYPE    |
+----------+------------+--------------+
|VEH-0007  |12.3        |LOW_FUEL_ALERT|
...
```

**✅ Success Checkpoint:** Low fuel alerts are working!

---

## 📊 Exercise 4: Aggregate Statistics (15 minutes)

### What You'll Do

Create a table with 1-minute aggregated statistics per vehicle.

### Commands

```sql
CREATE TABLE vehicle_stats_1min
WITH (
  KAFKA_TOPIC='vehicle.stats.1min',
  VALUE_FORMAT='JSON',
  PARTITIONS=1
) AS
SELECT
  vehicle_id,
  COUNT(*) AS event_count,
  AVG(speed_kmph) AS avg_speed,
  MAX(speed_kmph) AS max_speed,
  MIN(fuel_percent) AS min_fuel,
  AVG(engine_temp_c) AS avg_engine_temp
FROM vehicle_stream
WINDOW TUMBLING (SIZE 1 MINUTE)
GROUP BY vehicle_id
EMIT CHANGES;
```

---

### View Statistics

```sql
SELECT * FROM vehicle_stats_1min EMIT CHANGES;
```

**Expected output (updates every minute):**
```
+----------+-----------+---------+---------+
|VEHICLE_ID|EVENT_COUNT|AVG_SPEED|MAX_SPEED|
+----------+-----------+---------+---------+
|VEH-0001  |120        |65.5     |85.2     |
|VEH-0002  |120        |55.3     |70.1     |
...
```

**⚡ Key Insight:** Statistics update every minute automatically!

**✅ Success Checkpoint:** Aggregations are working!

---

## 🔍 Exercise 5: Query and Explore (10 minutes)

### List All Streams and Tables

```sql
SHOW STREAMS;
SHOW TABLES;
```

---

### Describe a Stream

```sql
DESCRIBE vehicle_stream;
DESCRIBE EXTENDED speeding_stream;
```

---

### View Topics

```sql
SHOW TOPICS;
```

---

### Drop a Stream (Cleanup)

```sql
-- Drop stream and its topic
DROP STREAM lowfuel_stream DELETE TOPIC;

-- Recreate it if needed
-- (run the CREATE STREAM command again)
```

---

## 🎓 Lab Summary

Congratulations! You've completed Module 3 Lab. You now know how to:

- ✅ Set up ksqlDB with Docker
- ✅ Create streams from Kafka topics
- ✅ Write filtering queries (WHERE clause)
- ✅ Create derived streams (speeding, low fuel)
- ✅ Perform aggregations with windowing
- ✅ Query streams in real-time

---

## 🧹 Cleanup (Optional)

**Exit ksqlDB CLI:**
```sql
exit;
```

**Stop containers:**
```bash
docker compose down
```

**To remove all data:**
```bash
docker compose down -v
```

---

## 🚀 Next Steps

Ready for more? Proceed to Module 4 to export this data to Azure Blob Storage!

**[→ Go to Module 4: Kafka Connect](../../module-4-kafka-connect/)**

---

## 🆘 Troubleshooting

### ksqlDB CLI Won't Connect

```bash
# Check if ksqlDB Server is running
docker logs ksqldb-server

# Restart if needed
docker restart ksqldb-server
sleep 30
docker exec -it ksqldb-cli ksql http://ksqldb-server:8088
```

### No Data in Streams

```bash
# Verify producer is running
docker ps | grep producer

# Check Kafka topics
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list

# Consume from topic directly
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic vehicle.telemetry \
  --from-beginning \
  --max-messages 5
```

### Query Errors

```sql
-- Show running queries
SHOW QUERIES;

-- Terminate a query
TERMINATE <query-id>;

-- Drop and recreate stream
DROP STREAM speeding_stream DELETE TOPIC;
-- Then recreate
```

---

**Great job!** You've mastered stream processing with ksqlDB!
