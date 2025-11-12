# Lab: Deploy Complete End-to-End Pipeline

## ⏱️ Duration: 45 minutes

---

## Overview

In this final lab, you'll deploy the **complete vehicle telemetry pipeline** from scratch, integrating everything you've learned:

1. Deploy full Kafka stack with Docker Compose
2. Start vehicle simulator (producer)
3. Create ksqlDB streams for real-time processing
4. Deploy Kafka Connect to export to Azure
5. Monitor the entire pipeline
6. Scale the system
7. Complete the capstone project

**This is your capstone!** By the end, you'll have a production-like data pipeline running on your machine.

---

## Prerequisites

✅ Completed Modules 1-5
✅ Docker Desktop running
✅ At least 8 GB RAM allocated to Docker
✅ Azure storage account (from Module 4) or willingness to create one

---

## Part 1: Deploy the Complete Stack (15 minutes)

### Step 1: Use Module 4's Docker Compose

The complete stack is already in Module 4. Let's use it:

```bash
cd kafka-tutorials/module-4-kafka-connect/lab
```

### Step 2: Start All Services

```bash
docker-compose up -d
```

**Expected output:**
```
Creating network "lab_default" with the default driver
Creating zookeeper ... done
Creating kafka ... done
Creating schema-registry ... done
Creating kafka-connect ... done
Creating ksqldb-server ... done
Creating ksqldb-cli ... done
Creating control-center ... done
Creating rest-proxy ... done
```

### Step 3: Verify All Services Running

```bash
docker ps
```

**Expected:** 8 containers running:
- zookeeper
- kafka
- schema-registry
- kafka-connect
- ksqldb-server
- ksqldb-cli
- control-center
- rest-proxy

### Step 4: Wait for Services to be Ready

**Important:** Services need ~2 minutes to fully start. Check logs:

```bash
# Check Kafka
docker logs kafka | tail -20

# Look for: "INFO [KafkaServer id=1] started"

# Check ksqlDB
docker logs ksqldb-server | tail -20

# Look for: "INFO Server up and running"

# Check Connect
docker logs kafka-connect | tail -20

# Look for: "INFO Kafka Connect started"

# Check Control Center
docker logs control-center | tail -20

# Look for: "INFO Started HTTP connector"
```

### Step 5: Access Control Center

Open browser:
```
http://localhost:9021
```

**What you should see:**
- Cluster overview with 1 broker
- 0 messages/sec (no data yet)
- Healthy status ✅

---

## Part 2: Start the Producer (5 minutes)

### Step 1: Locate Your Vehicle Simulator

From Module 2:
```bash
cd kafka-tutorials/module-2-producers-consumers/lab
```

### Step 2: Create the Topic

```bash
docker exec kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --create --topic vehicle.telemetry \
  --partitions 3 \
  --replication-factor 1
```

**Expected output:**
```
Created topic vehicle.telemetry.
```

### Step 3: Start the Simulator

```bash
python vehicle_simulator.py
```

**Expected output:**
```
Vehicle simulator started...
Sending data for 10 vehicles every 2 seconds...

2024-11-12 10:30:45 - Sent: V001 speed=65.2 km/h fuel=75.5% temp=85.3°C
2024-11-12 10:30:45 - Sent: V002 speed=82.1 km/h fuel=45.8% temp=90.2°C
2024-11-12 10:30:45 - Sent: V003 speed=55.7 km/h fuel=88.3% temp=82.5°C
...
```

**Keep this terminal running!**

### Step 4: Verify Data in Control Center

1. Go to Control Center → Topics
2. Click on `vehicle.telemetry`
3. Click "Messages" tab
4. Click "Jump to offset: 0"
5. **You should see messages!** ✅

---

## Part 3: Deploy ksqlDB Streams (10 minutes)

### Step 1: Access ksqlDB CLI

```bash
docker exec -it ksqldb-cli ksql http://ksqldb-server:8088
```

### Step 2: Create Base Vehicle Stream

Copy queries from Module 3:

```sql
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
  VALUE_FORMAT='JSON'
);
```

**Expected output:**
```
Message
-------------------
Stream created
```

### Step 3: Test the Stream

```sql
SELECT * FROM vehicle_stream EMIT CHANGES LIMIT 5;
```

**Expected:** See 5 vehicle records displayed.

Press `Ctrl+C` to stop the query.

### Step 4: Create Speeding Detection Stream

```sql
CREATE STREAM speeding_stream AS
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

### Step 5: Create Low Fuel Detection Stream

```sql
CREATE STREAM lowfuel_stream AS
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

### Step 6: Create Overheating Detection Stream

