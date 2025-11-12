# Additional Monitoring Exercises

## Overview

These exercises provide additional practice for monitoring and troubleshooting your Kafka pipeline using Control Center.

---

## Exercise 1: Analyze Topic Configuration

**Objective:** Understand how topic configuration affects performance.

### Tasks

1. **Compare retention settings across topics:**
   - Go to Topics → vehicle.telemetry → Configuration
   - Find `retention.ms` setting
   - Compare with vehicle.speeding topic
   - **Question:** Why might you set different retention for different topics?

2. **Check partition distribution:**
   - Go to Topics → vehicle.telemetry → Partitions tab
   - Note which broker owns each partition
   - **Question:** In a multi-broker cluster, how would partitions be distributed?

3. **Calculate storage requirements:**
   - Find total messages in vehicle.telemetry
   - Find average message size (look at topic size / message count)
   - **Calculate:** If you receive 5 msg/sec, how much storage per day?

   **Formula:**
   ```
   Storage per day = (5 msg/sec) × (avg size) × (86400 sec/day)
   ```

### Expected Results

**Retention:**
- Default: 7 days (604800000 ms)
- Some topics might have shorter retention (e.g., 1 day for high-volume topics)

**Storage calculation example:**
```
5 msg/sec × 500 bytes × 86,400 sec = 216 MB/day
Over 7 days: 216 MB × 7 = 1.5 GB
```

---

## Exercise 2: Consumer Group Load Balancing

**Objective:** Understand how consumers distribute load.

### Tasks

1. **Check current consumer group distribution:**
   - Go to Consumers → Select a ksqlDB consumer group
   - Click "Members" tab
   - **Note:** How many members? Which partitions does each consume?

2. **Calculate theoretical throughput:**
   - If topic has 3 partitions
   - Each consumer can process 10 msg/sec
   - **Question:** What's max throughput with 1 consumer? With 3 consumers?

3. **Simulate scaling:**
   - **Current:** 1 consumer, 3 partitions, processing 5 msg/sec
   - **Question:** If producer increases to 30 msg/sec, how many consumers needed?

   **Formula:**
   ```
   Consumers needed = Producer rate / Consumer capacity
   Consumers needed = 30 msg/sec / 10 msg/sec per consumer = 3
   ```

### Expected Results

