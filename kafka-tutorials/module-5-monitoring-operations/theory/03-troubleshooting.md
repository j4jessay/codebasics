# Troubleshooting Common Issues

## 📖 Reading Time: 5 minutes

---

## Overview

Even well-designed Kafka systems encounter issues. The key is **quickly identifying and fixing** them. This guide covers the most common problems and their solutions.

---

## Problem 1: Consumer Lag Growing

### Symptoms
```
Consumer Group: vehicle-processor-group
Lag: Growing continuously
  10 min ago: 100 messages
  5 min ago: 500 messages
  Now: 1,200 messages
```

### Root Causes

**1. Consumer Too Slow**
- Processing logic takes too long
- Database writes blocking
- Network calls slowing down processing

**2. Not Enough Consumers**
- More partitions than consumers
- Single consumer can't keep up

**3. Producer Too Fast**
- Sudden spike in message rate
- Consumer designed for normal load, not spike

### How to Diagnose

**Step 1:** Check consumption rate vs production rate
```
Control Center → Topics → vehicle.telemetry
Production rate: 50 msg/sec

Control Center → Consumers → vehicle-processor-group
Consumption rate: 30 msg/sec

Problem: Consumer 20 msg/sec slower! ❌
```

**Step 2:** Check consumer count vs partition count
```
Control Center → Consumers → vehicle-processor-group → Members
Members: 1 consumer

Control Center → Topics → vehicle.telemetry → Partitions
Partitions: 3

Problem: 1 consumer handling 3 partitions, could parallelize! ⚠️
```

### Solutions

**Solution 1: Add More Consumer Instances**

If you have multiple partitions, run multiple consumers:

```bash
# Terminal 1
python consumer.py

# Terminal 2
python consumer.py  # Same consumer group

# Terminal 3
python consumer.py
```

**Result:** Load distributed across 3 consumers, lag decreases!

**Solution 2: Optimize Consumer Code**

```python
# BEFORE (Slow)
for message in consumer:
    data = process_message(message)
    save_to_database(data)  # Blocking call for each message!

# AFTER (Fast - Batching)
batch = []
for message in consumer:
    batch.append(message.value)
    if len(batch) >= 100:
        save_batch_to_database(batch)  # One batch insert
        batch = []
```

**Solution 3: Increase Partitions**

If topic has 1 partition but heavy load:

```bash
kafka-topics --bootstrap-server localhost:9092 \
  --alter --topic vehicle.telemetry \
  --partitions 5
```

Then add more consumers to match partition count.

**Solution 4: Reduce Processing**

Maybe you don't need to process every message:

```python
# Example: Only process every 10th message for sampling
count = 0
for message in consumer:
    count += 1
    if count % 10 == 0:
        process_message(message)
```

---

## Problem 2: Producer Can't Connect to Kafka

### Symptoms
```
Error: KafkaTimeoutError: Failed to update metadata after 60.0 secs
```

### Root Causes

**1. Kafka Not Running**
**2. Wrong Bootstrap Server Address**
**3. Network/Firewall Issue**
**4. Port Not Exposed**

### How to Diagnose

**Step 1:** Check if Kafka container is running

```bash
docker ps | grep kafka
```

**Expected output:**
```
CONTAINER ID   IMAGE                              STATUS
abc123         confluentinc/cp-kafka:7.5.0       Up 10 minutes
```

**Step 2:** Check Kafka logs

```bash
docker logs kafka
```

**Look for:**
```
✅ Good: [KafkaServer id=1] started
❌ Bad: java.net.BindException: Address already in use
```

**Step 3:** Check network connectivity

```bash
# From your machine
telnet localhost 9092

# If works, you'll see:
Trying 127.0.0.1...
Connected to localhost.
```

**Step 4:** Verify bootstrap server in code

```python
# Check your producer code
producer = KafkaProducer(
    bootstrap_servers='localhost:9092'  # ← Correct?
)
```

### Solutions

**Solution 1: Start Kafka**

```bash
cd kafka-tutorials/module-4-kafka-connect/lab
docker-compose up -d
```

**Solution 2: Fix Bootstrap Server**

```python
# If running on same machine as Docker
bootstrap_servers='localhost:9092'  ✅

# If running Docker on remote machine
bootstrap_servers='REMOTE_IP:9092'  ✅

# WRONG
bootstrap_servers='kafka:9092'  ❌ (only works inside Docker network)
```

**Solution 3: Check Port Mapping**

In `docker-compose.yml`:
```yaml
kafka:
  ports:
    - "9092:9092"  ✅ Port exposed
```

