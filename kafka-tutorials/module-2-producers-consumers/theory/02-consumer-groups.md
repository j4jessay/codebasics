# Consumer Groups & Offset Management

## 📖 Reading Time: 10 minutes

---

## Overview

**Kafka consumers** read events from topics. **Consumer groups** enable multiple consumers to work together for load balancing and fault tolerance.

---

## How Consumers Work

### Basic Consumer Flow

```
┌──────────────┐
│    Kafka     │
│    Topic     │
│ Partition 0  │  
│ Partition 1  │  
│ Partition 2  │ 
└───────┬──────┘
        │
        ▼
   ┌─────────┐
   │Consumer │
   └─────────┘
```

Consumer reads from assigned partitions and tracks its position using **offsets**.

---

## Consumer Groups

### What is a Consumer Group?

A **consumer group** is a set of consumers working together to consume a topic.

**Benefits:**
- **Load balancing:** Partitions distributed across consumers
- **Fault tolerance:** If one consumer fails, others take over
- **Scalability:** Add more consumers to handle more data

### Example: Single Consumer

```
Topic (3 partitions)
├── Partition 0
├── Partition 1
└── Partition 2
        │
        ▼
   Consumer 1 (reads all 3 partitions)
```

**Problem:** One consumer handles all load (bottleneck)

### Example: Consumer Group (3 Consumers)

```
Topic (3 partitions)
├── Partition 0 ──────▶ Consumer 1
├── Partition 1 ──────▶ Consumer 2
└── Partition 2 ──────▶ Consumer 3

Consumer Group: "analytics-group"
```

**Benefit:** Load distributed evenly

### Example: Consumer Group (2 Consumers)

```
Topic (3 partitions)
├── Partition 0 ──────▶ Consumer 1
├── Partition 1 ──────▶ Consumer 1
└── Partition 2 ──────▶ Consumer 2

Consumer Group: "analytics-group"
```

**Partition assignment is automatic!**

---

## Partition Assignment

### Rules

1. **Each partition assigned to exactly one consumer** in a group
2. **One consumer can read multiple partitions**
3. **Max consumers = number of partitions**
4. **Extra consumers sit idle** (waiting for failures)

### Examples

**3 partitions, 2 consumers:**
```
P0 → C1
P1 → C1
P2 → C2
```

**3 partitions, 4 consumers:**
```
P0 → C1
P1 → C2
P2 → C3
     C4 (idle, waiting)
```

**6 partitions, 3 consumers:**
```
P0, P1 → C1
P2, P3 → C2
P4, P5 → C3
```

---

## Offset Management

### What is an Offset?

Consumers track their position using **offsets** - the sequential ID of each message.

```
Partition 0:
┌──────┬──────┬──────┬──────┬──────┐
│Msg 0 │Msg 1 │Msg 2 │Msg 3 │Msg 4 │
└──────┴──────┴──────┴──────┴──────┘
              ↑
         Consumer at offset 2
         (next read: offset 3)
```

### Commit Strategies

**1. Auto Commit (Default)**

```python
consumer = KafkaConsumer(
    'vehicle.telemetry',
    bootstrap_servers='localhost:9092',
    group_id='my-group',
    enable_auto_commit=True,
    auto_commit_interval_ms=5000  # Commit every 5 seconds
)
```

**Pros:** Simple, no manual management
**Cons:** Risk of duplicates or data loss

**2. Manual Commit (Recommended for Production)**

```python
consumer = KafkaConsumer(
    'vehicle.telemetry',
    enable_auto_commit=False
)

for message in consumer:
    process(message)
    consumer.commit()  # Commit after processing
```

**Pros:** Full control, exactly-once processing
**Cons:** More complex

---

## Consumer Configuration

### Essential Parameters

```python
from kafka import KafkaConsumer
import json

consumer = KafkaConsumer(
    'vehicle.telemetry',  # Topic(s) to consume
    
    # Connection
    bootstrap_servers='localhost:9092',
    
    # Consumer Group
    group_id='analytics-group',
    
    # Offset Management
    auto_offset_reset='earliest',  # Start from beginning if no offset
    enable_auto_commit=True,
    auto_commit_interval_ms=5000,
    
    # Deserialization
    value_deserializer=lambda m: json.loads(m.decode('utf-8')),
    key_deserializer=lambda k: k.decode('utf-8') if k else None
)
```

### Key Parameters

