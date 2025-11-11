# Module 1: Additional Exercises

These exercises help reinforce your understanding of Kafka fundamentals.

---

## Exercise 1: Topic Management

**Challenge:** Create a topic for vehicle telemetry data.

**Requirements:**
- Topic name: `vehicle.telemetry`
- Partitions: 3
- Replication factor: 1

**Commands to use:**
```bash
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --create ...
```

**Verification:**
```bash
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --describe --topic vehicle.telemetry
```

**Expected:** Topic created with 3 partitions

---

## Exercise 2: Send JSON Messages

**Challenge:** Send structured JSON messages to the `vehicle.telemetry` topic.

**Sample messages:**
```json
{"vehicle_id": "V001", "speed": 60, "fuel": 75}
{"vehicle_id": "V002", "speed": 45, "fuel": 80}
{"vehicle_id": "V003", "speed": 90, "fuel": 30}
```

**Hint:** Copy-paste JSON into the console producer

**Verification:** Consume and verify JSON is readable

---

## Exercise 3: Consumer Groups

**Challenge:** Create two consumer groups reading from the same topic.

**Steps:**
1. Send 10 messages to `test-topic`
2. Start consumer with group `group-1` and read all messages
3. Start another consumer with group `group-2` and read all messages
4. Both groups should see all messages independently

**Key Insight:** Each consumer group tracks its own offset

---

## Exercise 4: Partition Distribution

**Challenge:** Observe how messages are distributed across partitions.

**Steps:**
1. Create topic with 3 partitions: `distribution-test`
2. Send 15 messages without keys (round-robin)
3. Consume with partition display enabled
4. Count how many messages went to each partition

**Expected:** Roughly equal distribution (5, 5, 5)

---

## Exercise 5: Key-Based Routing

**Challenge:** Ensure all messages for a vehicle go to the same partition.

**Steps:**
1. Use `multi-partition-topic` (3 partitions)
2. Send 10 messages with keys: V001, V002, V003 (repeated)
3. Consume and observe partition assignment
4. Verify all V001 messages are in the same partition

**Why this matters:** Ensures ordering per vehicle

---

## Bonus Exercise: Retention Testing

**Challenge:** Create a topic with short retention and observe cleanup.

**Steps:**
1. Create topic with 1-minute retention:
   ```bash
   docker exec kafka kafka-topics --bootstrap-server localhost:29092 \
     --create --topic short-retention \
     --config retention.ms=60000
   ```
2. Send messages
3. Wait 2 minutes
4. Try to consume from beginning

**Expected:** Old messages are deleted

---

## Solutions

<details>
<summary>Click to see solutions</summary>

### Solution 1:
```bash
docker exec kafka kafka-topics \
  --bootstrap-server localhost:29092 \
  --create \
  --topic vehicle.telemetry \
  --partitions 3 \
  --replication-factor 1
```

### Solution 2:
```bash
docker exec -it kafka kafka-console-producer \
  --bootstrap-server localhost:29092 \
  --topic vehicle.telemetry

# Then paste JSON messages
```

### Solution 3:
```bash
# Terminal 1:
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic test-topic \
  --group group-1 \
  --from-beginning

# Terminal 2:
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic test-topic \
  --group group-2 \
  --from-beginning
```

</details>

---

**Congratulations!** You've mastered Kafka fundamentals. Ready for Module 2!
