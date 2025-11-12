# Capstone Project: Custom Alert Pipeline

## 🎯 Objective

Build a custom feature for the vehicle telemetry system to demonstrate your end-to-end Kafka skills!

**Challenge:** Detect "Idle Vehicles" and export the alerts to Azure Blob Storage.

**Definition of Idle Vehicle:**
- Speed < 5 km/h
- Status = "moving"
- Indicates: Vehicle stuck in traffic or parked illegally

---

## ⏱️ Time Limit

**15 minutes** (with guidance below)

---

## 📋 Requirements

Your solution must include:

1. **ksqlDB Stream** - Create a stream that detects idle vehicles
2. **Output Topic** - Stream should write to a new Kafka topic: `IDLE_VEHICLES`
3. **Kafka Connect** - Update connector to export idle vehicle data to Azure
4. **Monitoring** - Verify in Control Center that data is flowing
5. **Azure Verification** - Screenshot showing idle vehicle data in Azure Blob Storage

---

## 📝 Step-by-Step Guide

### Step 1: Create Idle Vehicle Detection Stream

**Access ksqlDB CLI:**
```bash
docker exec -it ksqldb-cli ksql http://ksqldb-server:8088
```

**Create the stream:**
```sql
CREATE STREAM idle_vehicles_stream AS
SELECT
  vehicle_id,
  speed_kmph,
  timestamp_utc,
  location,
  status,
  'IDLE_ALERT' AS alert_type
FROM vehicle_stream
WHERE speed_kmph < 5 AND status = 'moving'
EMIT CHANGES;
```

**Expected output:**
```
Message
-------------------
Stream created
```

**Test the stream:**
```sql
SELECT * FROM idle_vehicles_stream EMIT CHANGES LIMIT 5;
```

**Expected:** See idle vehicle records (may take a minute if no vehicles are currently idle).

Press `Ctrl+C` to stop the query.

Type `exit` to exit ksqlDB CLI.

---

### Step 2: Verify Topic Created

**Check Control Center:**
1. Go to http://localhost:9021
2. Click "Topics"
3. **You should see:** `IDLE_VEHICLES_STREAM` topic ✅

**Alternative (CLI):**
```bash
docker exec kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --list | grep IDLE
```

**Expected output:**
```
IDLE_VEHICLES_STREAM
```

---

### Step 3: Update Kafka Connect Configuration

**Edit the connector config:**
```bash
cd kafka-tutorials/module-4-kafka-connect/lab
nano config/azure-blob-sink.json
```

**Update the `topics` field** to include the new topic:
```json
{
  "name": "azure-blob-sink-connector",
  "config": {
    "connector.class": "io.confluent.connect.azure.blob.AzureBlobStorageSinkConnector",
    "tasks.max": "1",
    "topics": "SPEEDING_STREAM,LOWFUEL_STREAM,OVERHEATING_STREAM,IDLE_VEHICLES_STREAM",
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

**Save and exit** (Ctrl+X, Y, Enter).

---

### Step 4: Update the Connector

**Delete the old connector:**
```bash
curl -X DELETE http://localhost:8083/connectors/azure-blob-sink-connector
```

**Expected output:**
```
HTTP/1.1 204 No Content
```

**Deploy the updated connector:**
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

---

### Step 5: Verify in Control Center

**Topics:**
1. Go to Control Center → Topics
2. Click on `IDLE_VEHICLES_STREAM`
3. Click "Messages" tab
4. **You should see idle vehicle alerts** ✅

**ksqlDB Queries:**
1. Go to Control Center → ksqlDB
2. Click on your ksqlDB cluster
3. Click "Queries" tab
4. **You should see:** `CTAS_IDLE_VEHICLES_STREAM_*` with status "RUNNING" ✅

**Kafka Connect:**
1. Go to Control Center → Connect
2. Click on `connect-default`
3. Click on `azure-blob-sink-connector`
4. Click "Settings" tab
5. **Verify:** Topics list includes `IDLE_VEHICLES_STREAM` ✅

---

### Step 6: Verify Data in Azure

**Wait 1-2 minutes** for data to be exported to Azure.

**Check Azure Portal:**
1. Go to Azure Portal
2. Navigate to your storage account
3. Go to Containers → `vehicle-telemetry-data`
4. Browse folders:
   ```
   topics/
     IDLE_VEHICLES_STREAM/
       year=2024/
         month=11/
           day=12/
             hour=10/
               IDLE_VEHICLES_STREAM+0+0000000000.json
   ```
5. Download the JSON file
6. **Verify:** File contains idle vehicle alert data ✅

**Example data in JSON file:**
```json
{
  "VEHICLE_ID": "V003",
  "SPEED_KMPH": 3.2,
  "TIMESTAMP_UTC": "2024-11-12T10:45:32Z",
  "LOCATION": {
    "LAT": 28.6139,
    "LON": 77.2090
  },
  "STATUS": "moving",
  "ALERT_TYPE": "IDLE_ALERT"
}
```

---

### Step 7: Take Screenshots

**For your submission/portfolio, take screenshots of:**

1. **Control Center - Topics:** Showing `IDLE_VEHICLES_STREAM` with message count
2. **Control Center - ksqlDB Queries:** Showing idle_vehicles_stream query RUNNING
3. **Control Center - Kafka Connect:** Showing connector with updated topics
4. **Azure Portal:** Showing the IDLE_VEHICLES_STREAM folder with JSON files

---

## 🎉 Success Criteria

Your capstone is complete if:

- ✅ ksqlDB stream created and running
- ✅ `IDLE_VEHICLES_STREAM` topic exists and has messages
- ✅ Kafka Connect updated to include new topic
- ✅ Connector status = RUNNING
- ✅ Data verified in Azure Blob Storage
- ✅ Screenshots taken for all stages

---

## 💡 Bonus Challenges (Optional)

If you finish early, try these extensions:

### Bonus 1: Add Timestamp to Alerts

**Modify the stream to add a human-readable timestamp:**
```sql
DROP STREAM IF EXISTS idle_vehicles_stream DELETE TOPIC;

