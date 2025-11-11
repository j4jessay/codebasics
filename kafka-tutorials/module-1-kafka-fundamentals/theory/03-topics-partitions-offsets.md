# Topics, Partitions & Offsets

## 📖 Reading Time: 6 minutes

---

## Topics: The Foundation

### What is a Topic?

A **topic** is a category or stream name where events are published.

**Analogy:** Think of topics like TV channels:
- News channel → `news topic`
- Sports channel → `sports topic`
- Movies channel → `movies topic`

In Kafka:
- Orders → `orders topic`
- Payments → `payments topic`
- Vehicle telemetry → `vehicle.telemetry topic`

### Topic Characteristics

```
Topic: vehicle.telemetry
├── Name: vehicle.telemetry
├── Partitions: 3
├── Replication Factor: 1
├── Retention: 7 days
└── Format: JSON
```

**Key Properties:**
- **Named:** Must have a unique name
- **Durable:** Events stored on disk
- **Append-only:** New events added to the end
- **Immutable:** Events cannot be modified once written

---

## Partitions: Scaling Out

### Why Partitions?

Imagine a single mailbox receiving millions of letters. Bottleneck!

**Solution:** Split into multiple mailboxes (partitions).

```
Topic: orders (1 partition) - Limited throughput
  ↓
Topic: orders (3 partitions) - 3x throughput
  Partition 0
  Partition 1
  Partition 2
```

### How Partitions Work

Each partition is an **ordered, immutable sequence** of events:

```
Topic: vehicle.telemetry (3 partitions)

Partition 0: [Event A] [Event D] [Event G] ...
Partition 1: [Event B] [Event E] [Event H] ...
Partition 2: [Event C] [Event F] [Event I] ...
```

**Key Points:**
1. Events within a partition are **ordered**
2. Events across partitions are **not ordered**
3. Each partition can be on a **different broker**

### Partition Distribution

```
Kafka Cluster (3 brokers)

Broker 1:  Partition 0 (leader)
Broker 2:  Partition 1 (leader)
Broker 3:  Partition 2 (leader)
```

**Benefit:** Load is distributed across brokers.

---

## Offsets: Tracking Position

### What is an Offset?

An **offset** is a unique sequential ID assigned to each event within a partition.

```
Partition 0:
┌────────┬────────┬────────┬────────┬────────┐
│Offset 0│Offset 1│Offset 2│Offset 3│Offset 4│
├────────┼────────┼────────┼────────┼────────┤
│Event A │Event B │Event C │Event D │Event E │
└────────┴────────┴────────┴────────┴────────┘
          ↑
       Consumer's current position
```

**Characteristics:**
- Starts at 0
- Increments by 1 for each new event
- Never changes (immutable)
- Unique within a partition (not globally unique)

### Consumer Offsets

Consumers track their position using offsets:

```
Consumer Group: analytics
Topic: orders
Partition 0: Consumer at offset 1500
Partition 1: Consumer at offset 2300
Partition 2: Consumer at offset 1800
```

**When consumer restarts:**
- It reads the last committed offset
- Resumes from that position
- No data loss or duplication

---

## Partition Keys

### How are Events Assigned to Partitions?

When a producer sends an event, it can specify a **key**:

```python
producer.send(
    topic="orders",
    key="customer_123",      # Partition key
    value={"order_id": "001", "total": 25.99}
)
```

### Partitioning Strategies

**1. With Key (Hash Partitioning)**

```
Key: "customer_123" → Hash → Partition 0
Key: "customer_456" → Hash → Partition 1
Key: "customer_789" → Hash → Partition 2
```

**Benefit:** All events for the same key go to the same partition (ordering guaranteed per customer).

**2. Without Key (Round-Robin)**

```
Event 1 → Partition 0
Event 2 → Partition 1
Event 3 → Partition 2
Event 4 → Partition 0  (round-robin)
```

**Benefit:** Load balancing.

**3. Custom Partitioner**

You can write custom logic:
```java
if (event.amount > 1000) {
    return partition_0;  // High-value orders
} else {
    return partition_1;  // Regular orders
}
```

---

## Ordering Guarantees

### Within a Partition: Ordered ✅

```
Partition 0:
[Order Created] → [Order Paid] → [Order Shipped] → [Order Delivered]
   Offset 0          Offset 1       Offset 2           Offset 3

Consumer reads in order: Created → Paid → Shipped → Delivered
```

**Guaranteed:** Events are processed in the order they were written.

### Across Partitions: Not Ordered ❌

```
Partition 0: [Order A: Created]  → [Order A: Paid]
Partition 1: [Order B: Created]  → [Order B: Paid]

Consumer might read:
  Order A: Created
  Order B: Created
  Order B: Paid    ← Out of order globally!
  Order A: Paid
```

**Important:** If order matters, use partition keys to keep related events in the same partition.

---

## Replication and Leaders

### Replication Factor

Each partition has multiple copies for fault tolerance:

```
Partition 0 (Replication Factor = 3)

Broker 1: Partition 0 (Leader)       ← Handles all reads/writes
Broker 2: Partition 0 (Follower)     ← Replicates leader
Broker 3: Partition 0 (Follower)     ← Replicates leader
```