**Solution 4: Restart Docker Network**

```bash
docker-compose down
docker-compose up -d
```

---

## Problem 3: Messages Not Appearing in Topic

### Symptoms
```
Producer says "Message sent successfully"
But Control Center shows 0 messages in topic
```

### Root Causes

**1. Wrong Topic Name (Typo)**
**2. Producer Not Actually Sending**
**3. Messages Too Large**
**4. Serialization Error**

### How to Diagnose

**Step 1:** List all topics

```bash
docker exec kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --list
```

**Check:** Is your topic in the list?

**Step 2:** Consume from the topic

```bash
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic vehicle.telemetry \
  --from-beginning
```

**Expected:** See messages appearing

**Step 3:** Check producer logs

Add logging to producer:

```python
import logging
logging.basicConfig(level=logging.DEBUG)

producer = KafkaProducer(
    bootstrap_servers='localhost:9092',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

# Send message
future = producer.send('vehicle.telemetry', value=data)
record_metadata = future.get(timeout=10)  # Wait for ack

print(f"Message sent to {record_metadata.topic} partition {record_metadata.partition} offset {record_metadata.offset}")
```

### Solutions

**Solution 1: Create Topic Explicitly**

```bash
docker exec kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --create --topic vehicle.telemetry \
  --partitions 3 \
  --replication-factor 1
```

**Solution 2: Check Topic Name**

```python
# WRONG (typo)
producer.send('vehicle.telemtry', data)  ❌

# CORRECT
producer.send('vehicle.telemetry', data)  ✅
```

**Solution 3: Wait for Acknowledgment**

```python
# WRONG (fire and forget)
producer.send('vehicle.telemetry', data)
producer.close()  # Might close before message sent!

# CORRECT (wait for ack)
future = producer.send('vehicle.telemetry', data)
future.get(timeout=10)  # Wait
producer.flush()  # Ensure all sent
producer.close()
```

---

## Problem 4: ksqlDB Query Not Producing Output

### Symptoms
```
ksqlDB query status: RUNNING ✅
But output topic has 0 messages
```

### Root Causes

**1. Filter Too Restrictive (No Matches)**
**2. Input Topic Empty**
**3. Query Syntax Error**
**4. Serialization Mismatch**

### How to Diagnose

**Step 1:** Check input topic

```bash
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic vehicle.telemetry \
  --from-beginning \
  --max-messages 5
```

**Expected:** See input messages

**Step 2:** Query the stream directly

```sql
-- In ksqlDB CLI
SELECT * FROM vehicle_stream EMIT CHANGES LIMIT 5;
```

**Expected:** See rows

**Step 3:** Check filter logic

```sql
-- If filter is speed_kmph > 80
-- But all vehicles driving < 80
-- Then output will be empty!

-- Test with relaxed filter
SELECT * FROM vehicle_stream
WHERE speed_kmph > 10  -- Lower threshold
EMIT CHANGES LIMIT 5;
```

### Solutions

**Solution 1: Adjust Filter**

```sql
-- BEFORE (too strict)
CREATE STREAM speeding_stream AS
SELECT * FROM vehicle_stream
WHERE speed_kmph > 150;  -- No vehicles go this fast!

-- AFTER (realistic)
CREATE STREAM speeding_stream AS
SELECT * FROM vehicle_stream
WHERE speed_kmph > 80;
```

**Solution 2: Check Data Format**

```sql
-- If input is JSON, use VALUE_FORMAT='JSON'
CREATE STREAM vehicle_stream (...)
WITH (
  KAFKA_TOPIC='vehicle.telemetry',
  VALUE_FORMAT='JSON'  ✅
);
```

**Solution 3: Recreate Stream**

```sql
-- Drop and recreate
DROP STREAM IF EXISTS speeding_stream DELETE TOPIC;
CREATE STREAM speeding_stream AS ...
```

---

## Problem 5: Kafka Connect Connector Failed

### Symptoms
```
Control Center → Connect → Connector Status: FAILED ❌
```

### Root Causes

**1. Wrong Configuration**
**2. Authentication Error (Azure credentials)**
**3. Serialization Error**
**4. Network Issue**

### How to Diagnose

**Step 1:** Check connector logs

```bash
docker logs kafka-connect
```

**Look for error messages like:**
```
❌ ERROR Authentication failed
❌ ERROR Connection timeout
❌ ERROR Invalid configuration
```

**Step 2:** Check connector status via REST API

```bash
curl http://localhost:8083/connectors/azure-blob-sink-connector/status | jq
```