CREATE STREAM idle_vehicles_stream AS
SELECT
  vehicle_id,
  speed_kmph,
  timestamp_utc,
  location,
  status,
  'IDLE_ALERT' AS alert_type,
  TIMESTAMPTOSTRING(ROWTIME, 'yyyy-MM-dd HH:mm:ss') AS detected_at
FROM vehicle_stream
WHERE speed_kmph < 5 AND status = 'moving'
EMIT CHANGES;
```

---

### Bonus 2: Create Idle Duration Table

**Track how long vehicles have been idle:**
```sql
CREATE TABLE idle_duration AS
SELECT
  vehicle_id,
  COUNT(*) AS idle_event_count,
  MIN(timestamp_utc) AS first_idle_time,
  MAX(timestamp_utc) AS last_idle_time,
  WINDOWSTART AS window_start,
  WINDOWEND AS window_end
FROM idle_vehicles_stream
WINDOW TUMBLING (SIZE 5 MINUTES)
GROUP BY vehicle_id
EMIT CHANGES;
```

**Query the table:**
```sql
SELECT * FROM idle_duration EMIT CHANGES;
```

---

### Bonus 3: Multi-Condition Alert

**Detect vehicles that are both idle AND low on fuel:**
```sql
CREATE STREAM critical_idle_stream AS
SELECT
  i.vehicle_id,
  i.speed_kmph,
  f.fuel_percent,
  i.timestamp_utc,
  i.location,
  'CRITICAL_IDLE_LOW_FUEL' AS alert_type
FROM idle_vehicles_stream i
  INNER JOIN lowfuel_stream f
  WITHIN 1 MINUTE
  ON i.vehicle_id = f.vehicle_id
EMIT CHANGES;
```

**This is advanced ksqlDB!** Stream joins require careful configuration.

---

### Bonus 4: Add Email Notifications

**Use a consumer to send email alerts:**
```python
# idle_alert_consumer.py
from kafka import KafkaConsumer
import json
import smtplib

consumer = KafkaConsumer(
    'IDLE_VEHICLES_STREAM',
    bootstrap_servers='localhost:9092',
    value_deserializer=lambda v: json.loads(v.decode('utf-8'))
)

for message in consumer:
    alert = message.value
    vehicle_id = alert['VEHICLE_ID']

    # Send email (simplified)
    send_email(
        to='fleet-manager@example.com',
        subject=f'Idle Vehicle Alert: {vehicle_id}',
        body=f'Vehicle {vehicle_id} is idle at {alert["TIMESTAMP_UTC"]}'
    )

    print(f'Email sent for {vehicle_id}')