**Load balancing:**
- 1 consumer → Handles all 3 partitions
- 2 consumers → Each handles 1-2 partitions
- 3 consumers → Each handles 1 partition (optimal)
- 4 consumers → 1 consumer is idle (can't exceed partition count)

---

## Exercise 3: Identify Performance Bottlenecks

**Objective:** Learn to spot performance issues early.

### Tasks

1. **Monitor end-to-end latency:**
   - Note timestamp when producer sends a message
   - Check when message appears in vehicle.speeding topic (ksqlDB output)
   - Calculate time difference
   - **Question:** What's the end-to-end latency?

2. **Compare throughput at each stage:**
   - Input: vehicle.telemetry (5 msg/sec)
   - Processing: ksqlDB queries (~1 msg/sec to speeding)
   - Output: Azure Blob connector (check in Connect section)
   - **Question:** Are there any bottlenecks?

3. **Check broker resource usage:**
   - Use `docker stats kafka` command
   - Note CPU and memory usage
   - **Question:** Is the broker under heavy load?

### Expected Results

**End-to-end latency:**
- Healthy system: < 1 second
- Producer → Kafka: < 10 ms
- Kafka → ksqlDB: < 100 ms
- ksqlDB → Output topic: < 100 ms

**Throughput balance:**
- Input = 5 msg/sec
- Speeding output = ~0.5-1 msg/sec (10-20% of vehicles speeding)
- Connector = ~1 msg/sec (all filtered streams combined)

---

## Exercise 4: Analyze Message Distribution

**Objective:** Understand how messages are distributed across partitions.

### Tasks

1. **Check partition message counts:**
   - Go to Topics → vehicle.telemetry → Partitions
   - Note message count for each partition
   - **Question:** Are messages evenly distributed?

2. **Understand partitioning strategy:**
   - If using key-based partitioning (vehicle_id as key):
     - V001, V004, V007 → Partition 0
     - V002, V005, V008 → Partition 1
     - V003, V006, V009, V010 → Partition 2
   - **Question:** Why might partition 2 have more messages?

3. **Calculate partition skew:**
   - **Formula:**
     ```
     Skew = (Max partition messages - Min partition messages) / Avg messages × 100%
     ```
   - **Example:**
     - P0: 1000 messages
     - P1: 1000 messages
     - P2: 1200 messages
     - Avg: 1066
     - Skew: (1200-1000)/1066 × 100% = 18.7%
   - **Acceptable skew:** < 20%

### Expected Results

**Even distribution (no key):**
```
Partition 0: 33% of messages
Partition 1: 33% of messages
Partition 2: 34% of messages
```

**Key-based distribution (vehicle_id):**
```
Partition 0: 30% (vehicles 1, 4, 7)
Partition 1: 30% (vehicles 2, 5, 8)
Partition 2: 40% (vehicles 3, 6, 9, 10)
```

---

## Exercise 5: Monitor ksqlDB Query Performance

**Objective:** Analyze stream processing efficiency.

### Tasks

1. **Compare input vs output rates:**
   - Go to ksqlDB → Queries → SPEEDING_STREAM
   - Note messages processed
   - Go to Topics → vehicle.speeding
   - Note message count
   - **Question:** Do they match?

2. **Calculate filter selectivity:**
   - Total input messages: (from vehicle.telemetry)
   - Output messages: (from vehicle.speeding)
   - **Formula:**
     ```
     Selectivity = (Output messages / Input messages) × 100%
     ```
   - **Example:** 1000 input, 100 output = 10% selectivity

3. **Estimate query resource usage:**
   - Check ksqlDB container stats: `docker stats ksqldb-server`
   - Note CPU and memory usage
   - **Question:** Is ksqlDB under heavy load?

### Expected Results

**Filter selectivity:**
- Speeding (speed > 80): ~10-20% of messages
- Low fuel (fuel < 15%): ~5-10% of messages
- Overheating (temp > 100): ~5-10% of messages

**Resource usage:**
- CPU: < 50% for light load (5 msg/sec)
- Memory: ~500 MB - 1 GB

---

## Exercise 6: Connector Monitoring Deep Dive

**Objective:** Monitor data export to Azure Blob Storage.

### Tasks

1. **Track messages written to Azure:**
   - Go to Connect → azure-blob-sink-connector → Overview
   - Note "Messages sent" count
   - Wait 2 minutes, refresh
   - **Calculate:** Messages per minute

2. **Verify partitioning in Azure:**
   - Go to Azure Portal → Your storage account → Containers → vehicle-telemetry-data
   - Browse folders
   - **Check:** Do you see year/month/day/hour folders?
   - **Example path:** `year=2024/month=11/day=12/hour=10/`

3. **Calculate data written:**
   - Download a JSON file from Azure
   - Check file size
   - Multiply by number of files
   - **Question:** How much data per day?

### Expected Results

**Connector throughput:**
- Should match input rate (~1 msg/sec from all filtered topics)
- Messages sent should continuously increase

**Azure folder structure:**
```
vehicle-telemetry-data/
  topics/
    vehicle.speeding/
      year=2024/
        month=11/
          day=12/
            hour=10/
              vehicle.speeding+0+0000001234.json
```

**Data volume:**
- ~500 bytes per message
- ~1 msg/sec × 3600 sec/hour = 3600 messages/hour
- 3600 × 500 bytes = 1.8 MB/hour

---

## Exercise 7: Alerting Simulation

**Objective:** Understand when you'd want alerts.

### Tasks

1. **Define alert thresholds:**
   Based on your monitoring, define when you'd want alerts:

   **Consumer lag:**
   - Warning: Lag > 1000 for 5 minutes
   - Critical: Lag > 10,000 for 5 minutes

   **Broker disk:**
   - Warning: > 70% disk used
   - Critical: > 85% disk used

   **Connector status:**
   - Critical: Status = FAILED

   **Producer rate:**
   - Warning: Rate = 0 for 2 minutes (producer down)

2. **Simulate alert conditions:**
   - Stop producer (rate = 0)
   - **Question:** After how long should alert fire?
   - Restart producer
   - **Question:** When should alert clear?

3. **Calculate alert frequency:**
   - If producer fails once per week
   - And connector fails once per month
   - **Question:** How many alerts per month?

### Expected Results

**Alert philosophy:**
- Too sensitive → Alert fatigue (ignore alerts)
- Too lenient → Miss real problems
- **Goal:** Alert on actionable issues only

**Example thresholds:**
- Consumer lag: > 10,000 for 5 min (not just a spike)
- Broker disk: > 80% (time to add capacity)
- Connector: FAILED immediately (data not exporting)

---

## Exercise 8: Historical Trend Analysis

**Objective:** Use historical data to predict future needs.

### Tasks

1. **Record metrics over time:**
   Create a table:
   ```
   Time  | Messages in vehicle.telemetry | Disk usage | Consumer lag
   ------|-------------------------------|------------|-------------
   Day 1 | 100,000                      | 5%         | 0
   Day 2 | 200,000                      | 10%        | 0
   Day 3 | 300,000                      | 15%        | 0
   ```

2. **Calculate growth rate:**
   - **Formula:**
     ```
     Growth rate = (Day 3 messages - Day 1 messages) / Day 1 messages × 100%
     ```
   - **Example:** (300k - 100k) / 100k = 200% growth over 3 days

3. **Predict capacity needs:**
   - If current disk = 15% at 300k messages
   - Retention = 7 days
   - **Question:** When will disk reach 85% (capacity limit)?

   **Calculation:**
   ```
   85% / 15% = 5.67x current storage
   5.67x current messages = 1.7 million messages
   At 100k messages/day growth: 17 days until capacity limit
   ```

### Expected Results

**Capacity planning:**
- Monitor trends weekly
- Plan capacity 3-6 months ahead
- Consider: Message rate growth, retention policy, disk size

---

## Exercise 9: Multi-Topic Comparison

**Objective:** Compare metrics across topics.

### Tasks

1. **Create comparison table:**
   ```
   Topic                | Msg/sec | Partitions | Size (MB) | Retention
   ---------------------|---------|------------|-----------|----------
   vehicle.telemetry    | 5.0     | 3          | 100       | 7 days
   vehicle.speeding     | 0.5     | 1          | 10        | 7 days
   vehicle.lowfuel      | 0.3     | 1          | 6         | 7 days
   vehicle.overheating  | 0.2     | 1          | 4         | 7 days
   ```

2. **Analyze differences:**
   - **Question:** Why does vehicle.telemetry have more partitions?
   - **Answer:** Higher throughput, needs parallelism

3. **Optimize configuration:**
   - **Question:** Should output topics have same retention as input?
   - **Possible optimization:** Reduce retention on output topics to save disk

### Expected Results

**Topic design principles:**
- High-throughput topics → More partitions
- Low-throughput topics → 1 partition is fine
- Output/derived topics → Can have shorter retention
- Archive topics → Longer retention

---

## Exercise 10: Break-Fix Challenge

**Objective:** Practice troubleshooting skills.

### Scenario 1: Mystery Lag

**Symptoms:**
- Consumer lag growing on vehicle.telemetry
- All ksqlDB queries running
- No errors in logs

**Tasks:**
1. Check producer rate
2. Check consumer rate
3. Calculate the difference
4. Propose 3 solutions

### Scenario 2: Connector Failure

**Symptoms:**
- Connector status: FAILED
- Tasks: 0/1 running
- Error: "Authentication failed"

**Tasks:**
1. Check where error appears (Control Center → Connect → Connector → Tasks)
2. Identify the issue (Azure credentials wrong)
3. Fix: Update azure-credentials.env
4. Restart connector

### Scenario 3: Missing Output

**Symptoms:**
- ksqlDB query RUNNING
- Input topic has messages
- Output topic empty

**Tasks:**
1. Check query filter logic (is it too strict?)
2. Test query in editor with relaxed filter
3. Verify data format matches stream definition
4. Fix and recreate stream

---

## Solutions

### Scenario 1 Solution
**Root cause:** Consumer processing too slow for producer rate.
**Solutions:**
1. Add more consumer instances (scale out)
2. Increase partitions to enable more parallelism
3. Optimize consumer code (batch processing)

### Scenario 2 Solution
**Root cause:** Wrong Azure credentials.
**Fix:**
```bash
# Edit credentials
nano config/azure-credentials.env

# Restart connector
curl -X POST http://localhost:8083/connectors/azure-blob-sink-connector/restart
```

### Scenario 3 Solution
**Root cause:** Filter too strict (e.g., speed > 150, no vehicles go that fast).
**Fix:**
```sql
-- Drop and recreate with correct filter
DROP STREAM IF EXISTS speeding_stream DELETE TOPIC;

CREATE STREAM speeding_stream AS
SELECT * FROM vehicle_stream
WHERE speed_kmph > 80;  -- Changed from 150 to 80
```

---

## Key Takeaways

1. **Metrics tell a story** - Learn to read trends, not just snapshots

2. **Compare across components** - Input rate should match output rate

3. **Capacity planning is proactive** - Monitor trends to predict future needs

4. **Alerts should be actionable** - Only alert on things you can fix

5. **Document your findings** - Build a runbook for common issues

---

## Next Steps

**You've completed Module 5!** 🎉

You now have the skills to:
- Monitor Kafka clusters effectively
- Identify performance bottlenecks
- Troubleshoot common issues
- Perform capacity planning

**→ Proceed to [Module 6: End-to-End Pipeline](../module-6-complete-pipeline/)** for the final capstone project where you'll deploy the complete vehicle telemetry system!

---

## Additional Resources

- **Confluent Control Center Docs:** https://docs.confluent.io/platform/current/control-center/index.html
- **Kafka Monitoring Best Practices:** https://kafka.apache.org/documentation/#monitoring
- **Consumer Lag Monitoring:** https://docs.confluent.io/platform/current/control-center/topics/lag-monitoring.html

---

**Great work on completing these exercises!** You're now a Kafka monitoring expert! 🚀