**Example output:**
```json
{
  "name": "azure-blob-sink-connector",
  "connector": {
    "state": "FAILED",
    "worker_id": "connect:8083"
  },
  "tasks": [
    {
      "id": 0,
      "state": "FAILED",
      "trace": "Authentication failed: Invalid account key"
    }
  ]
}
```

### Solutions

**Solution 1: Fix Azure Credentials**

```bash
# Check azure-credentials.env
cat config/azure-credentials.env

# Ensure correct:
AZURE_STORAGE_ACCOUNT_NAME=your-actual-account-name
AZURE_STORAGE_ACCOUNT_KEY=your-actual-account-key  # No quotes!
```

**Solution 2: Restart Connector**

```bash
# Pause
curl -X PUT http://localhost:8083/connectors/azure-blob-sink-connector/pause

# Resume
curl -X PUT http://localhost:8083/connectors/azure-blob-sink-connector/resume
```

**Solution 3: Delete and Recreate**

```bash
# Delete
curl -X DELETE http://localhost:8083/connectors/azure-blob-sink-connector

# Recreate
./scripts/deploy_connector.sh
```

---

## Problem 6: Docker Container Crashes

### Symptoms
```
docker ps  # Kafka container not listed
```

### Root Causes

**1. Port Already in Use**
**2. Out of Memory**
**3. Disk Full**
**4. Configuration Error**

### How to Diagnose

**Step 1:** Check container logs

```bash
docker logs kafka  # Even if container stopped
```

**Step 2:** Check system resources

```bash
# Disk space
df -h

# Memory
free -h

# Docker stats (for running containers)
docker stats
```

### Solutions

**Solution 1: Free Up Port**

```bash
# Find process using port 9092
lsof -i :9092

# Kill the process
kill -9 <PID>

# Restart Kafka
docker-compose up -d
```

**Solution 2: Increase Docker Memory**

Docker Desktop → Settings → Resources → Memory: 4 GB minimum

**Solution 3: Clean Up Docker**

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove unused volumes
docker volume prune
```

---

## Troubleshooting Flowchart

```
Problem?
  │
  ├─ Can't connect to Kafka?
  │   └─ Check: Docker running? Port exposed? Bootstrap server correct?
  │
  ├─ Messages not appearing?
  │   └─ Check: Topic exists? Producer sending? Serialization correct?
  │
  ├─ Consumer lag growing?
  │   └─ Check: Consumer count? Processing time? Production rate?
  │
  ├─ ksqlDB query no output?
  │   └─ Check: Input data? Filter logic? Stream defined correctly?
  │
  └─ Connector failed?
      └─ Check: Credentials? Configuration? Network? Logs?
```

---

## Useful Commands for Debugging

### List Topics
```bash
docker exec kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --list
```

### Describe Topic
```bash
docker exec kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --describe --topic vehicle.telemetry
```

### List Consumer Groups
```bash
docker exec kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --list
```

### Check Consumer Lag
```bash
docker exec kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --describe --group vehicle-processor-group
```

### View Messages
```bash
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic vehicle.telemetry \
  --from-beginning \
  --max-messages 10
```

### Check Kafka Logs
```bash
docker logs kafka -f  # Follow logs
```

### Check All Container Logs
```bash
docker-compose logs -f  # All services
docker-compose logs -f kafka  # Specific service
```

---

## Prevention is Better than Cure

### Best Practices

1. **Monitor Daily** - Spend 5 minutes checking Control Center
2. **Set Up Alerts** - Get notified before problems become critical
3. **Test Thoroughly** - Test edge cases (network failure, high load)
4. **Document Config** - Keep notes on what works
5. **Version Control** - Track changes to configs and code

---

## Key Takeaways

1. **Consumer lag is the most common issue** - Usually fixed by adding consumers or optimizing code

2. **Connection errors are usually config** - Check bootstrap server, ports, Docker

3. **Check logs first** - Most errors show clear messages in logs

4. **Test in isolation** - If producer works but consumer doesn't, test consumer standalone

5. **Control Center helps** - Visual UI makes diagnosis faster than CLI

---

## What's Next?

Now that you understand the theory, let's do hands-on troubleshooting in the lab!

**→ Next: [Lab Exercises](../lab/README.md)**

---

## 🤔 Self-Check Questions

Before moving to the lab, make sure you can answer:

1. If consumer lag is growing, what are three possible fixes?
2. How do you check if Kafka is running?
3. What command lists all topics?
4. If a ksqlDB query shows RUNNING but no output, what should you check?
5. Where do you check connector error messages?

---

**Excellent work!** You're ready for hands-on monitoring and troubleshooting in the lab.
