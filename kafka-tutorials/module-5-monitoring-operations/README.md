# Module 5: Monitoring & Operations

## ⏱️ Duration: 45 minutes
**Theory: 15 min | Hands-On: 30 min**

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

- ✅ Use Confluent Control Center to monitor Kafka clusters
- ✅ Understand key Kafka metrics (throughput, latency, consumer lag)
- ✅ Monitor producer and consumer performance
- ✅ Identify and troubleshoot common issues
- ✅ Use Control Center to manage topics, connectors, and ksqlDB queries
- ✅ Interpret cluster health indicators

---

## 📚 Module Structure

### Part 1: Theory (15 minutes)

Read the following theory files in order:

1. **[Monitoring with Control Center](theory/01-control-center-overview.md)** (5 min)
   - What is Confluent Control Center?
   - Key features and capabilities
   - UI navigation

2. **[Key Metrics to Monitor](theory/02-key-metrics.md)** (5 min)
   - Producer metrics (throughput, latency, errors)
   - Consumer metrics (lag, throughput)
   - Broker metrics (disk usage, CPU, network)
   - ksqlDB query performance

3. **[Troubleshooting Common Issues](theory/03-troubleshooting.md)** (5 min)
   - Consumer lag problems
   - Connection issues
   - Performance bottlenecks
   - Error patterns

### Part 2: Hands-On Lab (30 minutes)

**[→ Go to Lab](lab/README.md)**

- Access Confluent Control Center UI (5 min)
- Monitor topics and message flow (5 min)
- Track consumer groups and lag (5 min)
- Monitor ksqlDB queries (5 min)
- Review Kafka Connect connectors (5 min)
- Troubleshooting exercise (5 min)

---

## ✅ Prerequisites

Before starting this module:

- [ ] Completed Module 1 (Kafka Fundamentals)
- [ ] Completed Module 3 (Stream Processing with ksqlDB)
- [ ] Completed Module 4 (Kafka Connect)
- [ ] Have the full Kafka stack running (docker-compose from Module 4)
- [ ] Have producer generating data
- [ ] Have ksqlDB queries running
- [ ] Have Azure Blob connector deployed

---

## 🚀 What You'll Learn

In this module, you'll learn to monitor your entire Kafka pipeline:

```
┌─────────────────────────────────────────────────────────┐
│          Confluent Control Center (Port 9021)           │
│                                                         │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Cluster   │  │   Topics     │  │   Consumers  │ │
│  │   Health    │  │   Monitor    │  │   Lag Check  │ │
│  └─────────────┘  └──────────────┘  └──────────────┘ │
│                                                         │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   ksqlDB    │  │    Kafka     │  │   Alerts &   │ │
│  │   Queries   │  │   Connect    │  │   Metrics    │ │
│  └─────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │    Your Kafka Cluster          │
        │                                │
        │  • Brokers                     │
        │  • Topics & Partitions         │
        │  • Producers & Consumers       │
        │  • ksqlDB Streams              │
        │  • Kafka Connect Connectors    │
        └────────────────────────────────┘
```

---

## 🎓 Success Criteria

You've successfully completed this module when you can:

- [ ] Access and navigate Control Center UI
- [ ] View topic details (partition count, message rate, size)
- [ ] Monitor consumer group lag
- [ ] Check ksqlDB query status and performance
- [ ] View Kafka Connect connector health
- [ ] Identify performance bottlenecks
- [ ] Explain what consumer lag means and why it matters
- [ ] Use Control Center to troubleshoot issues

---

## 🔧 Key Features of Control Center

### 1. Cluster Overview
- Broker health status
- Total topics and partitions
- Active producers and consumers
- Overall throughput

### 2. Topic Monitoring
- Message rate (per second)
- Data size and retention
- Partition distribution
- Consumer group subscriptions

### 3. Consumer Lag Tracking
- Current lag per partition
- Lag trends over time
- Consumer group health
- Offset commit status

### 4. ksqlDB Management
- Running queries
- Query performance metrics
- Stream and table definitions
- SQL editor

### 5. Kafka Connect Monitoring
- Connector status (running/failed/paused)
- Task distribution
- Throughput metrics
- Error logs

---

## 📊 What You'll Monitor

Your complete vehicle telemetry pipeline:

```
Producer (vehicle_simulator.py)
    ↓
Topic: vehicle.telemetry
    ↓ (Monitor: message rate, size)
ksqlDB Streams (speeding, lowfuel, overheating)
    ↓ (Monitor: query performance, output rate)
Output Topics (vehicle.speeding, vehicle.lowfuel, etc.)
    ↓ (Monitor: consumer lag)
Kafka Connect (Azure Blob Sink)
    ↓ (Monitor: connector status, throughput)
Azure Blob Storage
```

---

## ⏭️ Next Module

Once you've completed this module, proceed to:

**[Module 6: End-to-End Pipeline →](../module-6-complete-pipeline/)**

---

## 🆘 Need Help?

- Check the **[Troubleshooting Guide](../reference/troubleshooting.md)**
- Review **[Quick Commands](../reference/quick-commands.md)**
- Visit **[Confluent Control Center Documentation](https://docs.confluent.io/platform/current/control-center/index.html)**

---

## 🌟 Why Monitoring Matters

In production systems:

- **Prevent outages** - Catch issues before they become critical
- **Optimize performance** - Identify bottlenecks and tune configurations
- **Ensure SLAs** - Track latency and throughput guarantees
- **Debug issues** - Quickly identify root causes of problems
- **Capacity planning** - Understand usage patterns and growth

Real-world example: If consumer lag keeps growing, your consumers can't keep up with producers. Control Center helps you spot this immediately.

---

**Let's begin!** Start with the theory files, then explore Control Center hands-on.
