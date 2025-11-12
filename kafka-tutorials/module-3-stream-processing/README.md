# Module 3: Stream Processing with ksqlDB

## ⏱️ Duration: 90 minutes
**Theory: 30 min | Hands-On: 60 min**

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

- ✅ Understand stream processing concepts and benefits
- ✅ Explain the difference between streams and tables in ksqlDB
- ✅ Write ksqlDB queries to filter and transform data
- ✅ Create derived streams for real-time alerts
- ✅ Perform aggregations with windowing
- ✅ Process vehicle telemetry data in real-time

---

## 📚 Module Structure

### Part 1: Theory (30 minutes)

Read the following theory files in order:

1. **[Why Stream Processing?](theory/01-why-stream-processing.md)** (8 min)
   - Batch vs stream processing
   - Use cases for real-time analytics
   - Stream processing frameworks

2. **[ksqlDB Overview](theory/02-ksqldb-overview.md)** (8 min)
   - What is ksqlDB?
   - SQL over streams
   - Architecture and components

3. **[Streams vs Tables](theory/03-streams-vs-tables.md)** (7 min)
   - Stream concept
   - Table concept
   - When to use each

4. **[Windowing & Time](theory/04-windowing-time.md)** (7 min)
   - Tumbling windows
   - Hopping windows
   - Session windows
   - Time semantics

### Part 2: Hands-On Lab (60 minutes)

**[→ Go to Lab](lab/README.md)**

- Set up ksqlDB with Docker (10 min)
- Create base vehicle stream (10 min)
- Write filtering queries (speeding, low fuel) (15 min)
- Create aggregation queries (1-minute stats) (15 min)
- Build combined alert stream (10 min)

---

## ✅ Prerequisites

Before starting this module:

- [ ] Completed Module 1 (Kafka Fundamentals)
- [ ] Completed Module 2 (Producers & Consumers)
- [ ] Have producer running (sending vehicle telemetry)
- [ ] Understand SQL basics (SELECT, WHERE, GROUP BY)

---

## 🚀 What You'll Build

In this module, you'll build real-time stream processing:

```
┌─────────────────────┐
│  Python Producer    │
│  (10 vehicles)      │
└──────────┬──────────┘
           │ vehicle.telemetry topic
           ▼
    ┌──────────────┐
    │    Kafka     │
    └──────┬───────┘
           │
           ▼
┌──────────────────────┐
│      ksqlDB          │
│                      │
│ Base Stream:         │
│ • vehicle_stream     │
│                      │
│ Filtered Streams:    │
│ • speeding_stream    │ (speed > 80)
│ • lowfuel_stream     │ (fuel < 15%)
│ • overheating_stream │ (temp > 100°C)
│                      │
│ Aggregations:        │
│ • vehicle_stats_1min │ (1-min windows)
└──────────────────────┘
           │
           ▼
   ┌─────────────────┐
   │  Output Topics  │
   │ • vehicle.speeding
   │ • vehicle.lowfuel
   │ • vehicle.overheating
   │ • vehicle.stats.1min
   └─────────────────┘
```

---

## 🎓 Success Criteria

You've successfully completed this module when you can:

- [ ] Explain when to use stream processing vs batch processing
- [ ] Start ksqlDB and access the CLI
- [ ] Create a stream from a Kafka topic
- [ ] Write filtering queries (WHERE clause)
- [ ] Write aggregation queries (GROUP BY, windowing)
- [ ] Create derived streams from existing streams
- [ ] Query streams in real-time

---

## 🔧 What You'll Learn

### Stream Processing Queries

**Filtering:**
```sql
CREATE STREAM speeding_stream AS
SELECT vehicle_id, speed_kmph, timestamp_utc
FROM vehicle_stream
WHERE speed_kmph > 80;
```

**Aggregation:**
```sql
CREATE TABLE vehicle_stats_1min AS
SELECT vehicle_id,
       COUNT(*) AS event_count,
       AVG(speed_kmph) AS avg_speed
FROM vehicle_stream
WINDOW TUMBLING (SIZE 1 MINUTE)
GROUP BY vehicle_id;
```

---

## ⏭️ Next Module

Once you've completed this module, proceed to:

**[Module 4: Kafka Connect & Data Integration →](../module-4-kafka-connect/)**

---

## 🆘 Need Help?

- Check the **[Troubleshooting Guide](../reference/troubleshooting.md)**
- Review **[Quick Commands](../reference/quick-commands.md)**
- Review **[ksqlDB Documentation](https://docs.ksqldb.io/)**

---

**Let's begin!** Start with the theory files, then move to the lab.
