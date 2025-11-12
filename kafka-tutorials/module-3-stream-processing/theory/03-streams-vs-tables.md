# Streams vs Tables in ksqlDB

## 📖 Reading Time: 7 minutes

---

## Core Concepts

In ksqlDB, there are two fundamental data structures:

1. **STREAM:** A sequence of immutable events
2. **TABLE:** The current state derived from events

Understanding the difference is crucial for effective stream processing.

---

## Streams: Event Sequences

### What is a Stream?

A **stream** represents an unbounded sequence of events.

**Analogy:** A river - water (events) flows continuously

**Characteristics:**
- Events are **immutable** (cannot change)
- Events are **append-only** (new events added to end)
- Historical events are preserved
- **Infinite** sequence

---

### Stream Example: Order Events

```sql
CREATE STREAM orders (
  order_id VARCHAR KEY,
  customer_id VARCHAR,
  amount DOUBLE,
  timestamp VARCHAR
) WITH (
  KAFKA_TOPIC='orders',
  VALUE_FORMAT='JSON'
);
```

**Data in stream:**
```
Time    | OrderID | CustomerID | Amount
--------|---------|------------|-------
10:00   | O001    | C123       | 50.00
10:05   | O002    | C456       | 100.00
10:10   | O003    | C123       | 75.00   ← New order from C123
10:15   | O004    | C123       | 25.00   ← Another order from C123
```

**Key point:** All events are kept. We see the full history.

---

### Querying Streams

```sql
-- Continuous query: Shows all events as they arrive
SELECT * FROM orders EMIT CHANGES;

-- Filter: Only high-value orders
SELECT * FROM orders
WHERE amount > 50
EMIT CHANGES;
```

---

## Tables: Current State

### What is a Table?

A **table** represents the **current state** by aggregating events from a stream.

**Analogy:** A snapshot - shows current state at this moment

**Characteristics:**
- Values can be **updated** (state changes)
- Only stores **latest value** per key
- Represents **current state**, not history
- **Mutable**

---

### Table Example: Customer Totals

```sql
CREATE TABLE customer_totals AS
SELECT 
  customer_id,
  SUM(amount) AS total_spent,
  COUNT(*) AS order_count
FROM orders
GROUP BY customer_id;
```

**State in table (continuously updated):**
```
CustomerID | TotalSpent | OrderCount
-----------|------------|------------
C123       | 150.00     | 3          ← Updates as new orders arrive
C456       | 100.00     | 1
```

**Key point:** Only current state is stored. History is aggregated away.

---

### How Table State Updates

**Initial state:**
```
C123: $0 (0 orders)
```

**After Order 1 (C123, $50):**
```
C123: $50 (1 order)
```

**After Order 2 (C123, $75):**
```
C123: $125 (2 orders)  ← Updated!
```

**After Order 3 (C123, $25):**
```
C123: $150 (3 orders)  ← Updated again!
```

---

## Streams vs Tables: Side-by-Side

| Aspect | Stream | Table |
|--------|--------|-------|
| **Represents** | Sequence of events | Current state |
| **Data** | All historical events | Latest value per key |
| **Updates** | Append-only (immutable) | Mutable (state changes) |
| **Query** | `EMIT CHANGES` (continuous) | Point-in-time lookup |
| **Example** | Order placed events | Customer balance |
| **Use case** | Event log, audit trail | Dashboard, lookups |

---

## When to Use Each

### Use STREAM When:

✅ You need **full event history**
```sql
-- All order events
CREATE STREAM orders ...
```

✅ You want to **filter events**
```sql
-- High-value orders
CREATE STREAM high_value AS
SELECT * FROM orders WHERE amount > 100;
```

✅ You need **event-driven processing**
```sql
-- Process each event independently
```

---

### Use TABLE When:

✅ You need **current aggregated state**
```sql
-- Total spent per customer
CREATE TABLE customer_totals AS
SELECT customer_id, SUM(amount) FROM orders GROUP BY customer_id;
```

✅ You want to **lookup latest value**
```sql
-- What's customer C123's current total?
SELECT * FROM customer_totals WHERE customer_id = 'C123';
```

✅ You need **join with latest state**
```sql
-- Enrich orders with customer's current total
SELECT o.*, c.total_spent
FROM orders_stream o
JOIN customer_totals c ON o.customer_id = c.customer_id;
```

---

## Vehicle Telemetry Example

### Stream: All Telemetry Events

```sql
CREATE STREAM vehicle_stream (
  vehicle_id VARCHAR,
  speed_kmph DOUBLE,
  fuel_percent DOUBLE,
  timestamp_utc VARCHAR
) WITH (
  KAFKA_TOPIC='vehicle.telemetry',
  VALUE_FORMAT='JSON'
);
```

**Data:**
```
VehicleID | Speed | Fuel | Time
----------|-------|------|------
V001      | 60    | 75   | 10:00
V001      | 65    | 74   | 10:01
V001      | 70    | 73   | 10:02  ← All events preserved
```

**Use case:** Audit trail, replay events, historical analysis

---

### Table: Current Vehicle State

```sql
CREATE TABLE vehicle_latest_state AS
SELECT 
  vehicle_id,
  LATEST_BY_OFFSET(speed_kmph) AS current_speed,
  LATEST_BY_OFFSET(fuel_percent) AS current_fuel
FROM vehicle_stream
GROUP BY vehicle_id;
```

**Data:**
```
VehicleID | CurrentSpeed | CurrentFuel
----------|--------------|-------------
V001      | 70           | 73          ← Only latest values
V002      | 55           | 80
```

**Use case:** Dashboard showing current vehicle status

---

## Stream-Table Duality

**Key concept:** Every table has an underlying stream, and every stream can be aggregated into a table.

### Stream → Table

```sql
-- Stream of events
CREATE STREAM events ...

-- Aggregate into table
CREATE TABLE state AS
SELECT key, COUNT(*) FROM events GROUP BY key;
```

### Table → Stream (Changelog)

```sql
-- Table state
CREATE TABLE customer_totals ...

-- View as stream of changes
SELECT * FROM customer_totals EMIT CHANGES;
```

---

## Practical Examples

### Example 1: Speeding Alerts (Stream)

```sql
-- Stream of speeding events
CREATE STREAM speeding_stream AS
SELECT vehicle_id, speed_kmph, timestamp_utc
FROM vehicle_stream
WHERE speed_kmph > 80;
```

**Why stream?** We want all speeding events, not just current state.

---

### Example 2: Vehicle Statistics (Table)

```sql
-- Table of 1-minute statistics
CREATE TABLE vehicle_stats_1min AS
SELECT 
  vehicle_id,
  AVG(speed_kmph) AS avg_speed,
  MAX(speed_kmph) AS max_speed
FROM vehicle_stream
WINDOW TUMBLING (SIZE 1 MINUTE)
GROUP BY vehicle_id;
```

**Why table?** We want current statistics, updated every minute.

---

## Key Takeaways

1. **STREAM** = Event sequence (immutable history)

2. **TABLE** = Current state (mutable aggregation)

3. **Use STREAM** for event logs, filtering, transformations

4. **Use TABLE** for aggregations, lookups, current state

5. **Stream-Table duality** - they're related!

6. **Vehicle telemetry** - Stream for all events, Table for current state

---

## What's Next?

Learn about windowing and time in stream processing!

**→ Next: [Windowing & Time](04-windowing-time.md)**

---

## 🤔 Self-Check Questions

1. What's the key difference between a stream and a table?
2. When would you use a stream vs a table?
3. Can a table be converted back to a stream?
4. Why would you aggregate a stream into a table?

---
