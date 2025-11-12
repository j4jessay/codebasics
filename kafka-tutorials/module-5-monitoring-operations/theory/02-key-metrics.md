# Key Metrics to Monitor

## 📖 Reading Time: 5 minutes

---

## Overview

Monitoring Kafka is like monitoring a highway system:
- **Throughput** = Cars per hour
- **Latency** = Time to travel from A to B
- **Lag** = Traffic jam (cars backed up)
- **Errors** = Accidents

Let's learn what to monitor and why.

---

## 1. Producer Metrics

### Throughput (Messages/Second)

**What it measures:** How many messages producers are sending per second

**Where to see it:**
- Control Center → Topics → Select topic → Production tab

**Example:**
```
vehicle.telemetry topic
Messages/sec: 50.2
Bytes/sec: 45.3 KB
```

**What's normal:**
- ✅ Steady rate matching your expected load
- ⚠️ Sudden drop to zero = producer crashed
- ⚠️ Sudden spike = investigate why

**Real-world example:**
- **Our vehicle simulator:** 10 vehicles × 1 message every 2 seconds = 5 messages/sec
- **Control Center should show:** ~5 messages/sec

---

### Request Latency

**What it measures:** How long it takes for the broker to acknowledge a message

**Where to see it:**
- Control Center → Brokers → Produce Latency graph

**Example:**
```
Average latency: 12 ms
P99 latency: 45 ms
```

**What's normal:**
- ✅ < 10 ms = excellent
- ⚠️ 10-100 ms = acceptable
- ❌ > 100 ms = investigate

**What affects latency:**
- Network distance
- Broker disk I/O
- Replication settings (`acks=all` is slower but safer)
- Batch size (larger batches = higher latency)

---

### Error Rate

**What it measures:** Failed produce requests

**Where to see it:**
- Control Center → Topics → Messages tab (look for errors)

**Example:**
```
Success rate: 99.8%
Error rate: 0.2%
```

**Common errors:**
- `LEADER_NOT_AVAILABLE` - Broker restarting or partition leader election
- `REQUEST_TIMEOUT` - Network issue or slow broker
- `MESSAGE_TOO_LARGE` - Message exceeds max size

**What's normal:**
- ✅ 0% error rate
- ⚠️ Occasional errors (< 0.1%) can happen during rebalancing
- ❌ Sustained errors = serious problem

---

## 2. Consumer Metrics

### Consumer Lag (MOST IMPORTANT!)

**What it measures:** How far behind the consumer is from the latest message

**Formula:**
```
Lag = (Latest Offset) - (Consumer's Current Offset)
```

**Example:**
```
Topic: vehicle.telemetry
Partition 0:
  - End offset: 10,000 (latest message)
  - Consumer offset: 9,950 (where consumer is)
  - Lag: 50 messages
```

**Where to see it:**
- Control Center → Consumers → Select consumer group → Lag tab

**What's normal:**
- ✅ **Lag = 0** = Consumer is caught up (ideal!)
- ✅ **Lag = small constant number** = Consumer keeping pace but slightly behind (acceptable)
- ⚠️ **Lag = 100-1000 and stable** = Consumer slower than producer, but stable
- ❌ **Lag continuously growing** = Consumer can't keep up! (PROBLEM!)

**Visual example:**
```
Healthy Consumer:
Time:    0s    10s   20s   30s   40s
Lag:     0     0     2     1     0     ✅ Stable

Unhealthy Consumer:
Time:    0s    10s   20s   30s   40s
Lag:     10    50    120   200   350   ❌ Growing!
```

**Why lag matters:**
- Growing lag means real-time processing is falling behind
- Eventually, consumer might be hours or days behind
- Users see stale data

**How to fix growing lag:**
1. Add more consumer instances (scale out)
2. Optimize consumer code (faster processing)
3. Increase partitions (more parallelism)
4. Reduce processing per message

---

### Consumption Rate

**What it measures:** How many messages per second the consumer is processing

**Where to see it:**
- Control Center → Consumers → Select consumer group → Consumption tab

**Example:**
```
Consumer Group: vehicle-processor-group
Consumption rate: 48.5 messages/sec
```

