# Monitoring with Confluent Control Center

## 📖 Reading Time: 5 minutes

---

## What is Confluent Control Center?

**Confluent Control Center** is a web-based GUI for managing and monitoring Apache Kafka clusters. It's part of the Confluent Platform and provides a centralized view of your entire Kafka ecosystem.

**Think of it as:** The "dashboard" of your car that shows speed, fuel, engine temperature - but for your Kafka cluster!

---

## Why Do We Need Monitoring?

### Without Monitoring (Flying Blind)

Imagine running your vehicle telemetry system without any visibility:

```
❌ Is Kafka receiving data? Unknown
❌ Are consumers keeping up? Unknown
❌ Is ksqlDB detecting speeding? Unknown
❌ Is connector sending to Azure? Unknown
❌ Any errors or issues? Unknown
```

**Problem:** You only find out about issues when users complain or the system breaks.

### With Control Center (Full Visibility)

```
✅ Producer rate: 50 messages/second
✅ Consumer lag: 0 messages (healthy)
✅ ksqlDB queries: Running, 45 events/min
✅ Azure connector: Running, 12 files written
✅ All systems: Green ✓
```

**Benefit:** Proactive monitoring, catch issues early, optimize performance.

---

## Key Features

### 1. Cluster Monitoring

**What it shows:**
- Broker status (up/down)
- Total topics and partitions
- Active producers and consumers
- Cluster throughput (messages/second)

**Example view:**
```
Cluster: kafka-cluster
Status: Healthy ✓

Brokers: 1 / 1 online
Topics: 8
Partitions: 24
Messages/sec: 52.3
Data rate: 45.2 KB/sec
```

---

### 2. Topic Monitoring

**What it shows:**
- Message rate for each topic
- Total messages stored
- Partition details
- Data size and retention

**Example view:**
```
Topic: vehicle.telemetry

Messages: 1,247,893
Partitions: 3
Replication: 1
Message rate: 50.2/sec

Under-replicated partitions: 0 ✓
```

**Why it matters:** See which topics are most active, identify hot topics.

---

### 3. Consumer Monitoring

**What it shows:**
- Consumer groups and members
- Consumer lag (how far behind)
- Consumption rate
- Offset position

**Example view:**
```
Consumer Group: vehicle-processor-group

Members: 2
Status: Stable ✓

Topic: vehicle.telemetry
Lag: 0 messages ✓
Current offset: 1,247,893
End offset: 1,247,893
```

**Why it matters:** Consumer lag is the #1 indicator of problems!

---

### 4. ksqlDB Monitoring

**What it shows:**
- Running queries
- Query performance
- Stream and table definitions
- Query editor for ad-hoc queries

**Example view:**
```
Query: SPEEDING_STREAM

Status: Running ✓
Uptime: 2h 34m
Messages processed: 45,234
Messages/sec: 5.2
Errors: 0
```

**Why it matters:** Ensure stream processing is running and performing well.

---

### 5. Kafka Connect Monitoring

**What it shows:**
- Connector status
- Task distribution
- Throughput metrics
- Error logs

**Example view:**
```
Connector: azure-blob-sink-connector

Status: Running ✓
Tasks: 1 / 1 running
Messages processed: 3,421
Throughput: 42.3 msg/sec
Errors: 0
```

**Why it matters:** Ensure data is flowing to external systems.

---

## Accessing Control Center

### URL
```
http://localhost:9021
```

### What You'll See First

**Home Screen:**
```
┌──────────────────────────────────────────────┐
│  Confluent Control Center                    │
│                                              │
│  ┌────────────────┐  ┌──────────────────┐   │
│  │   Cluster 1    │  │   Cluster Health │   │
│  │   1 broker     │  │   ✓ Healthy      │   │
│  └────────────────┘  └──────────────────┘   │
│                                              │
│  Topics: 8          Brokers: 1              │
│  Consumers: 3       Throughput: 52.3 msg/s  │
└──────────────────────────────────────────────┘
```

---

## Navigation Structure

### Main Menu (Left Sidebar)

1. **Home** - Cluster overview
2. **Cluster** - Broker and cluster configuration
3. **Topics** - List and details of all topics
4. **Consumers** - Consumer groups and lag
5. **ksqlDB** - Query editor and stream management
6. **Connect** - Connector management
7. **Settings** - Configuration and preferences

---

## Key Metrics Explained

### 1. Throughput

**Definition:** Number of messages per second

**Where to see it:**
- Cluster overview
- Per topic
- Per producer
- Per consumer

**Good/Bad:**
- ✅ Steady rate = healthy
- ⚠️ Sudden spike = investigate
- ❌ Zero messages = producer issue

---

### 2. Consumer Lag

**Definition:** How many messages behind the consumer is from the latest message

**Formula:**
```
Lag = End Offset - Current Offset
```

**Example:**
```
End offset: 1000 (latest message)
Consumer offset: 950 (consumer's position)
Lag: 50 messages
```