```sql
CREATE STREAM overheating_stream AS
SELECT
  vehicle_id,
  engine_temp_c,
  timestamp_utc,
  location,
  'OVERHEATING_ALERT' AS alert_type
FROM vehicle_stream
WHERE engine_temp_c > 100
EMIT CHANGES;
```

### Step 7: Create Combined Alerts Stream

```sql
CREATE STREAM vehicle_alerts AS
SELECT
  vehicle_id,
  'SPEEDING' AS alert_type,
  speed_kmph AS alert_value,
  timestamp_utc
FROM speeding_stream;
```

### Step 8: Create 1-Minute Stats Table

```sql
CREATE TABLE vehicle_stats_1min AS
SELECT
  vehicle_id,
  COUNT(*) AS event_count,
  AVG(speed_kmph) AS avg_speed,
  AVG(fuel_percent) AS avg_fuel,
  AVG(engine_temp_c) AS avg_temp,
  WINDOWSTART AS window_start,
  WINDOWEND AS window_end
FROM vehicle_stream
WINDOW TUMBLING (SIZE 1 MINUTE)
GROUP BY vehicle_id
EMIT CHANGES;
```

### Step 9: Verify All Streams Created

```sql
SHOW STREAMS;
```

**Expected output:**
```
Stream Name              | Kafka Topic
-----------------------------------------
VEHICLE_STREAM           | vehicle.telemetry
SPEEDING_STREAM          | SPEEDING_STREAM
LOWFUEL_STREAM           | LOWFUEL_STREAM
OVERHEATING_STREAM       | OVERHEATING_STREAM
VEHICLE_ALERTS           | VEHICLE_ALERTS
```

```sql
SHOW TABLES;
```

**Expected output:**
```
Table Name              | Kafka Topic
-----------------------------------------
VEHICLE_STATS_1MIN      | VEHICLE_STATS_1MIN
```

Type `exit` to exit ksqlDB CLI.

### Step 10: Verify in Control Center

1. Go to Control Center → Topics
2. **You should now see new topics:**
   - `SPEEDING_STREAM`
   - `LOWFUEL_STREAM`
   - `OVERHEATING_STREAM`
   - `VEHICLE_ALERTS`
   - `VEHICLE_STATS_1MIN`

3. Click on `SPEEDING_STREAM` → Messages
4. **You should see speeding alerts!** (if any vehicles are speeding)

---

## Part 4: Deploy Kafka Connect to Azure (5 minutes)

### Step 1: Configure Azure Credentials

```bash
cd kafka-tutorials/module-4-kafka-connect/lab

# Copy the example file
cp config/azure-credentials.env.example config/azure-credentials.env

# Edit with your Azure credentials
nano config/azure-credentials.env
```

**Enter your actual credentials:**
```bash
AZURE_STORAGE_ACCOUNT_NAME=your-storage-account-name
AZURE_STORAGE_ACCOUNT_KEY=your-storage-account-key
```

Save and exit (Ctrl+X, Y, Enter).

### Step 2: Update Connector Configuration

Edit the connector config:
```bash
nano config/azure-blob-sink.json
```

**Update topics to include ksqlDB output topics:**
```json
{
  "name": "azure-blob-sink-connector",
  "config": {
    "connector.class": "io.confluent.connect.azure.blob.AzureBlobStorageSinkConnector",
    "tasks.max": "1",
    "topics": "SPEEDING_STREAM,LOWFUEL_STREAM,OVERHEATING_STREAM",
    "azblob.account.name": "YOUR_AZURE_STORAGE_ACCOUNT_NAME",
    "azblob.account.key": "YOUR_AZURE_STORAGE_ACCOUNT_KEY",
    "azblob.container.name": "vehicle-telemetry-data",
    "format.class": "io.confluent.connect.azure.blob.format.json.JsonFormat",
    "partitioner.class": "io.confluent.connect.storage.partitioner.TimeBasedPartitioner",
    "path.format": "'year'=YYYY/'month'=MM/'day'=dd/'hour'=HH",
    "partition.duration.ms": "3600000",
    "rotate.interval.ms": "60000",
    "flush.size": "100"
  }
}
```

**Update the placeholder values** with your actual Azure account name and key.

### Step 3: Deploy the Connector

```bash
./scripts/deploy_connector.sh
```

**Expected output:**
```
Deploying Azure Blob Storage Sink Connector...
Connector deployed successfully!

Connector Status:
{
  "name": "azure-blob-sink-connector",
  "connector": {
    "state": "RUNNING",
    "worker_id": "kafka-connect:8083"
  },
  "tasks": [
    {
      "id": 0,
      "state": "RUNNING",
      "worker_id": "kafka-connect:8083"
    }
  ]
}
```