**What's normal:**
- ✅ Consumption rate ≥ Production rate (consumer keeping up)
- ❌ Consumption rate < Production rate (lag will grow)

**Example:**
```
Producer: 50 messages/sec
Consumer: 48 messages/sec
Result: Lag grows by 2 messages/sec (120/min)
```

---

### Rebalance Events

**What it measures:** How often consumer group membership changes

**What causes rebalances:**
- Consumer joins or leaves the group
- Consumer crashes
- Partition count changes
- Session timeout

**Where to see it:**
- Control Center → Consumers → Consumer group → Events

**Example:**
```
Consumer Group: vehicle-processor-group
Last rebalance: 2 hours ago
Rebalance count: 3
```

**What's normal:**
- ✅ Rare rebalances (only when you add/remove consumers)
- ❌ Frequent rebalances (every few minutes) = consumers crashing or session timeouts

**Impact of rebalancing:**
- Consumers stop processing during rebalance (30 seconds to 2 minutes)
- Temporary lag spike

---

## 3. Broker Metrics

### Disk Usage

**What it measures:** How much disk space Kafka is using

**Where to see it:**
- Control Center → Cluster → Brokers → Storage tab

**Example:**
```
Broker 1:
  Total disk: 100 GB
  Used: 25 GB (25%)
  Available: 75 GB
```

**What's normal:**
- ✅ < 70% disk usage
- ⚠️ 70-85% = monitor closely, plan for expansion
- ❌ > 85% = urgent! Kafka may stop accepting messages

**How to manage:**
- Configure retention policy (delete old messages)
  ```
  retention.ms = 604800000  # 7 days
  ```
- Enable compression (reduces disk usage)
- Add more brokers and redistribute partitions

---

### CPU & Memory Usage

**What it measures:** Broker resource utilization

**Where to see it:**
- Control Center → Cluster → Brokers → System tab
- Or use `docker stats` command

**Example:**
```
Broker 1:
  CPU: 35%
  Memory: 2.1 GB / 4 GB (52%)
```

**What's normal:**
- ✅ CPU < 70%, Memory < 80%
- ⚠️ CPU > 70%, Memory > 80% = consider scaling
- ❌ CPU or Memory at 100% = performance issues

---

### Request Queue Size

**What it measures:** How many requests are waiting to be processed

**Where to see it:**
- Control Center → Cluster → Brokers → Request Metrics

**Example:**
```
Broker 1:
  Request queue size: 5
  Average: 3.2
```

**What's normal:**
- ✅ Queue size < 10
- ⚠️ Queue size 10-50 = broker getting busy
- ❌ Queue size > 50 = broker overloaded

---

## 4. ksqlDB Metrics

### Query Status

**What it measures:** Is the query running or failed?

**Where to see it:**
- Control Center → ksqlDB → Queries tab

**Example:**
```
Query: SPEEDING_STREAM
Status: RUNNING ✅
Uptime: 3h 45m
```

**Possible statuses:**
- ✅ `RUNNING` = Healthy
- ⚠️ `REBALANCING` = Temporary, normal
- ❌ `ERROR` = Query failed, check logs
- ❌ `NOT_RUNNING` = Query stopped

---

### Messages Processed

**What it measures:** How many messages the query has processed

**Where to see it:**
- Control Center → ksqlDB → Select query → Metrics

**Example:**
```
Query: SPEEDING_STREAM
Total messages processed: 1,234,567
Messages/sec: 5.2
```

**What's normal:**
- ✅ Messages/sec matches input rate (or filter reduces it)
- ❌ 0 messages/sec but input exists = query logic issue

**Example:**
```
Input topic (vehicle.telemetry): 50 msg/sec
Filter (speed > 80): ~10% match
Expected output: ~5 msg/sec ✓
```

---

### Error Count

**What it measures:** How many errors the query encountered

**Where to see it:**
- Control Center → ksqlDB → Select query → Errors tab

**Example:**
```
Query: SPEEDING_STREAM
Errors: 0 ✅
```

**Common errors:**
- Serialization errors (bad JSON)
- Null pointer exceptions (missing fields)
- Type conversion errors

---

## 5. Kafka Connect Metrics

### Connector Status

**What it measures:** Is the connector running?

