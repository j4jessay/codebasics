# Lab: Monitoring Kafka with Control Center

## ⏱️ Duration: 30 minutes

---

## Overview

In this lab, you'll use **Confluent Control Center** to monitor your entire Kafka pipeline:

1. Access Control Center UI
2. Monitor topics and message flow
3. Track consumer groups and lag
4. Monitor ksqlDB queries
5. Review Kafka Connect connectors
6. Troubleshoot a simulated issue

---

## Prerequisites

Before starting this lab:

✅ **Completed Module 4** (Kafka Connect)
✅ **Full Kafka stack running** (from Module 4)
✅ **Producer generating data** (vehicle simulator)
✅ **ksqlDB queries running** (speeding, low fuel streams)
✅ **Azure Blob connector deployed** (from Module 4)

---

## Step 0: Ensure Everything is Running

### Start the Full Stack

If not already running, start from Module 4:

```bash
cd kafka-tutorials/module-4-kafka-connect/lab
docker-compose up -d
```

**Wait 2 minutes** for all services to start.

### Verify All Services Running

```bash
docker ps
```

**Expected output:** 8 containers running:
```
- zookeeper
- kafka
- schema-registry
- kafka-connect
- ksqldb-server
- ksqldb-cli
- control-center
- rest-proxy
```

### Start the Producer

If not running:

```bash
# From Module 2 (or wherever you have your producer)
cd kafka-tutorials/module-2-producers-consumers/lab
python vehicle_simulator.py
```

**Expected output:**
```
Vehicle simulator started...
Sending data for 10 vehicles every 2 seconds...
Sent: V001 speed: 65.2 km/h
Sent: V002 speed: 82.1 km/h
...
```

### Verify ksqlDB Queries Running

```bash
docker exec -it ksqldb-cli ksql http://ksqldb-server:8088
```

```sql
SHOW STREAMS;
```

**Expected output:**
```
Stream Name              | Kafka Topic
-----------------------------------------
VEHICLE_STREAM           | vehicle.telemetry
SPEEDING_STREAM          | vehicle.speeding
LOWFUEL_STREAM           | vehicle.lowfuel
OVERHEATING_STREAM       | vehicle.overheating
```

Type `exit` to exit ksqlDB CLI.

---

## Exercise 1: Access Control Center (5 minutes)

### Step 1: Open Control Center

Open your browser and go to:
```
http://localhost:9021
```

**What you should see:**

- **Main dashboard** with cluster overview
- **Cluster name:** `kafka-cluster` or similar
- **Brokers:** 1 online
- **Topics:** 8+ topics
- **Consumers:** Multiple consumer groups
- **Throughput graph** showing messages per second

### Step 2: Explore the Interface

**Left sidebar navigation:**
- Home
- Cluster
- Topics
- Consumers
- ksqlDB
- Connect
- Settings

**Top of page:**
- Cluster dropdown (if you have multiple clusters)
- Time range selector
- Search bar

### Step 3: Note Initial Metrics

Take a screenshot or note:
- **Total messages/second:** ____
- **Number of topics:** ____
- **Number of consumer groups:** ____
- **Cluster health:** Should be "Healthy" ✅

---

## Exercise 2: Monitor Topics (5 minutes)

### Step 1: View All Topics

1. Click **"Topics"** in the left sidebar
2. You'll see a list of all topics

**Look for these topics:**
```
vehicle.telemetry
vehicle.speeding
vehicle.lowfuel
vehicle.overheating
vehicle.alerts.all
_confluent-* (internal topics, ignore)
```

### Step 2: Inspect `vehicle.telemetry` Topic

1. Click on **`vehicle.telemetry`** topic
2. You'll see:
   - **Overview tab:** Message rate, partition count, replication
   - **Messages tab:** Actual messages (you can browse!)
   - **Schema tab:** If using schema registry
   - **Configuration tab:** Topic settings

**Check these metrics:**

**Production Rate:**
- Look at the graph on the Overview tab
- Should see ~5 messages/second (10 vehicles, 1 msg per 2 sec)

**Message Count:**
- Scroll down to see total messages
- Should be growing continuously

**Partition Information:**
- Partitions: Should be 3 (or whatever you configured)
- Replication factor: 1

### Step 3: View Recent Messages

1. Click **"Messages"** tab
2. Select **"Jump to offset"** or **"Jump to timestamp"**
3. Click **"Fetch"**

**What you should see:**
```json
{
  "vehicle_id": "V001",
  "timestamp_utc": "2024-11-12T10:30:45Z",
  "location": {"lat": 28.6139, "lon": 77.2090},
  "speed_kmph": 65.2,
  "fuel_percent": 75.5,
  "engine_temp_c": 85.3,
  "status": "moving"
}
```

**Try this:**
- Browse through different offsets
- Note the partition number for each message
- See how messages are distributed across partitions

### Step 4: Check Output Topics

Repeat the above for:
- **`vehicle.speeding`** - Should have fewer messages (only when speed > 80)
- **`vehicle.lowfuel`** - Even fewer (only when fuel < 15%)