### Step 4: Verify in Control Center

1. Go to Control Center → Connect
2. Click on `connect-default`
3. **You should see:** `azure-blob-sink-connector` with status "Running" ✅

---

## Part 5: Monitor the Complete Pipeline (5 minutes)

### Step 1: Check Pipeline Health in Control Center

**Topics:**
1. Go to Topics
2. Check message rates:
   - `vehicle.telemetry`: ~5 msg/sec ✅
   - `SPEEDING_STREAM`: ~0.5 msg/sec ✅
   - `LOWFUEL_STREAM`: ~0.3 msg/sec ✅

**Consumers:**
1. Go to Consumers
2. Find ksqlDB consumer groups
3. Check lag: Should be 0 or near-zero ✅

**ksqlDB:**
1. Go to ksqlDB
2. Click on your ksqlDB cluster
3. Go to "Queries" tab
4. **All queries should be "RUNNING"** ✅

**Connect:**
1. Go to Connect
2. Connector status: "RUNNING" ✅
3. Tasks: 1/1 running ✅

### Step 2: Verify Data in Azure

1. Go to Azure Portal
2. Navigate to your storage account
3. Go to Containers → `vehicle-telemetry-data`
4. Browse folders:
   ```
   topics/
     SPEEDING_STREAM/
       year=2024/
         month=11/
           day=12/
             hour=10/
               SPEEDING_STREAM+0+0000000000.json
   ```
5. Download and open a JSON file
6. **You should see vehicle alert data!** ✅

---

## Part 6: Scale the System (5 minutes)

### Exercise: Handle 3x Load

**Scenario:** Your vehicle fleet is growing! You now have 30 vehicles (3x current).

### Step 1: Increase Partitions

```bash
docker exec kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --alter --topic vehicle.telemetry \
  --partitions 6
```

**Result:** Now 6 partitions instead of 3.

### Step 2: Verify in Control Center

1. Go to Topics → vehicle.telemetry
2. Click "Partitions" tab
3. **You should see 6 partitions** ✅

### Step 3: Scale the Producer

Open 2 more terminals and run:

```bash
# Terminal 2
cd kafka-tutorials/module-2-producers-consumers/lab
python vehicle_simulator.py

# Terminal 3
python vehicle_simulator.py
```

**Now you have 3 producers sending data for 30 vehicles total!**

### Step 4: Monitor Increased Load

1. Go to Control Center → Topics → vehicle.telemetry
2. **Message rate should increase to ~15 msg/sec** (3x previous) ✅

### Step 5: Check Consumer Lag

1. Go to Consumers
2. Find ksqlDB consumer group
3. **Lag should still be 0 or near-zero** ✅

**If lag is growing:**
- ksqlDB can't keep up
- Solution: Add more ksqlDB servers (not covered in this tutorial)

### Step 6: Scale Down

Stop the extra producers (Ctrl+C in terminals 2 and 3).

**Result:** Message rate drops back to ~5 msg/sec.

---

## Part 7: Test Failure Scenarios (5 minutes)

### Test 1: Producer Failure

1. **Stop the producer** (Ctrl+C)
2. Go to Control Center → Topics → vehicle.telemetry
3. **Observe:** Message rate drops to 0
4. **Restart producer:** `python vehicle_simulator.py`
5. **Observe:** Message rate recovers ✅

**Lesson:** Producer failures are easy to detect in Control Center.

---

### Test 2: Connector Failure Simulation

1. Pause the connector:
   ```bash
   curl -X PUT http://localhost:8083/connectors/azure-blob-sink-connector/pause
   ```

2. Go to Control Center → Connect
3. **Observe:** Connector status = "PAUSED"

4. Resume the connector:
   ```bash
   curl -X PUT http://localhost:8083/connectors/azure-blob-sink-connector/resume
   ```

5. **Observe:** Connector status = "RUNNING" ✅

**Lesson:** Connectors can be paused/resumed without data loss (Kafka retains data).

---

## Part 8: Complete Pipeline Verification (5 minutes)

### End-to-End Data Flow Test

**Step 1:** Note the current time.

**Step 2:** Check producer logs - note a specific vehicle event:
```
2024-11-12 10:45:32 - Sent: V007 speed=92.5 km/h fuel=45.2% temp=88.3°C
```

**Step 3:** Wait 1-2 minutes for data to flow through pipeline.

**Step 4:** Verify each stage:

**Stage 1: Kafka Topic**
```bash
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic vehicle.telemetry \
  --from-beginning \
  --max-messages 5 | grep V007
```

**Expected:** See V007 message ✅

