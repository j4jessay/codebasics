# Why Stream Processing?

## 📖 Reading Time: 8 minutes

---

## Overview

**Stream processing** is the practice of processing data continuously as it arrives, rather than waiting to batch it up for later processing.

---

## Batch vs Stream Processing

### Batch Processing (Traditional)

```
Collect data for hours/days → Process in batches → Get results

Example: Daily sales report
├── Collect orders all day
├── Run batch job at midnight
└── Get results next morning
```

**Characteristics:**
- ⏱️ **Latency:** Hours to days
- 💾 **Storage:** Store everything, then process
- 📊 **Use case:** Historical analysis, reports

**Example:** End-of-day sales reports, monthly analytics

---

### Stream Processing (Modern)

```
Data arrives → Process immediately → Get results instantly

Example: Real-time fraud detection
├── Transaction arrives
├── Check fraud rules in milliseconds
└── Approve/reject immediately
```

**Characteristics:**
- ⏱️ **Latency:** Milliseconds to seconds
- 💾 **Storage:** Process on-the-fly
- 📊 **Use case:** Real-time alerts, live dashboards

**Example:** Fraud detection, live monitoring, instant alerts

---

## When to Use Stream Processing

### ✅ Good Use Cases

**1. Real-Time Alerts**
```
Vehicle speed > 80 km/h → Instant alert to dispatcher
Fuel < 15% → Notify driver immediately
```

**2. Live Dashboards**
```
Website traffic → Update dashboard every second
Order count → Show live metrics
```

**3. Fraud Detection**
```
Credit card transaction → Check patterns in real-time
Suspicious activity → Block immediately
```

**4. IoT Monitoring**
```
Sensor readings → Detect anomalies instantly
Temperature spike → Trigger cooling system
```

**5. Personalization**
```
User clicks product → Update recommendations immediately
User searches → Adjust search results in real-time
```

---

### ❌ Not Ideal For

**1. Historical Analysis**
- Analyzing last year's data → Use batch processing

**2. Complex Joins Across Long Time Periods**
- Joining months of data → Use data warehouse

**3. One-Time Data Loads**
- Loading static reference data → Use batch jobs

---

## Real-World Examples

### Uber: Real-Time Ride Matching

```
Driver location updates (every 5 seconds)
         ↓
   Stream Processing
         ↓
Match with nearby riders → Calculate ETA → Update surge pricing
```

**Without stream processing:** Riders wait minutes, outdated ETAs

**With stream processing:** Instant matching, accurate ETAs

---

### Netflix: Viewing Analytics

```
User plays a video
      ↓
Stream Processing
      ↓
Update watch history → Recommend similar shows → Track engagement
```

**Result:** Real-time recommendations while you're still watching

---

### Banking: Fraud Detection

```
Credit card transaction
         ↓
   Stream Processing
         ↓
Check spending patterns → Compare to fraud models → Approve/reject
```

**Timing is critical:** Detect fraud in milliseconds, not hours

---

## Stream Processing Frameworks

### Popular Options

| Framework | Language | Complexity | Use Case |
|-----------|----------|------------|----------|
| **ksqlDB** | SQL | Easy | Real-time queries, filtering |
| **Kafka Streams** | Java/Scala | Medium | Application-embedded processing |
| **Apache Flink** | Java/Scala | High | Complex event processing |
| **Apache Spark Streaming** | Scala/Python | Medium | Micro-batching |
| **Apache Storm** | Java | High | Low-latency processing |

**For this tutorial:** We'll use **ksqlDB** because:
- ✅ SQL-based (easy to learn)
- ✅ Built on Kafka (no separate cluster)
- ✅ Perfect for filtering and aggregations

---

## Benefits of Stream Processing

### 1. Low Latency

**Batch:**
```
Order placed at 10:00 AM
Batch runs at midnight
Notification sent at 12:01 AM (14 hours later)
```

**Stream:**
```
Order placed at 10:00 AM
Processed immediately
Notification sent at 10:00:01 AM (1 second later)
```

---

### 2. Reduced Storage Costs

**Batch:** Store everything, then process
```
Store 1 TB/day → Keep for 30 days → 30 TB storage
```

**Stream:** Process and discard
```
Process on-the-fly → Keep only results → 1 GB storage
```

---

### 3. Continuous Insights

**Batch:** Insights only after batch completes

**Stream:** Insights continuously updated

**Example: Website analytics**
- Batch: "Yesterday we had 10,000 visitors"
- Stream: "Right now we have 342 active users"

---

### 4. Event-Driven Actions

**Batch:** React hours/days later

**Stream:** React instantly

**Example: Temperature monitoring**
- Batch: "Yesterday, temperature exceeded 100°C 3 times"
- Stream: "Temperature is 105°C right now → Turn on cooling!"

---

## Stream Processing Patterns

### 1. Filtering

Filter events based on conditions:

```sql
SELECT * FROM orders
WHERE amount > 1000;
```

**Use case:** High-value order alerts

---

### 2. Transformation

Transform data structure:

```sql
SELECT 
  order_id,
  customer_id,
  amount * 1.1 AS amount_with_tax
FROM orders;
```

**Use case:** Enrich data, calculate derived fields

---

### 3. Aggregation

Summarize data over time windows:

```sql
SELECT 
  customer_id,
  COUNT(*) AS order_count,
  SUM(amount) AS total_spent
FROM orders
WINDOW TUMBLING (SIZE 1 HOUR)
GROUP BY customer_id;
```

**Use case:** Real-time metrics, dashboards

---

### 4. Joining Streams

Combine multiple streams:

```sql
SELECT 
  o.order_id,
  o.amount,
  c.customer_name
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id;
```

**Use case:** Enrich orders with customer data

---

## Vehicle Telemetry Example

Let's apply stream processing to our vehicle IoT project:

### Without Stream Processing

```
1. Collect telemetry all day
2. Run batch job at night
3. Get speeding report next morning
```

**Problem:** Speeding detected 12 hours later!

---

### With Stream Processing

```
Vehicle speed = 95 km/h
       ↓
ksqlDB: WHERE speed > 80
       ↓
Alert dispatcher immediately
```

**Benefit:** Instant alerts, real-time action

---

## Key Takeaways

1. **Stream processing** handles data as it arrives (real-time)

2. **Batch processing** handles data in large chunks (delayed)

3. **Use stream processing** for: alerts, monitoring, fraud detection

4. **Use batch processing** for: historical analysis, reports

5. **ksqlDB** makes stream processing easy with SQL

6. **Low latency** is the main benefit (milliseconds vs hours)

---

## What's Next?

Now that you understand why stream processing matters, let's learn about ksqlDB!

**→ Next: [ksqlDB Overview](02-ksqldb-overview.md)**

---

## 🤔 Self-Check Questions

1. What's the main difference between batch and stream processing?
2. Name three use cases for stream processing.
3. Why is stream processing better for fraud detection than batch?
4. What is the latency of batch processing vs stream processing?

---