**If Broker 1 fails:**
- Broker 2 or 3 becomes the new leader
- No data loss
- Clients automatically reconnect

### In-Sync Replicas (ISR)

**In-Sync Replicas:** Followers that are fully caught up with the leader.

```
Partition 0:
Leader (Broker 1):   [Events up to offset 1000]
Follower (Broker 2): [Events up to offset 1000] ← In-Sync ✅
Follower (Broker 3): [Events up to offset 950]  ← Out of Sync ❌
```

**For safety:** Producer can wait for ISR acknowledgment before confirming write.

---

## Practical Example: Vehicle Telemetry

Let's apply these concepts to our vehicle IoT system:

### Topic Configuration

```
Topic: vehicle.telemetry
Partitions: 3
Replication Factor: 1 (for simplicity in tutorial)
```

### Event Distribution

```python
# Producer code
for vehicle in vehicles:
    producer.send(
        topic="vehicle.telemetry",
        key=vehicle.id,          # "VEH-0001", "VEH-0002", etc.
        value=telemetry_data
    )
```

**Result:**
```
Partition 0: All events from VEH-0001, VEH-0004, VEH-0007, ...
Partition 1: All events from VEH-0002, VEH-0005, VEH-0008, ...
Partition 2: All events from VEH-0003, VEH-0006, VEH-0009, ...
```

**Benefit:** Each vehicle's events are ordered within its partition.

---

## Choosing Number of Partitions

### Factors to Consider

**1. Throughput**
- More partitions = higher throughput
- Each partition can handle ~10-100 MB/sec

**2. Parallelism**
- Max consumers = number of partitions
- 3 partitions → max 3 consumers reading in parallel

**3. Broker Count**
- Partitions distributed across brokers
- 3 brokers → at least 3 partitions to balance load

**4. Replication Overhead**
- More partitions = more replication traffic

### Rule of Thumb

**For this tutorial:** 1-3 partitions (simple, easy to understand)

**For production:**
- Start with 3-10 partitions
- Scale up as needed
- More partitions ≠ always better (overhead increases)

---

## Retention and Cleanup

### How Long are Events Kept?

Kafka retains events based on:

**1. Time-Based Retention**
```
retention.ms = 604800000  (7 days)
```

After 7 days, events are deleted.

**2. Size-Based Retention**
```
retention.bytes = 10737418240  (10 GB)
```

When topic reaches 10 GB, oldest events deleted.

**3. Compacted Topics (Advanced)**
- Keeps only the latest event per key
- Used for changelog topics

### What Happens to Old Events?

```
Day 1: [Event 1] [Event 2] [Event 3]
Day 2: [Event 4] [Event 5]
...
Day 8: [Event 1] [Event 2] [Event 3] ← DELETED (past retention)
```

**Important:** Consumers must process events before retention period expires.

---

## Summary Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Topic: vehicle.telemetry                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Partition 0 (Broker 1)                                     │
│  ┌─────────┬─────────┬─────────┬─────────┬─────────┐      │
│  │ Offset 0│ Offset 1│ Offset 2│ Offset 3│ Offset 4│      │
│  ├─────────┼─────────┼─────────┼─────────┼─────────┤      │
│  │VEH-0001 │VEH-0004 │VEH-0007 │VEH-0001 │VEH-0004 │      │
│  └─────────┴─────────┴─────────┴─────────┴─────────┘      │
│                                                              │
│  Partition 1 (Broker 2)                                     │
│  ┌─────────┬─────────┬─────────┬─────────┐                │
│  │ Offset 0│ Offset 1│ Offset 2│ Offset 3│                │
│  ├─────────┼─────────┼─────────┼─────────┤                │
│  │VEH-0002 │VEH-0005 │VEH-0008 │VEH-0002 │                │
│  └─────────┴─────────┴─────────┴─────────┘                │
│                                                              │
│  Partition 2 (Broker 3)                                     │
│  ┌─────────┬─────────┬─────────┐                          │
│  │ Offset 0│ Offset 1│ Offset 2│                          │
│  ├─────────┼─────────┼─────────┤                          │
│  │VEH-0003 │VEH-0006 │VEH-0009 │                          │
│  └─────────┴─────────┴─────────┘                          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Takeaways

1. **Topics** are categories where events are organized

2. **Partitions** enable scalability by splitting topics

3. **Offsets** are unique sequential IDs within a partition

4. **Ordering** is guaranteed within a partition, not across partitions

5. **Partition keys** control which partition an event goes to

6. **Replication** provides fault tolerance

7. **Retention** controls how long events are kept

---

## Ready for Hands-On!

You now understand the core concepts. Let's put them into practice!

**→ Next: [Go to Lab](../lab/README.md)**

---

## 🤔 Self-Check Questions

Before starting the lab, make sure you can answer:

1. If a topic has 5 partitions, what's the maximum number of consumers that can read in parallel?

2. Why would you use a partition key?

3. What happens to events after the retention period expires?

4. Can you guarantee ordering across all partitions of a topic?

5. What is the first offset in a partition?

*(Answers: 1=5, 2=To keep related events in same partition, 3=They're deleted, 4=No, only within a partition, 5=0)*

---

**Excellent!** You've completed all theory for Module 1. Now let's build something!