```

---

### Bonus 5: Create Dashboard

**Use Grafana to visualize idle vehicle stats:**
1. Set up Prometheus + Grafana
2. Export Kafka metrics
3. Create dashboard showing:
   - Idle vehicles per hour
   - Average idle duration
   - Idle hotspots (location clustering)

---

## 🔍 Self-Evaluation Rubric

Rate yourself on each criterion:

| Criterion | Points | Self-Rating |
|-----------|--------|-------------|
| ksqlDB stream created correctly | 20 | ___/20 |
| Topic exists with messages | 20 | ___/20 |
| Connector updated and running | 20 | ___/20 |
| Data verified in Azure | 20 | ___/20 |
| Screenshots documented | 10 | ___/10 |
| Code is clean and commented | 10 | ___/10 |
| **TOTAL** | **100** | ___/100 |

**Bonus points:**
- Bonus challenge completed: +10 points each (up to +50)

**Grading scale:**
- 90-100: Excellent! You've mastered Kafka! 🌟
- 80-89: Great work! Minor improvements needed.
- 70-79: Good effort! Review some concepts.
- < 70: Keep learning! Practice more.

---

## 🎓 What You've Demonstrated

By completing this capstone, you've proven you can:

✅ **Analyze requirements** - Understood the idle vehicle detection requirement
✅ **Design stream processing** - Created appropriate ksqlDB query with filtering
✅ **Deploy to production** - Updated Kafka Connect configuration
✅ **End-to-end integration** - Connected producer → Kafka → ksqlDB → Connect → Azure
✅ **Monitoring & verification** - Used Control Center to verify each stage
✅ **Troubleshooting** - Debugged any issues that arose
✅ **Documentation** - Captured screenshots and documented your work

**These are real-world data engineering skills!** 🚀

---

## 📚 Reflection Questions

Answer these questions to solidify your learning:

1. **What was the most challenging part of this capstone?**
   - [Your answer]

2. **If you were to deploy this to production, what would you change?**
   - [Your answer]

3. **How would you handle 100x more vehicles (1,000 vehicles)?**
   - [Your answer]

4. **What other alerts would be useful for a fleet management system?**
   - [Your answer]

5. **What did you learn from this entire curriculum?**
   - [Your answer]

---

## 🎯 Next Steps After Capstone

### Build Your Portfolio

**Create a GitHub repository with:**
- Complete code (producer, consumers, ksqlDB queries)
- Architecture diagram
- Screenshots of Control Center and Azure
- README.md explaining your project

**Example README structure:**
```markdown
# Real-Time Vehicle Telemetry Pipeline

## Architecture
[Insert diagram]

## Features
- Real-time speeding detection
- Low fuel alerts
- Overheating monitoring
- Idle vehicle detection

## Technologies
- Apache Kafka
- ksqlDB
- Kafka Connect
- Azure Blob Storage
- Python

## How to Run
[Step-by-step instructions]

## Screenshots
[Insert screenshots]
```

---

### Share Your Work

- Post on LinkedIn with hashtags: #ApacheKafka #DataEngineering #RealTime
- Share on Twitter/X: Tag @confluentinc
- Write a blog post about your learning journey
- Present to your team or at a meetup

---

### Keep Learning

**Next topics to explore:**
1. **Kafka Streams** - Java/Scala API for stream processing
2. **Schema Registry** - Manage Avro schemas
3. **Multi-datacenter replication** - Cross-region Kafka
4. **Kafka security** - SSL, SASL, ACLs
5. **Production monitoring** - Prometheus + Grafana

**Recommended resources:**
- Confluent Kafka tutorials: https://kafka-tutorials.confluent.io/
- Kafka: The Definitive Guide (book)
- Confluent Developer courses: https://developer.confluent.io/
- Kafka Summit talks: https://kafka-summit.org/

---

### Get Certified

**Confluent Certifications:**
1. **Confluent Certified Developer for Apache Kafka (CCDAK)**
   - Focus: Application development with Kafka
   - You're ready for this! ✅

2. **Confluent Certified Administrator for Apache Kafka (CCAAK)**
   - Focus: Cluster management and operations
   - Requires more hands-on operational experience

**Preparation:**
- Review this curriculum
- Take practice exams
- Read official Confluent docs
- Build more projects

---

## 🏆 Congratulations!

**You've completed the entire Kafka curriculum!** 🎉

You started knowing nothing about Kafka, and now you've built a complete, production-like real-time data pipeline from scratch.

**You've earned the right to call yourself a Kafka engineer!**

This is just the beginning. Kafka is used by thousands of companies, and the skills you've learned are in high demand.

**Go build amazing things with Kafka!** 🚀

---

**Questions? Feedback? Share your capstone project:**
- GitHub: [Link to your project]
- LinkedIn: [Your profile]
- Email: [Your email]

---

**Final words:** Thank you for taking this journey. May your streams be fast, your lag be zero, and your clusters be highly available! ⚡

**Happy streaming!** 🎊