**Stage 2: ksqlDB Filtering**
```bash
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic SPEEDING_STREAM \
  --from-beginning \
  --max-messages 10 | grep V007
```

**Expected:** See V007 speeding alert (since speed > 80) ✅

**Stage 3: Azure Blob Storage**
- Go to Azure Portal → Storage account → Containers → vehicle-telemetry-data
- Navigate to: topics/SPEEDING_STREAM/year=2024/month=11/day=12/hour=10/
- Download latest JSON file
- Search for V007
- **Expected:** See V007 speeding alert in JSON ✅

**Success!** Data flowed through all stages:
```
Producer → Kafka → ksqlDB → Output Topic → Kafka Connect → Azure ✅
```

---

## Part 9: Performance Benchmarking (Optional)

### Measure End-to-End Latency

**Question:** How long does it take for a message to go from producer to Azure?

**Method:**
1. Producer sends message with timestamp
2. Download file from Azure
3. Calculate time difference

**Expected latency:**
- Producer → Kafka: < 10 ms
- Kafka → ksqlDB: < 100 ms
- ksqlDB → Output topic: < 100 ms
- Output topic → Connector: < 1 sec (batching delay)
- Connector → Azure: 1-60 sec (depending on flush settings)

**Total: 1-60 seconds** (mostly waiting for connector to batch and flush)

**To reduce latency:**
- Reduce `flush.size` in connector config
- Reduce `rotate.interval.ms` in connector config
- Trade-off: More frequent writes = more API calls = higher cost

---

## Cleanup

### Stop the Pipeline

```bash
# Stop producer (Ctrl+C in producer terminal)

# Stop Docker containers
cd kafka-tutorials/module-4-kafka-connect/lab
docker-compose down
```

**Expected output:**
```
Stopping control-center ... done
Stopping ksqldb-cli ... done
Stopping ksqldb-server ... done
Stopping kafka-connect ... done
Stopping schema-registry ... done
Stopping kafka ... done
Stopping zookeeper ... done
Removing containers...
```

### Start Again Later

```bash
docker-compose up -d
```

**Note:** All data persists (Docker volumes). Topics, messages, and connector configs remain.

### Full Cleanup (Delete All Data)

```bash
docker-compose down -v  # WARNING: Deletes all Kafka data!
```

---

## Success Criteria ✅

You've successfully completed the lab if:

- ✅ All 8 Docker containers running
- ✅ Producer sending data continuously
- ✅ Data visible in Control Center topics
- ✅ ksqlDB streams detecting speeding/low fuel/overheating
- ✅ Kafka Connect exporting to Azure Blob Storage
- ✅ Data verified in Azure Portal
- ✅ Consumer lag = 0 (all consumers keeping up)
- ✅ No errors in logs
- ✅ Successfully scaled partitions and producers
- ✅ Tested failure scenarios

---

## Troubleshooting

### Producer Can't Connect

```bash
# Check Kafka is running
docker ps | grep kafka

# Check Kafka logs
docker logs kafka

# Try:
docker restart kafka
```

### ksqlDB Queries Not Producing Output

```sql
-- Check if base stream has data
SELECT * FROM vehicle_stream EMIT CHANGES LIMIT 5;

-- If no data, check topic
```

```bash
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic vehicle.telemetry \
  --from-beginning \
  --max-messages 5
```

### Connector Failed

```bash
# Check status
curl http://localhost:8083/connectors/azure-blob-sink-connector/status | jq

# Check logs
docker logs kafka-connect

# Common issue: Wrong Azure credentials
# Fix: Update config/azure-credentials.env
```

### High Consumer Lag

- Check if consumer is running
- Check if consumer can keep up with production rate
- Solution: Add more consumers or optimize consumer code

---

## What You've Accomplished!

🎉 **Congratulations!** You've deployed a complete, production-like data pipeline:

✅ **Ingestion:** Real-time vehicle telemetry from 10 (or 30!) vehicles
✅ **Storage:** Kafka storing events with 3-6 partitions
✅ **Processing:** ksqlDB detecting speeding, low fuel, overheating in real-time
✅ **Integration:** Kafka Connect exporting to Azure Blob Storage
✅ **Monitoring:** Control Center providing full visibility
✅ **Scaling:** Increased partitions and producers to handle 3x load
✅ **Resilience:** Tested failure scenarios and recovery

**This is a real data pipeline!** The concepts and architecture apply directly to production systems at companies like Uber, Netflix, and LinkedIn.

---

## Next Step: Capstone Project

Ready for the final challenge? Complete the **[Capstone Project](../capstone/README.md)** to add your own custom feature to the pipeline!

---

**Excellent work!** You're now a Kafka engineer! 🚀
