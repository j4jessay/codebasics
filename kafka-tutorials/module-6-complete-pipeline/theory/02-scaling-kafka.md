# Scaling Kafka

## 📖 Reading Time: 8 minutes

---

## Overview

As your data grows, you'll need to **scale** your Kafka deployment. Scaling means increasing capacity to handle more throughput, more data, or more consumers.

There are two approaches:
1. **Vertical scaling** - Make machines bigger
2. **Horizontal scaling** - Add more machines

Kafka is designed for **horizontal scaling** - this is its superpower!

---

## Horizontal vs Vertical Scaling

### Vertical Scaling (Scale Up)

**What it means:** Increase resources on existing machines.

**Example:**
```
Before:
Broker 1: 4 CPUs, 16 GB RAM, 500 GB disk

After:
Broker 1: 16 CPUs, 64 GB RAM, 2 TB disk ↑
```

**Pros:**
- ✅ Simple (no architecture changes)
- ✅ No data rebalancing needed

**Cons:**
- ❌ Expensive (doubling resources costs more than 2x)
- ❌ Limited (can't scale infinitely)
- ❌ Single point of failure still exists

**Use case:** Quick fix for short-term capacity needs.

---

### Horizontal Scaling (Scale Out)

**What it means:** Add more machines to the cluster.

**Example:**
```
Before:
┌──────────┐
│ Broker 1 │  (Handling 100% of load)
└──────────┘

After:
┌──────────┐  ┌──────────┐  ┌──────────┐
│ Broker 1 │  │ Broker 2 │  │ Broker 3 │
└──────────┘  └──────────┘  └──────────┘
(Each handling ~33% of load)
```

**Pros:**
- ✅ Nearly infinite scalability
- ✅ Better fault tolerance (more replicas)
- ✅ Cost-effective (use commodity hardware)

**Cons:**
- ❌ More complex setup
- ❌ Requires data rebalancing

**Use case:** Long-term scaling strategy for Kafka.

---

## Scaling Brokers

### When to Add Brokers

**Indicators:**
1. **Disk usage > 70%** - Running out of space
2. **CPU usage > 70%** - Broker overloaded
3. **Network throughput > 80% of capacity** - Network saturated
4. **High request latency** - Broker can't keep up

**Example scenario:**
```
Current: 1 broker, 50,000 msg/sec
Target: 150,000 msg/sec (3x growth)
Action: Add 2 more brokers (total 3)
Result: Each broker handles 50,000 msg/sec
```

---

### How to Add a Broker

**Step-by-step:**

**1. Start the new broker:**
```yaml
# docker-compose.yml (add broker 2)
kafka2:
  image: confluentinc/cp-kafka:7.5.0
  environment:
    KAFKA_BROKER_ID: 2  # Unique ID
    KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
    KAFKA_LISTENERS: PLAINTEXT://kafka2:9092
```

```bash
docker-compose up -d kafka2
```

**2. Verify broker joined the cluster:**
```bash
# List brokers
docker exec zookeeper zookeeper-shell localhost:2181 ls /brokers/ids

# Output: [1, 2]  ← Broker 2 is now part of the cluster ✅
```

**3. Rebalance partitions:**

New brokers don't automatically get partitions. You need to **reassign partitions**.

```bash
# Generate reassignment plan
kafka-reassign-partitions \
  --bootstrap-server localhost:9092 \
  --topics-to-move-json-file topics.json \
  --broker-list "1,2" \
  --generate

# Execute reassignment
kafka-reassign-partitions \
  --bootstrap-server localhost:9092 \
  --reassignment-json-file reassignment.json \
  --execute

# Verify reassignment
kafka-reassign-partitions \
  --bootstrap-server localhost:9092 \
  --reassignment-json-file reassignment.json \
  --verify
```

**4. Monitor rebalancing:**

- Check Control Center → Cluster → Brokers
- Partitions should be evenly distributed
- Wait for "under-replicated partitions" to go to 0

---

### Partition Rebalancing Example

**Before adding broker 2:**
```
Broker 1:
  - topic-A-partition-0 (leader)
  - topic-A-partition-1 (leader)
  - topic-A-partition-2 (leader)

Broker 2:
  (not yet in cluster)
```

**After adding broker 2 and rebalancing:**
```
Broker 1:
  - topic-A-partition-0 (leader)
  - topic-A-partition-1 (follower)

Broker 2:
  - topic-A-partition-1 (leader)
  - topic-A-partition-2 (leader)
```

**Result:** Load distributed across both brokers!

---

## Scaling Partitions

### Why Increase Partitions?

Partitions enable **parallelism**:
- 1 partition → Max 1 consumer (limited throughput)
- 10 partitions → Max 10 consumers (10x throughput)

**Example:**
```
Scenario: Consumer processing 5,000 msg/sec, but producer sends 20,000 msg/sec

Problem: Consumer lag growing!

Solution: Increase partitions to 4, run 4 consumers
Result: Each consumer handles 5,000 msg/sec → 20,000 total ✅
```

---

### How to Increase Partitions

**Command:**
```bash
kafka-topics --bootstrap-server localhost:9092 \
  --alter --topic vehicle.telemetry \
  --partitions 6  # Increase from 3 to 6
```

**Important notes:**

1. **You CAN increase partitions** ✅
2. **You CANNOT decrease partitions** ❌ (would require deleting topic)
3. **Existing messages stay in old partitions** - Only new messages use new partitions
4. **Key-based ordering may be affected** - Messages with same key may go to different partitions

---

### Partition Count Best Practices

**How many partitions should a topic have?**

**Formula:**
```
Partitions = max(
  (Target throughput) / (Consumer throughput),
  (Max consumers you'll run)
)
```

**Example 1: High-throughput topic**
```
Target: 100,000 msg/sec
Single consumer: 10,000 msg/sec
Partitions needed: 100,000 / 10,000 = 10 partitions
```

**Example 2: Moderate-throughput topic**
```
Target: 1,000 msg/sec
Single consumer: 500 msg/sec
Partitions needed: 1,000 / 500 = 2 partitions

But you want to run 5 consumers for redundancy:
Use 5 partitions (each consumer gets 1 partition)
```

**Rule of thumb:**
- Start with: `Partitions = 2 × (Number of brokers)`
- Small topics (< 1,000 msg/sec): 1-3 partitions
- Medium topics (1,000-10,000 msg/sec): 3-10 partitions
- Large topics (> 10,000 msg/sec): 10-100 partitions

**Don't over-partition!**
- More partitions = More overhead (leader elections, file handles)
- Kafka recommends < 4,000 partitions per broker
- Start small, scale up as needed

---

## Scaling Consumers

### Consumer Scaling Strategies

#### Strategy 1: Add More Consumer Instances

**Before:**
```
Topic: 3 partitions
Consumer Group: 1 consumer

Consumer 1 → Partition 0, 1, 2  (handling all 3 partitions)
```

**After:**
```
Topic: 3 partitions
Consumer Group: 3 consumers

Consumer 1 → Partition 0
Consumer 2 → Partition 1
Consumer 3 → Partition 2
```

**Result:** 3x throughput (each consumer handles 1 partition)

**How to do it:**
```bash
# Terminal 1
python consumer.py --group-id vehicle-processor

# Terminal 2
python consumer.py --group-id vehicle-processor

# Terminal 3
python consumer.py --group-id vehicle-processor
```

**Key:** Use the **same group ID** - Kafka automatically balances partitions!

---

#### Strategy 2: Optimize Consumer Code

**Example: Slow consumer (sequential processing)**

```python
# SLOW - Process each message one by one
for message in consumer:
    result = process_message(message.value)
    save_to_database(result)  # Blocking DB call each time!
```

**Throughput:** ~100 msg/sec (limited by DB calls)

**Example: Fast consumer (batch processing)**

```python
# FAST - Batch messages before saving
batch = []
for message in consumer:
    batch.append(message.value)

    if len(batch) >= 100:  # Process in batches of 100
        results = [process_message(msg) for msg in batch]
        save_batch_to_database(results)  # One DB call for 100 messages
        batch = []
```

**Throughput:** ~5,000 msg/sec (50x improvement!)

---

#### Strategy 3: Use Multi-Threading

**Example: Parallel processing**

```python
from concurrent.futures import ThreadPoolExecutor

def process_message(message):
    # Expensive processing (API call, ML inference, etc.)
    return result

with ThreadPoolExecutor(max_workers=10) as executor:
    for message in consumer:
        executor.submit(process_message, message.value)
```

**Benefit:** Process multiple messages concurrently within one consumer.

**Caution:** Be careful with offset commits - only commit after processing completes!

---

### Consumer Scaling Limits

**Maximum consumers per consumer group = Number of partitions**

**Example:**
```
Topic: 3 partitions
Consumer group: 5 consumers

Consumer 1 → Partition 0
Consumer 2 → Partition 1
Consumer 3 → Partition 2
Consumer 4 → Idle (no partition to consume) ⚠️
Consumer 5 → Idle ⚠️
```

**Lesson:** If you need more than N consumers, you need at least N partitions!

---

## Scaling Producers

### Producer Scaling Strategies

#### Strategy 1: Increase Batch Size

**Small batches (default):**
```python
producer = KafkaProducer(
    batch_size=16384,  # 16 KB (default)
    linger_ms=0        # Send immediately
)
```

**Result:** Low latency, but low throughput (many small network requests)

**Large batches (optimized):**
```python
producer = KafkaProducer(
    batch_size=65536,  # 64 KB (4x larger)
    linger_ms=10       # Wait up to 10ms to batch more messages
)
```

**Result:** Higher throughput (fewer network requests), slightly higher latency

**Trade-off:** Batching improves throughput but adds latency.

---

#### Strategy 2: Enable Compression

```python
producer = KafkaProducer(
    compression_type='lz4'  # or 'snappy', 'gzip', 'zstd'
)
```

**Benefits:**
- Reduce network bandwidth (2-5x reduction)
- Reduce disk usage (same ratio)
- Increase effective throughput

**Cost:** CPU overhead for compression/decompression

**Comparison:**
| Compression | Speed | Ratio | Use Case |
|-------------|-------|-------|----------|
| **None** | Fastest | 1x | Low CPU, high bandwidth |
| **LZ4** | Very fast | 2-3x | General purpose (best balance) |
| **Snappy** | Fast | 2-3x | Alternative to LZ4 |
| **Gzip** | Slow | 3-5x | Low bandwidth, high CPU |
| **Zstd** | Medium | 3-5x | Best compression, Kafka 2.1+ |

**Recommendation:** Use LZ4 for most cases.

---

#### Strategy 3: Add More Producer Instances

**Example:**
```
1 producer → 10,000 msg/sec

Add 2 more producers → 30,000 msg/sec
```

**Simple horizontal scaling!**

```bash
# Terminal 1
python vehicle_simulator.py --vehicles 10

# Terminal 2
python vehicle_simulator.py --vehicles 10

# Terminal 3
python vehicle_simulator.py --vehicles 10

# Total: 30 vehicles sending data
```

---

## Scaling ksqlDB

### When to Scale ksqlDB

**Indicators:**
1. **Query lag growing** - ksqlDB can't keep up with input rate
2. **High CPU usage** - Queries consuming too much CPU
3. **Complex queries** - Joins, windowing, aggregations

---

### ksqlDB Scaling Strategy

**Add more ksqlDB server instances:**

```yaml
# docker-compose.yml
ksqldb-server-1:
  image: confluentinc/ksqldb-server:0.29.0
  environment:
    KSQL_BOOTSTRAP_SERVERS: kafka:9092
    KSQL_KSQL_SERVICE_ID: my-ksql-cluster  # Same cluster ID

ksqldb-server-2:
  image: confluentinc/ksqldb-server:0.29.0
  environment:
    KSQL_BOOTSTRAP_SERVERS: kafka:9092
    KSQL_KSQL_SERVICE_ID: my-ksql-cluster  # Same cluster ID
```

**Result:** Queries distributed across ksqlDB servers (like consumer groups!)

---

## Scaling Kafka Connect

### When to Scale Kafka Connect

**Indicators:**
1. **Connector lag growing** - Can't keep up with input topics
2. **Many connectors** - Single worker overloaded

---

### Kafka Connect Scaling Strategy

**Distributed mode with multiple workers:**

```yaml
# docker-compose.yml
kafka-connect-1:
  image: confluentinc/cp-kafka-connect:7.5.0
  environment:
    CONNECT_GROUP_ID: connect-cluster
    CONNECT_CONFIG_STORAGE_TOPIC: connect-configs
    CONNECT_OFFSET_STORAGE_TOPIC: connect-offsets
    CONNECT_STATUS_STORAGE_TOPIC: connect-status

kafka-connect-2:
  image: confluentinc/cp-kafka-connect:7.5.0
  environment:
    CONNECT_GROUP_ID: connect-cluster  # Same group ID
    CONNECT_CONFIG_STORAGE_TOPIC: connect-configs
    CONNECT_OFFSET_STORAGE_TOPIC: connect-offsets
    CONNECT_STATUS_STORAGE_TOPIC: connect-status
```

**Result:** Connector tasks distributed across workers.

**Example:**
```
1 connector with 4 tasks
2 workers

Worker 1: Task 0, Task 1
Worker 2: Task 2, Task 3
```

---

## Real-World Scaling Example

### Scenario: E-commerce Platform

**Initial setup:**
```
Traffic: 1,000 orders/sec
Brokers: 3
Partitions: 10 per topic
Consumers: 10
Throughput: Adequate ✅
```

**Black Friday traffic spike:**
```
Traffic: 50,000 orders/sec (50x increase!)
Problem: Consumer lag growing to millions! ❌
```

**Scaling actions:**

**1. Increase partitions (urgent):**
```bash
kafka-topics --alter --topic orders --partitions 50
```

**2. Add more consumer instances:**
```
10 consumers → 50 consumers (match partition count)
```

**3. Add more brokers (if needed):**
```
3 brokers → 5 brokers (to handle disk/network load)
```

**4. Optimize consumer code:**
```python
# Batch database inserts
# Use connection pooling
# Cache frequently accessed data
```

**Result:**
```
Lag drops from millions → hundreds → zero ✅
System stable at 50,000 orders/sec
```

**After Black Friday:**
```
Traffic returns to normal
Scale down consumers to save costs
Keep higher partition count for future spikes
```

---

## Scaling Checklist

### Before Scaling

1. **Identify bottleneck** - What's the limiting factor?
   - Broker disk full? → Add brokers or reduce retention
   - Consumer lag? → Add consumers or optimize code
   - Network saturation? → Add brokers or enable compression

2. **Measure current capacity** - Know your baseline
   - Messages/sec
   - Disk usage
   - CPU/memory usage
   - Consumer lag

3. **Plan capacity** - How much do you need to scale?
   - 2x? 10x? 100x?
   - Short-term spike or long-term growth?

### During Scaling

1. **Scale gradually** - Don't jump from 1 to 100 brokers
2. **Monitor closely** - Watch metrics during and after scaling
3. **Test before production** - Validate in staging environment

### After Scaling

1. **Verify metrics** - Did scaling solve the problem?
2. **Document changes** - Update runbooks with new capacity
3. **Review costs** - Are you over-provisioned?

---

## Key Takeaways

1. **Kafka scales horizontally** - Add more machines, not bigger machines

2. **Partitions enable parallelism** - More partitions = more consumers

3. **Consumer scaling is easiest** - Just add more consumer instances

4. **Producer scaling is about batching and compression** - Optimize before adding instances

5. **Broker scaling requires rebalancing** - Plan for data movement

6. **Scale proactively** - Monitor trends, plan ahead

7. **Cost vs performance** - Don't over-provision

---

## What's Next?

Now that you understand production considerations and scaling, let's deploy the complete pipeline!

**→ Next: [Lab: Deploy Complete Pipeline](../lab/README.md)**

---

## 🤔 Self-Check Questions

Before moving to the lab, make sure you can answer:

1. What's the difference between horizontal and vertical scaling?
2. If a topic has 5 partitions, what's the maximum number of consumers in a consumer group?
3. How do you increase partition count for an existing topic?
4. What are three ways to scale consumer throughput?
5. Why is batching important for producer performance?

---

**Excellent!** You're ready to deploy and scale the complete pipeline in the lab!