**Question:** Why do these topics have fewer messages than `vehicle.telemetry`?

**Answer:** Because ksqlDB filters the data! Only matching events are sent to output topics.

---

## Exercise 3: Monitor Consumer Groups (5 minutes)

### Step 1: View All Consumer Groups

1. Click **"Consumers"** in the left sidebar
2. You'll see all consumer groups

**Look for these groups:**
```
_confluent-ksql-default_query_*  (ksqlDB queries)
connect-azure-blob-sink-connector  (Kafka Connect)
```

### Step 2: Inspect a ksqlDB Consumer Group

1. Find a consumer group like:
   ```
   _confluent-ksql-default_query_CTAS_SPEEDING_STREAM_*
   ```
2. Click on it

**What you'll see:**

**Overview Tab:**
- **Status:** Should be "Stable" ✅
- **Members:** Number of consumers in the group
- **Lag:** **THIS IS THE MOST IMPORTANT METRIC!**

**Lag Table:**
```
Topic: vehicle.telemetry
Partition | Current Offset | Log End Offset | Lag
----------|----------------|----------------|-----
0         | 1,234          | 1,234          | 0 ✅
1         | 1,189          | 1,189          | 0 ✅
2         | 1,256          | 1,256          | 0 ✅
```

**What lag means:**
- **Lag = 0:** Consumer caught up ✅
- **Lag = small number (< 100):** Acceptable ✅
- **Lag = growing continuously:** Problem! ❌

### Step 3: Check Kafka Connect Consumer Group

1. Find consumer group:
   ```
   connect-azure-blob-sink-connector
   ```
2. Click on it
3. Check lag

**Expected:** Lag should be 0 or very small (< 10)

**If lag is growing:**
- Connector can't keep up
- Possible causes: Network slow, Azure API slow, too many messages

---

## Exercise 4: Monitor ksqlDB Queries (5 minutes)

### Step 1: View All Queries

1. Click **"ksqlDB"** in the left sidebar
2. Click on your ksqlDB cluster (likely named `ksqldb`)
3. You'll see:
   - **Streams tab:** List of streams
   - **Tables tab:** List of tables
   - **Queries tab:** Running queries
   - **Editor tab:** SQL editor

### Step 2: Check Running Queries

1. Click **"Queries"** tab
2. You'll see all running queries

**Example:**
```
Query ID                              | Status  | Type
---------------------------------------------------
CTAS_SPEEDING_STREAM_*               | RUNNING | PERSISTENT
CTAS_LOWFUEL_STREAM_*                | RUNNING | PERSISTENT
CTAS_OVERHEATING_STREAM_*            | RUNNING | PERSISTENT
```

### Step 3: Inspect a Query

1. Click on **`CTAS_SPEEDING_STREAM_*`**
2. You'll see:
   - **Query statement:** The SQL that created the stream
   - **Status:** Running ✅
   - **Uptime:** How long it's been running
   - **Messages processed:** Total count

**Example query statement:**
```sql
CREATE STREAM SPEEDING_STREAM AS
SELECT vehicle_id, speed_kmph, timestamp_utc, location
FROM VEHICLE_STREAM
WHERE speed_kmph > 80;
```

### Step 4: Test Ad-Hoc Query in Editor

1. Click **"Editor"** tab
2. Type this query:
   ```sql
   SELECT * FROM VEHICLE_STREAM EMIT CHANGES LIMIT 5;
   ```
3. Click **"Run query"**

**What you should see:**
- Real-time stream of vehicle data
- 5 rows displayed, then query stops

**Try another query:**
```sql
SELECT vehicle_id, AVG(speed_kmph) AS avg_speed
FROM VEHICLE_STREAM
WINDOW TUMBLING (SIZE 1 MINUTE)
GROUP BY vehicle_id
EMIT CHANGES;
```

**What this does:**
- Calculates average speed per vehicle per minute
- Updates in real-time as new data arrives

**Stop the query** when done (click "Stop" button).

---

## Exercise 5: Monitor Kafka Connect (5 minutes)

### Step 1: View All Connectors

1. Click **"Connect"** in the left sidebar
2. Select your connect cluster: `connect-default`
3. You'll see all connectors

**Look for:**
```
Connector Name                 | Status
----------------------------------------
azure-blob-sink-connector      | RUNNING ✅
```

### Step 2: Inspect the Azure Blob Connector

1. Click on **`azure-blob-sink-connector`**
2. You'll see:
   - **Overview tab:** Status, throughput, errors
   - **Settings tab:** Configuration
   - **Tasks tab:** Task status

**Check these metrics:**

**Status:**
- Should be **"Running"** ✅
- If "Failed" ❌, see troubleshooting section

**Tasks:**
- Should show **1 task running** (or however many you configured)
- Task ID: 0, Status: Running ✅

**Throughput:**
- Messages sent to Azure Blob Storage
- Should match the rate of input topics (vehicle.speeding, etc.)

**Errors:**
- Should be **0 errors** ✅
- If errors exist, click to see error messages

