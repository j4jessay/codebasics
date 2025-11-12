# Windowing & Time in Stream Processing

## 📖 Reading Time: 7 minutes

---

## Overview

**Windowing** is the process of grouping events into time-based buckets for aggregation.

**Why needed?** Streams are infinite - we need to define boundaries for calculations like COUNT, SUM, AVG.

---

## The Problem: Infinite Streams

### Without Windowing

```sql
-- This doesn't make sense for infinite streams!
SELECT COUNT(*) FROM orders;
```

**Question:** When does the count stop? Never!

---

### With Windowing

```sql
-- Count orders per hour
SELECT COUNT(*) FROM orders
WINDOW TUMBLING (SIZE 1 HOUR)
GROUP BY customer_id;
```

**Now it makes sense:** Count resets every hour.

---

## Window Types

### 1. Tumbling Windows (Fixed, Non-Overlapping)

**Definition:** Fixed-size windows that don't overlap.

```
Time:   0     1     2     3     4     5
        |-----|-----|-----|-----|-----|
Window: [  1  ][  2  ][  3  ][  4  ][  5  ]
```

**Example:** Hourly statistics

```sql
SELECT 
  vehicle_id,
  AVG(speed_kmph) AS avg_speed
FROM vehicle_stream
WINDOW TUMBLING (SIZE 1 HOUR)
GROUP BY vehicle_id;
```

**Result:**
- 00:00-01:00 → Average speed
- 01:00-02:00 → Average speed
- 02:00-03:00 → Average speed
- (no overlap)

---

### 2. Hopping Windows (Fixed, Overlapping)

**Definition:** Fixed-size windows that slide by a specified interval.

```
Time:   0     1     2     3     4
        |-----|-----|-----|-----|
Window: [  1-hour  ]
          [  1-hour  ]    (advance 30 min)
            [  1-hour  ]
```

**Example:** 1-hour windows, advance every 30 minutes

```sql
SELECT 
  vehicle_id,
  AVG(speed_kmph) AS avg_speed
FROM vehicle_stream
WINDOW HOPPING (SIZE 1 HOUR, ADVANCE BY 30 MINUTES)
GROUP BY vehicle_id;
```

**Result:**
- 00:00-01:00 → Stats
- 00:30-01:30 → Stats (overlaps with above)
- 01:00-02:00 → Stats

**Use case:** Moving averages, trend detection

---

### 3. Session Windows (Dynamic, Activity-Based)

**Definition:** Windows based on periods of activity separated by gaps.

```
Events: |  |  |        |  |  |        |  |
        <Session 1>   <Session 2>   <Session 3>
         (30s gap)     (30s gap)
```

**Example:** User sessions (5-minute inactivity timeout)

```sql
SELECT 
  user_id,
  COUNT(*) AS clicks
FROM clickstream
WINDOW SESSION (5 MINUTES)
GROUP BY user_id;
```

**Use case:** User sessions, anomaly detection

---

## Time Semantics

### Event Time vs Processing Time

**Event Time:** When the event actually happened
```
Event occurred: 10:00:00
```

**Processing Time:** When the event was processed by ksqlDB
```
Processed at: 10:05:00 (5-minute delay)
```

**Which to use?**
- **Event time:** For accurate historical analysis
- **Processing time:** When real-time is more important than accuracy

---

### Late Arriving Events

**Problem:** Events might arrive out of order.

```
Time:   10:00  10:01  10:02  10:03
Events:   E1     E2     E4     E3  ← E3 is late!
```

**Solution:** Grace period - wait for late events

```sql
WINDOW TUMBLING (SIZE 1 MINUTE, GRACE PERIOD 30 SECONDS)
```

---

## Practical Examples

### Example 1: 1-Minute Vehicle Statistics

```sql
CREATE TABLE vehicle_stats_1min AS
SELECT 
  vehicle_id,
  COUNT(*) AS event_count,
  AVG(speed_kmph) AS avg_speed,
  MAX(speed_kmph) AS max_speed,
  MIN(fuel_percent) AS min_fuel
FROM vehicle_stream
WINDOW TUMBLING (SIZE 1 MINUTE)
GROUP BY vehicle_id
EMIT CHANGES;
```

**Result:**
```
Vehicle | EventCount | AvgSpeed | MaxSpeed | MinFuel
--------|------------|----------|----------|--------
V001    | 120        | 65.5     | 85.0     | 73.2
V002    | 120        | 55.3     | 70.0     | 80.1
```

**Updates every minute!**

---

### Example 2: Hourly Order Totals

