# Kafka Architecture Overview

## 📖 Reading Time: 7 minutes

---

## The Big Picture

Kafka's architecture consists of several key components working together:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Producer   │────▶│   Kafka     │────▶│  Consumer   │
│(Send Events)│     │   Broker    │     │(Read Events)│
└─────────────┘     └──────┬──────┘     └─────────────┘
                           │
                    ┌──────▼──────┐
                    │  Zookeeper  │
                    │(Coordination)│
                    └─────────────┘
```

---

## Core Components

### 1. Kafka Broker

**What it is:** A Kafka server that stores events and serves clients.

**Think of it as:** A post office that receives mail (events) and stores them in mailboxes (topics) for pickup.

**Key responsibilities:**
- Receives events from producers
- Stores events on disk
- Serves events to consumers
- Manages replication and partitions

**In production:** You typically run 3-7 brokers for fault tolerance.

**In this tutorial:** We'll start with 1 broker for simplicity.

---

### 2. Zookeeper

**What it is:** A coordination service that manages Kafka brokers.

**Think of it as:** The manager of the post office who tracks which mailboxes exist and who's in charge of each one.

**Key responsibilities:**
- Tracks which brokers are alive
- Stores metadata about topics
- Elects partition leaders
- Manages cluster configuration

**Important:** Kafka is moving away from Zookeeper (KRaft mode), but most production systems still use it.

---

### 3. Producer

**What it is:** An application that writes events to Kafka.

**Examples:**
- A web server logging user clicks
- An IoT sensor sending temperature readings
- A microservice publishing order events

**What it does:**
```python
# Pseudocode
producer = KafkaProducer()
producer.send(
    topic="orders",
    key="customer_123",
    value={"order_id": "001", "total": 25.99}
)
```

**Key features:**
- Can batch messages for efficiency
- Can compress data
- Chooses which partition to send to

---

### 4. Consumer

**What it is:** An application that reads events from Kafka.

**Examples:**
- An analytics service calculating metrics
- A notification service sending emails
- A data warehouse ingesting events

**What it does:**
```python
# Pseudocode
consumer = KafkaConsumer(topics=["orders"])
for message in consumer:
    process(message.value)
```

**Key features:**
- Can read at their own pace
- Can rewind and re-read old events
- Can form consumer groups for parallel processing

---

### 5. Topics

**What it is:** A category or feed name to which events are published.

**Think of it as:** A folder or channel where related events are stored.

**Examples:**
```
orders topic       → All order-related events
payments topic     → All payment-related events
vehicles topic     → All vehicle telemetry events
```

**Key characteristics:**
- Named (e.g., "orders", "payments")
- Can have multiple producers and consumers
- Events are stored in order within partitions
- Can be retained for hours, days, or forever

---

### 6. Partitions

**What it is:** A topic is split into partitions for scalability and parallelism.

**Think of it as:** Instead of one mailbox, you have multiple mailboxes for the same topic.

**Example:**

```
Topic: orders (3 partitions)

Partition 0: [Order 1, Order 4, Order 7, ...]
Partition 1: [Order 2, Order 5, Order 8, ...]
Partition 2: [Order 3, Order 6, Order 9, ...]
```

**Why partitions matter:**
1. **Parallelism:** Multiple consumers can read different partitions simultaneously
2. **Scalability:** Partitions can be spread across multiple brokers
3. **Ordering:** Order is guaranteed within a partition, not across partitions

---

## How Messages Flow

### Step 1: Producer Sends Event

```
Producer                 Kafka Broker
  │                           │
  │─────(1) Send event───────▶│
  │                           │
  │                      (Store on disk)
  │                           │
  │◀────(2) ACK received─────│
```

### Step 2: Event Stored in Partition

```
Topic: vehicle.telemetry

Partition 0: [Event 1] [Event 2] [Event 3] → [New Event]
             │         │         │            │
          Offset: 0   Offset: 1 Offset: 2  Offset: 3
```

Each event gets a unique **offset** (position) in the partition.

### Step 3: Consumer Reads Event

```
Kafka Broker             Consumer
     │                       │
     │◀───(1) Fetch data────│
     │                       │
     │─(2) Return events────▶│
     │                       │
     │◀──(3) Commit offset──│
```

Consumers track their position using offsets.

---

## Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Kafka Cluster                         │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   Broker 1                          │   │
│  │                                                      │   │
│  │  Topic: orders                                      │   │
│  │  ┌──────────────┐  ┌──────────────┐                │   │
│  │  │ Partition 0  │  │ Partition 1  │                │   │
│  │  │ [Msg][Msg]   │  │ [Msg][Msg]   │                │   │
│  │  └──────────────┘  └──────────────┘                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                  Zookeeper                          │   │
│  │  (Tracks brokers, topics, partitions)               │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
           ▲                                      │
           │                                      ▼
    ┌──────┴──────┐                      ┌───────────────┐
    │  Producers  │                      │   Consumers   │
    │             │                      │               │
    │ Web Server  │                      │ Analytics     │
    │ IoT Device  │                      │ Notifications │
    │ Microservice│                      │ Data Warehouse│
    └─────────────┘                      └───────────────┘
```