**Good/Bad:**
- ✅ Lag = 0 or near-zero = consumer keeping up
- ⚠️ Lag = 100-1000 = consumer slightly behind
- ❌ Lag growing = consumer can't keep up!

---

### 3. Partition Distribution

**Definition:** How partitions are distributed across brokers

**Example (1 broker, 3 partitions):**
```
Broker 1:
  - vehicle.telemetry-0 (Leader)
  - vehicle.telemetry-1 (Leader)
  - vehicle.telemetry-2 (Leader)
```

**Why it matters:** In multi-broker clusters, even distribution is critical for performance.

---

## Common Monitoring Tasks

### Task 1: Check if Producer is Sending Data

**Steps:**
1. Go to **Topics** menu
2. Find your topic (e.g., `vehicle.telemetry`)
3. Look at **Messages/sec** graph
4. Should see steady flow of messages

**What to look for:**
- ✅ Steady message rate
- ❌ Zero messages = producer not running
- ⚠️ Spiky pattern = producer issues

---

### Task 2: Check Consumer Lag

**Steps:**
1. Go to **Consumers** menu
2. Find your consumer group
3. Look at **Lag** column
4. Click for detailed per-partition lag

**What to look for:**
- ✅ Lag = 0 or small constant number
- ❌ Lag continuously growing = problem!

---

### Task 3: Verify ksqlDB Queries

**Steps:**
1. Go to **ksqlDB** menu
2. See list of running queries
3. Click on query for details
4. Check **Status** = Running

**What to look for:**
- ✅ Status = Running, no errors
- ❌ Status = Error, check error message

---

### Task 4: Monitor Kafka Connect

**Steps:**
1. Go to **Connect** menu
2. Find your connector (e.g., `azure-blob-sink-connector`)
3. Check **Status** = Running
4. View tasks and throughput

**What to look for:**
- ✅ All tasks running
- ❌ Failed tasks, check error logs

---

## Real-World Example: Vehicle Telemetry

Let's see what Control Center shows for our vehicle telemetry system:

### Cluster View
```
Brokers: 1 online ✓
Topics: 8 (vehicle.telemetry, vehicle.speeding, etc.)
Throughput: 52.3 messages/sec
```

### Topics View
```
vehicle.telemetry → 50 msg/sec ✓
vehicle.speeding → 2 msg/sec ✓
vehicle.lowfuel → 1 msg/sec ✓
vehicle.overheating → 0.5 msg/sec ✓
```

### Consumers View
```
ksqlDB query consumers → Lag: 0 ✓
```

### Connect View
```
azure-blob-sink-connector → Running, 42 msg/sec ✓
```

**Conclusion:** System healthy! All components working as expected.

---

## Alerting (Not Covered in This Tutorial)

Control Center also supports:
- Email alerts for lag thresholds
- Broker down notifications
- Connector failure alerts

*(This requires additional configuration not covered in this basic tutorial)*

---

## Control Center vs Command-Line Tools

| Task | Command-Line | Control Center |
|------|-------------|----------------|
| **Check topic list** | `kafka-topics --list` | Click "Topics" menu |
| **Check consumer lag** | `kafka-consumer-groups --describe` | Click "Consumers" menu |
| **View messages** | `kafka-console-consumer` | Built-in message browser |
| **Monitor throughput** | Not easy | Real-time graphs |
| **Visual dashboard** | Not available | Full UI |

**Benefit of Control Center:** Everything in one place, visual, easy to use.

---

## Limitations

Control Center is **not open source** - it's part of Confluent Platform (commercial):

- ✅ Free for development/testing
- ❌ Requires license for production

**Alternatives:**
- **Kafdrop** - Open-source web UI
- **AKHQ** - Open-source Kafka GUI
- **Grafana + Prometheus** - Metrics monitoring
- **Burrow** - Consumer lag monitoring

For this tutorial, we use Control Center because it's easy to set up with Docker.

---

## Key Takeaways

1. **Control Center is your monitoring dashboard** - everything in one place

2. **Consumer lag is the most important metric** - indicates if consumers are keeping up

3. **Use it proactively** - don't wait for problems, monitor regularly

4. **Visual graphs help** - easier to spot trends than command-line output

5. **Monitors entire stack** - Kafka, ksqlDB, Connect, Schema Registry

---

## What's Next?

Now that you understand what Control Center is, let's learn about the key metrics you should monitor.

**→ Next: [Key Metrics to Monitor](02-key-metrics.md)**

---

## 🤔 Self-Check Questions

Before moving on, make sure you can answer:

1. What is Confluent Control Center used for?
2. Why is consumer lag important?
3. What are the five main sections of Control Center?
4. How do you access Control Center?
5. What does "Messages/sec" tell you?

---

**Great job!** You've learned about Control Center. Next, we'll dive into specific metrics to monitor.
