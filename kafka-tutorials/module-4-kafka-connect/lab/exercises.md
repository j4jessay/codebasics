# Module 4: Additional Exercises

These exercises help reinforce your Kafka Connect skills.

---

## Exercise 1: Change Partition Format

**Challenge:** Modify the time-based partitioning to use daily folders instead of hourly.

**Current:**
```
year=2024/month=11/day=10/hour=14/
```

**Target:**
```
year=2024/month=11/day=10/
```

**Hint:** Modify `path.format` and `partition.duration.ms` in config.

**Solution:**
<details>
<summary>Click to see solution</summary>

```json
{
  "path.format": "'year'=YYYY/'month'=MM/'day'=dd",
  "partition.duration.ms": "86400000"
}
```
(86400000 ms = 24 hours)
</details>

---

## Exercise 2: Add More Topics

**Challenge:** Configure the connector to also export `vehicle.overheating` and `vehicle.stats.1min` topics.

**Hint:** Modify the `topics` parameter.

**Solution:**
<details>
<summary>Click to see solution</summary>

```json
{
  "topics": "vehicle.speeding,vehicle.lowfuel,vehicle.overheating,vehicle.stats.1min"
}
```
</details>

---

## Exercise 3: Change Batch Size

**Challenge:** Increase the flush size to 100 messages.

**Current:** `flush.size`: "10"

**Question:** What's the impact of larger batch sizes?

**Answer:** Larger batches = better throughput, higher latency

---

## Exercise 4: Monitor Connector

**Challenge:** Write a script that checks connector status every 10 seconds.

**Requirements:**
- Loop every 10 seconds
- Print connector state
- Alert if state = FAILED

**Starter code:**
```bash
#!/bin/bash
while true; do
    # Your code here
    sleep 10
done
```

---

## Exercise 5: Error Handling

**Challenge:** Intentionally break the connector (wrong Azure key) and observe what happens.

**Steps:**
1. Change Azure key to invalid value
2. Redeploy connector
3. Check status and logs
4. Fix and redeploy

**What you'll learn:** Error handling, troubleshooting

---

## Exercise 6: Alternative Sink

**Challenge:** Research and document how you would export data to:
- Amazon S3
- Elasticsearch  
- PostgreSQL database

**For each, find:**
- Connector name
- Required configuration parameters
- Use cases

---

## Bonus: Multi-Task Connector

**Challenge:** Configure the connector with `tasks.max`: "3" instead of "1".

**Questions:**
1. How many tasks are created?
2. How does this affect throughput?
3. When would you increase tasks?

**Hint:** Check status to see task distribution

---

**Congratulations!** You've mastered Kafka Connect. Ready for Module 5!