```sql
CREATE TABLE hourly_sales AS
SELECT 
  TIMESTAMPTOSTRING(WINDOWSTART, 'yyyy-MM-dd HH:mm') AS window_start,
  COUNT(*) AS order_count,
  SUM(amount) AS total_sales
FROM orders
WINDOW TUMBLING (SIZE 1 HOUR)
GROUP BY 1
EMIT CHANGES;
```

**Result:**
```
WindowStart      | OrderCount | TotalSales
-----------------|------------|------------
2024-11-10 10:00 | 45         | $2,150.00
2024-11-10 11:00 | 52         | $2,780.00
```

---

### Example 3: 5-Minute Moving Average

```sql
CREATE STREAM speed_moving_avg AS
SELECT 
  vehicle_id,
  AVG(speed_kmph) AS avg_speed_5min
FROM vehicle_stream
WINDOW HOPPING (SIZE 5 MINUTES, ADVANCE BY 1 MINUTE)
GROUP BY vehicle_id
EMIT CHANGES;
```

**Use case:** Smooth out speed fluctuations, detect trends

---

## Window Functions

### WINDOWSTART and WINDOWEND

Get window boundaries:

```sql
SELECT 
  vehicle_id,
  WINDOWSTART AS window_start,
  WINDOWEND AS window_end,
  COUNT(*) AS event_count
FROM vehicle_stream
WINDOW TUMBLING (SIZE 1 MINUTE)
GROUP BY vehicle_id;
```

**Result:**
```
Vehicle | WindowStart | WindowEnd   | EventCount
--------|-------------|-------------|------------
V001    | 10:00:00    | 10:01:00    | 120
V001    | 10:01:00    | 10:02:00    | 118
```

---

### TIMESTAMPTOSTRING

Format timestamps:

```sql
TIMESTAMPTOSTRING(WINDOWSTART, 'yyyy-MM-dd HH:mm:ss')
```

---

## Choosing Window Size

### Factors to Consider

**1. Latency Requirements**
- Smaller windows = lower latency
- 1-minute window → Results every minute
- 1-hour window → Results every hour

**2. Data Volume**
- More data = larger windows
- 1,000 events/sec → 1-minute windows (60K events)
- 10 events/sec → 10-second windows (100 events)

**3. Use Case**
- Real-time alerts → Small windows (seconds)
- Dashboards → Medium windows (minutes)
- Reports → Large windows (hours, days)

---

## Common Pitfalls

### 1. Windows Too Small

```sql
WINDOW TUMBLING (SIZE 1 SECOND)
```

**Problem:** Too many tiny windows, high overhead

---

### 2. Windows Too Large

```sql
WINDOW TUMBLING (SIZE 1 DAY)
```

**Problem:** Results updated only once per day (high latency)

---

### 3. Forgetting EMIT CHANGES

```sql
-- Wrong: Won't show updates
SELECT * FROM vehicle_stats_1min;

-- Correct: Shows continuous updates
SELECT * FROM vehicle_stats_1min EMIT CHANGES;
```

---

## Best Practices

### 1. Start with Tumbling Windows

Simplest to understand and debug.

```sql
WINDOW TUMBLING (SIZE 1 MINUTE)
```

---

### 2. Use Event Time When Possible

More accurate for historical analysis.

```sql
CREATE STREAM events (
  event_time VARCHAR,
  ...
) WITH (
  TIMESTAMP='event_time',
  TIMESTAMP_FORMAT='yyyy-MM-dd''T''HH:mm:ss''Z'''
);
```

---

### 3. Include Window Boundaries in Output

Helps with debugging:

```sql
SELECT 
  WINDOWSTART,
  WINDOWEND,
  vehicle_id,
  AVG(speed_kmph)
FROM vehicle_stream
WINDOW TUMBLING (SIZE 1 MINUTE)
GROUP BY vehicle_id;
```

---

## Key Takeaways

1. **Windowing** groups infinite streams into finite buckets

2. **Tumbling windows** - Fixed size, non-overlapping

3. **Hopping windows** - Fixed size, overlapping

4. **Session windows** - Dynamic, based on activity gaps

5. **Event time vs processing time** - Choose based on use case

6. **Window size** affects latency and resource usage

---

## Ready for Hands-On!

You've completed all theory. Now let's build real stream processing queries!

**→ Next: [Go to Lab](../lab/README.md)**

---

## 🤔 Self-Check Questions

1. What's the difference between tumbling and hopping windows?
2. When would you use session windows?
3. What's event time vs processing time?
4. Why do we need windowing for aggregations?

---