---

## Key Terminology

### Offset
- **Definition:** A unique sequential ID for each message within a partition
- **Example:** Message at offset 100 comes before offset 101
- **Usage:** Consumers track their position using offsets

### Replication
- **Definition:** Copies of partitions stored on multiple brokers
- **Purpose:** Fault tolerance (if one broker fails, data is not lost)
- **Example:** Replication factor = 3 means 3 copies of each partition

### Leader & Followers
- **Leader:** One broker is the leader for each partition (handles all reads/writes)
- **Followers:** Other brokers replicate the leader (backups)
- **If leader fails:** A follower becomes the new leader

### Consumer Group
- **Definition:** Multiple consumers working together to read a topic
- **Benefit:** Load balancing (each consumer reads different partitions)
- **Example:**
  ```
  Topic with 3 partitions
  Consumer Group: analytics (3 consumers)

  Consumer 1 reads Partition 0
  Consumer 2 reads Partition 1
  Consumer 3 reads Partition 2
  ```

---

## Kafka vs Traditional Messaging

### Traditional Message Queue (e.g., RabbitMQ)

```
Producer → Queue → Consumer 1 (message deleted)
                 → Consumer 2 (can't read, already deleted)
```

**Problem:** Once consumed, message is gone.

### Kafka Event Log

```
Producer → Topic/Partition → Consumer 1 (reads from offset 0)
                           → Consumer 2 (reads from offset 0)
                           → Consumer 3 (joins later, reads from offset 0)
```

**Benefit:** Multiple consumers can read the same events, even new consumers joining later.

---

## Performance Characteristics

### Why Kafka is Fast

1. **Sequential Disk I/O**
   - Writes events sequentially (fast)
   - No random disk seeks (slow)

2. **Zero-Copy**
   - Data moves from disk to network without copying to application memory
   - OS-level optimization

3. **Batch Processing**
   - Producers batch multiple events
   - Network efficiency

4. **Compression**
   - Events compressed before sending
   - Reduces network and disk usage

**Result:** Millions of messages per second on commodity hardware

---

## Durability Guarantees

### How Kafka Ensures Data is Not Lost

1. **Replication**
   ```
   Partition 0 Leader    (Broker 1)
   Partition 0 Follower  (Broker 2)
   Partition 0 Follower  (Broker 3)
   ```

2. **Acknowledgments**
   - `acks=0`: Fire and forget (fast, unsafe)
   - `acks=1`: Leader acknowledges (balance)
   - `acks=all`: All replicas acknowledge (slow, safe)

3. **Retention**
   - Events stored for configured time (e.g., 7 days)
   - Or by size (e.g., 100 GB)
   - Or forever (if needed)

---

## Simple Example: Vehicle Telemetry

Let's see how our vehicle IoT system maps to Kafka architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                     Kafka Cluster                            │
│                                                              │
│  Topic: vehicle.telemetry (1 partition)                     │
│  ┌────────────────────────────────────────────────────┐    │
│  │ Offset 0: {vehicle_id: "V001", speed: 45, ...}    │    │
│  │ Offset 1: {vehicle_id: "V002", speed: 60, ...}    │    │
│  │ Offset 2: {vehicle_id: "V001", speed: 50, ...}    │    │
│  │ Offset 3: {vehicle_id: "V003", speed: 85, ...}    │    │
│  │ ...                                                 │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
         ▲                                        │
         │                                        ▼
┌────────┴────────┐                    ┌──────────────────┐
│ Python Producer │                    │ ksqlDB Processor │
│ (10 vehicles    │                    │ (detect alerts)  │
│  sending data)  │                    └──────────────────┘
└─────────────────┘
```

---

## What We'll Build in the Lab

In this module's lab, you'll set up:

```
┌─────────────┐
│  Zookeeper  │ (Port 2181)
└──────┬──────┘
       │
┌──────▼──────┐
│    Kafka    │ (Port 9092)
│   Broker    │
└─────────────┘
```

Then you'll interact with it using:
- **kafka-console-producer** (CLI tool to send messages)
- **kafka-console-consumer** (CLI tool to read messages)

---

## Key Takeaways

1. **Kafka Broker** - The server that stores and serves events

2. **Zookeeper** - Coordination service (tracks brokers and metadata)

3. **Topics** - Categories where events are organized

4. **Partitions** - Topics split for scalability and parallelism

5. **Offsets** - Sequential IDs for messages within a partition

6. **Producers** - Write events to Kafka

7. **Consumers** - Read events from Kafka

8. **Replication** - Multiple copies for fault tolerance

---

## What's Next?

Now that you understand Kafka's architecture, let's dive deeper into topics, partitions, and offsets.

**→ Next: [Topics, Partitions & Offsets](03-topics-partitions-offsets.md)**

---

## 🤔 Self-Check Questions

Before moving on, make sure you can answer:

1. What is the role of Zookeeper in a Kafka cluster?
2. What is a partition and why are they important?
3. How does Kafka achieve fault tolerance?
4. What is the difference between a topic and a partition?
5. Can multiple consumers read the same events from a topic?

---

**Great progress!** Move to the next file to learn about topics, partitions, and offsets in detail.