### Step 3: View Configuration

1. Click **"Settings"** tab
2. You'll see all configuration values:
   ```
   connector.class: io.confluent.connect.azure.blob.AzureBlobStorageSinkConnector
   topics: vehicle.speeding,vehicle.lowfuel,vehicle.overheating
   azblob.account.name: your-storage-account
   format.class: io.confluent.connect.azure.blob.format.json.JsonFormat
   partitioner.class: io.confluent.connect.storage.partitioner.TimeBasedPartitioner
   ...
   ```

**Note:** This is useful for debugging configuration issues.

---

## Exercise 6: Troubleshooting (5 minutes)

Let's simulate and fix a common problem!

### Simulate Problem: Stop the Producer

1. Stop your vehicle simulator (Ctrl+C in the terminal running it)
2. Wait 1 minute
3. Go back to Control Center

### Observe the Problem

**In Topics:**
1. Go to **Topics → vehicle.telemetry**
2. Look at the production graph
3. **What do you see?** Message rate drops to 0! ❌

**In Consumers:**
1. Go to **Consumers → ksqlDB consumer group**
2. **What happened to lag?** It stayed at 0 (because no new messages)

**In ksqlDB:**
1. Go to **ksqlDB → Queries**
2. **Query status?** Still "Running" ✅ (but not processing anything)

### Fix the Problem

1. Restart the producer:
   ```bash
   python vehicle_simulator.py
   ```

2. Go back to Control Center

3. Watch the metrics recover:
   - **Topics:** Message rate goes back to ~5 msg/sec ✅
   - **Consumers:** Lag stays at 0 ✅
   - **ksqlDB:** Queries start processing again ✅

**Lesson learned:** Control Center helps you quickly identify when data stops flowing!

---

## Exercise 7: Simulate Consumer Lag (Bonus)

Let's see what growing lag looks like.

### Simulate Lag

We can't easily slow down the consumer (ksqlDB handles it efficiently), but we can understand what lag would look like:

1. **Imagine scenario:** Producer suddenly sends 1000 messages/second
2. **Consumer can only process 100 messages/second**
3. **Result:** Lag grows by 900 messages/second!

### What Control Center Would Show

**Consumers → Consumer Group → Lag:**
```
Time     | Lag
---------|-------
10:00    | 0
10:01    | 54,000    (900 msg/sec × 60 sec)
10:02    | 108,000   (doubled!)
10:03    | 162,000   (tripled!)
```

**Red alert!** ❌ Lag continuously growing.

### How to Fix (Reminder)

1. Add more consumers (scale out)
2. Optimize consumer code
3. Increase partitions
4. Reduce processing per message

---

## Summary: What You Monitored

| Component | What You Checked | Expected Value |
|-----------|------------------|----------------|
| **Topics** | Message rate | ~5 msg/sec |
| **Topics** | Partition count | 3 |
| **Consumers** | Lag | 0 or near-zero |
| **Consumers** | Status | Stable |
| **ksqlDB** | Query status | Running |
| **ksqlDB** | Messages processed | Growing |
| **Connect** | Connector status | Running |
| **Connect** | Task status | 1/1 running |

---

## Cleanup (Optional)

If you want to stop everything:

```bash
cd kafka-tutorials/module-4-kafka-connect/lab
docker-compose down
```

To start again later:
```bash
docker-compose up -d
```

---

## Key Takeaways

1. **Control Center provides full visibility** - All components in one place

2. **Consumer lag is the #1 metric** - Growing lag = problem

3. **Visual graphs help** - Easier to spot trends than CLI output

4. **Quick diagnosis** - Identify issues in seconds, not minutes

5. **Message browser is useful** - See actual data flowing through topics

---

## Success Criteria ✅

You've successfully completed this lab if you can:

- ✅ Access Control Center UI
- ✅ Navigate to Topics, Consumers, ksqlDB, Connect sections
- ✅ View message rate for a topic
- ✅ Check consumer lag for a consumer group
- ✅ Verify ksqlDB query status
- ✅ Check Kafka Connect connector status
- ✅ Identify when producer stops sending data

---

## Next Steps

Congratulations! You now know how to monitor your Kafka pipeline.

**→ Complete the [Additional Exercises](../exercises.md)** to practice more troubleshooting scenarios.

**→ Proceed to [Module 6: End-to-End Pipeline](../../module-6-complete-pipeline/)** for the final capstone project!

---

## Need Help?

### Control Center Not Loading?

```bash
# Check if container is running
docker ps | grep control-center

# Check logs
docker logs control-center

# Restart
docker restart control-center

# Wait 1-2 minutes, then try http://localhost:9021 again
```

### Not Seeing Any Topics?

- Wait 2-3 minutes after starting docker-compose
- Ensure Kafka is running: `docker ps | grep kafka`
- Check broker connection in Control Center

### Consumer Lag Shows "N/A"?

- Consumer group might not be active
- Ensure consumers are running (producer, ksqlDB queries)
- Refresh the page

---

**Great job!** You've mastered Kafka monitoring with Control Center!