| Parameter | Values | Purpose |
|-----------|--------|---------|
| `group_id` | String | Consumer group name |
| `auto_offset_reset` | earliest/latest | Where to start if no offset |
| `enable_auto_commit` | True/False | Auto vs manual commit |
| `max_poll_records` | Integer | Max messages per poll |

---

## Consuming Messages

### Basic Consumer Loop

```python
from kafka import KafkaConsumer

consumer = KafkaConsumer(
    'vehicle.telemetry',
    bootstrap_servers='localhost:9092',
    group_id='telemetry-processor',
    value_deserializer=lambda m: json.loads(m.decode('utf-8'))
)

try:
    for message in consumer:
        # Process message
        print(f'Vehicle: {message.value["vehicle_id"]}')
        print(f'Speed: {message.value["speed_kmph"]} km/h')
        print(f'Partition: {message.partition}')
        print(f'Offset: {message.offset}')
except KeyboardInterrupt:
    pass
finally:
    consumer.close()
```

### Consumer with Manual Commit

```python
consumer = KafkaConsumer(
    'vehicle.telemetry',
    enable_auto_commit=False
)

for message in consumer:
    try:
        # Process message
        process_telemetry(message.value)
        
        # Commit offset after successful processing
        consumer.commit()
    except Exception as e:
        print(f'Error processing message: {e}')
        # Don't commit - will retry this message
```

---

## Rebalancing

### What is Rebalancing?

When consumers join or leave a group, partitions are **reassigned** (rebalanced).

**Triggers:**
- New consumer joins group
- Consumer leaves or crashes
- New partitions added to topic

### Example Rebalance

**Before (2 consumers):**
```
P0, P1 → C1
P2, P3 → C2
```

**C3 joins:**
```
(Rebalancing...)
P0 → C1
P1, P2 → C2
P3 → C3
```

**During rebalancing:**
- All consumers stop consuming
- Partitions are reassigned
- Consumers resume with new assignments

**Impact:** Brief pause in processing

---

## Multiple Consumer Groups

**Key Concept:** Different consumer groups can read the same topic independently.

```
         Topic: orders
              │
      ┌───────┼───────┐
      │       │       │
      ▼       ▼       ▼
  Group 1  Group 2  Group 3
  (Email)  (SMS)   (Analytics)
```

Each group tracks its own offsets!

**Example:**
```python
# Email service
email_consumer = KafkaConsumer(
    'orders',
    group_id='email-service'
)

# Analytics service
analytics_consumer = KafkaConsumer(
    'orders',
    group_id='analytics-service'
)
```

Both read the same messages, independently.

---

## Best Practices

### 1. Choose Appropriate Group ID

```python
# Good: Descriptive names
group_id='vehicle-alert-processor'
group_id='telemetry-analytics'

# Bad: Generic names
group_id='consumer1'
group_id='test'
```

### 2. Handle Rebalances Gracefully

```python
from kafka import ConsumerRebalanceListener

class MyRebalanceListener(ConsumerRebalanceListener):
    def on_partitions_revoked(self, revoked):
        print(f'Partitions revoked: {revoked}')
        # Save state, commit offsets
    
    def on_partitions_assigned(self, assigned):
        print(f'Partitions assigned: {assigned}')
        # Initialize state for new partitions

consumer.subscribe(['vehicle.telemetry'], listener=MyRebalanceListener())
```

### 3. Commit Offsets Carefully

```python
# Commit after processing batch
for i, message in enumerate(consumer):
    process(message)
    
    if i % 100 == 0:  # Commit every 100 messages
        consumer.commit()
```

### 4. Set Timeouts Appropriately

```python
consumer = KafkaConsumer(
    session_timeout_ms=30000,    # 30 seconds
    max_poll_interval_ms=300000  # 5 minutes
)
```

---

## Monitoring Consumers

### Check Consumer Lag

```bash
# View consumer group details
docker exec kafka kafka-consumer-groups \
  --bootstrap-server localhost:29092 \
  --describe \
  --group analytics-group

# Output:
# GROUP           TOPIC            PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG
# analytics-group vehicle.telemetry 0         1000            1050            50
```

**LAG = 50** means consumer is 50 messages behind.

---

## Key Takeaways

1. **Consumer groups** enable load balancing and fault tolerance

2. **One partition → one consumer** per group

3. **Offsets** track consumer position

4. **Commit strategies** control reliability (auto vs manual)

5. **Rebalancing** happens when group membership changes

6. **Multiple groups** can read the same topic independently

---

## What's Next?

Learn about serialization and data formats.

**→ Next: [Serialization](03-serialization.md)**

---