**Where to see it:**
- Control Center → Connect → Connectors

**Example:**
```
Connector: azure-blob-sink-connector
Status: RUNNING ✅
Tasks: 1/1 running
```

**Possible statuses:**
- ✅ `RUNNING` = All tasks running
- ⚠️ `DEGRADED` = Some tasks failed
- ❌ `FAILED` = Connector failed
- ⚠️ `PAUSED` = Manually paused

---

### Throughput

**What it measures:** Messages sent to the sink (e.g., Azure Blob Storage)

**Where to see it:**
- Control Center → Connect → Select connector → Throughput tab

**Example:**
```
Connector: azure-blob-sink-connector
Messages sent: 3,421
Throughput: 42.3 msg/sec
```

**What's normal:**
- ✅ Throughput matches input topic rate
- ⚠️ Throughput < input rate = connector lag growing
- ❌ 0 throughput = connector not working

---

### Task Errors

**What it measures:** Connector task failures

**Where to see it:**
- Control Center → Connect → Select connector → Tasks → Errors

**Example:**
```
Task 0: Running ✅
Errors: 0
Last error: None
```

**Common errors:**
- `Authentication failed` - Wrong Azure credentials
- `Serialization error` - Bad data format
- `Connection timeout` - Network issue

---

## Monitoring Checklist

### Daily Checks (5 minutes)

```
☐ Cluster health: All brokers online?
☐ Consumer lag: All < 1000?
☐ ksqlDB queries: All running?
☐ Kafka Connect: All connectors running?
☐ Error count: Zero or near-zero?
```

### Weekly Checks (15 minutes)

```
☐ Disk usage: Still under 70%?
☐ Throughput trends: Expected patterns?
☐ Rebalance frequency: Rare?
☐ Query performance: No degradation?
```

---

## Setting Alerts (Not Hands-On, FYI)

In production, you'd set up alerts for:

1. **Consumer lag > threshold**
   - Example: Alert if lag > 10,000 messages for 5 minutes

2. **Broker down**
   - Example: Alert immediately if broker offline

3. **Connector failed**
   - Example: Alert if connector status = FAILED

4. **Disk usage > threshold**
   - Example: Alert if disk > 80%

*This requires Confluent Platform configuration beyond this tutorial.*

---

## Real-World Example: Vehicle Telemetry

Here's what healthy metrics look like for our system:

### Producers
```
Topic: vehicle.telemetry
Production rate: 5 msg/sec ✅
Latency: 8 ms ✅
Errors: 0% ✅
```

### Consumers (ksqlDB)
```
Consumer Group: _confluent-ksql-default_query_CTAS_SPEEDING_STREAM_*
Lag: 0 ✅
Consumption rate: 5 msg/sec ✅
```

### ksqlDB Queries
```
SPEEDING_STREAM: Running, 0.5 msg/sec ✅
LOWFUEL_STREAM: Running, 0.3 msg/sec ✅
OVERHEATING_STREAM: Running, 0.2 msg/sec ✅
```

### Kafka Connect
```
azure-blob-sink-connector: Running ✅
Throughput: 1 msg/sec ✅
Tasks: 1/1 running ✅
```

**Conclusion:** System healthy!

---

## Key Takeaways

1. **Consumer lag is #1 priority** - Growing lag = consumer can't keep up

2. **Throughput must balance** - Consumer rate ≥ Producer rate

3. **Zero errors is ideal** - Occasional errors OK, sustained errors BAD

4. **Disk usage matters** - Kafka needs space, plan retention

5. **Check status daily** - 5 minutes of monitoring prevents hours of debugging

---

## What's Next?

Now that you know which metrics to monitor, let's learn how to troubleshoot common issues.

**→ Next: [Troubleshooting Common Issues](03-troubleshooting.md)**

---

## 🤔 Self-Check Questions

Before moving on, make sure you can answer:

1. What does consumer lag measure?
2. If producer sends 100 msg/sec and consumer processes 80 msg/sec, what happens to lag?
3. What's a healthy error rate?
4. Why does disk usage matter for Kafka?
5. What are the three possible connector statuses?

---

**Great progress!** You now understand the key metrics. Next, learn troubleshooting.
