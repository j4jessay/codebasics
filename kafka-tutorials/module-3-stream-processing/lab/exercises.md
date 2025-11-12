# Module 3: Additional Exercises

These exercises help reinforce your ksqlDB skills.

---

## Exercise 1: Engine Overheating Detection

**Challenge:** Create a stream to detect engine overheating (> 100°C).

**Requirements:**
- Stream name: `overheating_stream`
- Filter: `engine_temp_c > 100`
- Output topic: `vehicle.overheating`

**Solution:**
<details>
<summary>Click to see solution</summary>

```sql
CREATE STREAM overheating_stream
WITH (
  KAFKA_TOPIC='vehicle.overheating',
  VALUE_FORMAT='JSON',
  PARTITIONS=1
) AS
SELECT
  vehicle_id,
  engine_temp_c,
  timestamp_utc,
  'OVERHEATING_ALERT' AS alert_type
FROM vehicle_stream
WHERE engine_temp_c > 100
EMIT CHANGES;
```
</details>

---

## Exercise 2: Harsh Braking Detection

**Challenge:** Detect harsh braking (speed drops > 30 km/h in 5 seconds).

**Hint:** You'll need to compare current speed with previous speed using LAG function.

**Advanced:** This requires window functions and is challenging!

---

## Exercise 3: Hourly Statistics

**Challenge:** Create hourly (not 1-minute) aggregated statistics.

**Requirements:**
- Window size: 1 HOUR
- Metrics: Same as vehicle_stats_1min

**Solution:**
<details>
<summary>Click to see solution</summary>

```sql
CREATE TABLE vehicle_stats_hourly AS
SELECT
  vehicle_id,
  COUNT(*) AS event_count,
  AVG(speed_kmph) AS avg_speed,
  MAX(speed_kmph) AS max_speed
FROM vehicle_stream
WINDOW TUMBLING (SIZE 1 HOUR)
GROUP BY vehicle_id
EMIT CHANGES;
```
</details>

---

## Exercise 4: Combined Alerts Stream

**Challenge:** Create one stream with ALL alert types (speeding, low fuel, overheating).

**Requirements:**
- Include alert_type field to distinguish alerts
- Use INSERT INTO to combine streams

**Hint:** See Module 3 theory on combining streams

---

## Exercise 5: Moving Average Speed

**Challenge:** Calculate 5-minute moving average speed.

**Requirements:**
- Use HOPPING window
- Window size: 5 minutes
- Advance by: 1 minute

**Solution:**
<details>
<summary>Click to see solution</summary>

```sql
CREATE STREAM speed_moving_avg AS
SELECT 
  vehicle_id,
  AVG(speed_kmph) AS avg_speed_5min,
  WINDOWSTART AS window_start
FROM vehicle_stream
WINDOW HOPPING (SIZE 5 MINUTES, ADVANCE BY 1 MINUTE)
GROUP BY vehicle_id
EMIT CHANGES;
```
</details>

---

## Exercise 6: Custom Query Practice

**Challenge:** Write queries for these scenarios:

1. **Critical Fuel:** Find vehicles with fuel < 10%
2. **High Speed:** Find average speed when vehicle exceeds 90 km/h
3. **Count Alerts:** Count how many speeding events per vehicle per hour
4. **Location Filter:** Filter vehicles in specific GPS coordinates

---

## Bonus: Query Optimization

**Challenge:** Compare performance of these two approaches:

**Approach 1:**
```sql
SELECT * FROM vehicle_stream WHERE speed_kmph > 80 EMIT CHANGES;
```

**Approach 2:**
```sql
SELECT * FROM speeding_stream EMIT CHANGES;
```

**Question:** Which is more efficient and why?

**Answer:** Approach 2 is more efficient because it reads from a pre-filtered stream instead of filtering every time.

---

**Congratulations!** You've mastered ksqlDB stream processing. Ready for Module 4!
