# Module 1 Lab: Kafka Fundamentals

## ⏱️ Duration: 40 minutes

---

## 🎯 Lab Objectives

By the end of this lab, you will:

- ✅ Set up a minimal Kafka cluster using Docker
- ✅ Create topics using CLI commands
- ✅ Send messages using the console producer
- ✅ Receive messages using the console consumer
- ✅ Understand offsets and consumer groups

---

## 🛠️ Setup (10 minutes)

### Step 1: Verify Prerequisites

```bash
# Check Docker is running
docker --version
docker compose version

# Expected output: Docker version 20.10+ and Compose 2.0+
```

### Step 2: Start Kafka Cluster

```bash
# Navigate to lab directory
cd kafka-tutorials/module-1-kafka-fundamentals/lab

# Start Zookeeper and Kafka
docker compose up -d

# Expected output:
# ✔ Container zookeeper  Started
# ✔ Container kafka      Started
```

**⏱️ Wait Time:** 30-60 seconds for services to initialize

### Step 3: Verify Services are Running

```bash
# Check running containers
docker ps

# You should see 2 containers:
# - zookeeper (port 2181)
# - kafka (ports 9092, 29092)
```

**✅ Success Checkpoint:** Both containers show status "Up"

---

## 📝 Exercise 1: Create Your First Topic (5 minutes)

### What You'll Do

Create a topic called `test-topic` with 1 partition and replication factor 1.

### Commands

```bash
# Create topic
docker exec kafka kafka-topics \
  --bootstrap-server localhost:29092 \
  --create \
  --topic test-topic \
  --partitions 1 \
  --replication-factor 1

# Expected output:
# Created topic test-topic.
```

### Verify Topic was Created

```bash
# List all topics
docker exec kafka kafka-topics \
  --bootstrap-server localhost:29092 \
  --list

# Expected output:
# test-topic
```

### View Topic Details

```bash
# Describe the topic
docker exec kafka kafka-topics \
  --bootstrap-server localhost:29092 \
  --describe \
  --topic test-topic

# Expected output:
# Topic: test-topic       TopicId: xxx    PartitionCount: 1       ReplicationFactor: 1
# Topic: test-topic       Partition: 0    Leader: 1       Replicas: 1     Isr: 1
```

**✅ Success Checkpoint:** Topic `test-topic` appears in the list with 1 partition

---

## 📤 Exercise 2: Send Messages (Producer) (5 minutes)

### What You'll Do

Use the console producer to send messages to `test-topic`.

### Commands

```bash
# Start console producer
docker exec -it kafka kafka-console-producer \
  --bootstrap-server localhost:29092 \
  --topic test-topic

# You'll see a prompt: >
# Type messages (one per line) and press Enter:
```

### Send These Messages

```
> Hello Kafka!
> This is my first message
> Learning event streaming
> Apache Kafka is awesome
```

**Press Ctrl+C to exit the producer**

**✅ Success Checkpoint:** No errors appear, messages are sent

---

## 📥 Exercise 3: Receive Messages (Consumer) (5 minutes)

### What You'll Do

Use the console consumer to read messages from `test-topic`.

### Commands

```bash
# Start console consumer (read from beginning)
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic test-topic \
  --from-beginning

# Expected output:
# Hello Kafka!
# This is my first message
# Learning event streaming
# Apache Kafka is awesome
```

**Press Ctrl+C to exit the consumer**

### Read Only New Messages

```bash
# Start console consumer (without --from-beginning)
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic test-topic

# (In another terminal, send more messages using producer)
# You'll only see new messages, not old ones
```

**✅ Success Checkpoint:** You see the messages you sent earlier

---

## 🔍 Exercise 4: Understanding Offsets (10 minutes)

### What You'll Do

Explore how offsets work and how consumers track their position.

### Step 1: Send Numbered Messages

```bash
# Start producer again
docker exec -it kafka kafka-console-producer \
  --bootstrap-server localhost:29092 \
  --topic test-topic

# Send these messages:
> Message 1
> Message 2
> Message 3
> Message 4
> Message 5
```

### Step 2: Consumer with Group ID

```bash
# Start consumer with a consumer group
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic test-topic \
  --group my-consumer-group \
  --from-beginning

# You'll see all messages from the beginning
# Press Ctrl+C after reading
```

### Step 3: Restart Consumer (Same Group)

```bash
# Start the same consumer group again
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic test-topic \
  --group my-consumer-group

# Notice: You DON'T see old messages!
# The consumer group remembered its position (offset)
```

**⚡ Key Insight:** Consumer groups track their offset. When restarted, they continue from where they left off.

### Step 4: View Consumer Group Offsets

```bash
# Check consumer group details
docker exec kafka kafka-consumer-groups \
  --bootstrap-server localhost:29092 \
  --describe \
  --group my-consumer-group

# Expected output shows:
# - CURRENT-OFFSET: Where the consumer is now
# - LOG-END-OFFSET: Total messages in the topic
# - LAG: How many messages behind
```

**✅ Success Checkpoint:** LAG shows 0 (consumer is caught up)

---

## 🔄 Exercise 5: Multiple Partitions (10 minutes)

### What You'll Do

Create a topic with multiple partitions and see how messages are distributed.

### Step 1: Create Multi-Partition Topic

```bash
# Create topic with 3 partitions
docker exec kafka kafka-topics \
  --bootstrap-server localhost:29092 \
  --create \
  --topic multi-partition-topic \
  --partitions 3 \
  --replication-factor 1

# Verify
docker exec kafka kafka-topics \
  --bootstrap-server localhost:29092 \
  --describe \
  --topic multi-partition-topic

# You should see Partition 0, 1, and 2
```

### Step 2: Send Messages with Keys

```bash
# Producer with key-value pairs
docker exec -it kafka kafka-console-producer \
  --bootstrap-server localhost:29092 \
  --topic multi-partition-topic \
  --property "parse.key=true" \
  --property "key.separator=:"

# Send messages (key:value format):
> user1:Hello from user1
> user2:Hello from user2
> user3:Hello from user3
> user1:Another message from user1
> user2:Another message from user2
```

**Note:** Messages with the same key go to the same partition!

### Step 3: Consume with Partition Info

```bash
# Consumer showing partition, offset, key, value
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic multi-partition-topic \
  --from-beginning \
  --property print.partition=true \
  --property print.offset=true \
  --property print.key=true \
  --property print.value=true

# Output format: Partition:Offset:Key:Value
```

**⚡ Key Insight:** All messages from `user1` are in the same partition. This guarantees ordering for that user's messages.

**✅ Success Checkpoint:** You see partition numbers in the output

---

## 🎓 Lab Summary

Congratulations! You've completed Module 1 Lab. You now know how to:

- ✅ Start Kafka using Docker Compose
- ✅ Create topics with specified partitions
- ✅ Send messages using console producer
- ✅ Consume messages using console consumer
- ✅ Understand how offsets work
- ✅ Use consumer groups to track position
- ✅ Work with partition keys for ordering

---

## 🧹 Cleanup (Optional)

If you want to stop Kafka and free up resources:

```bash
# Stop containers
docker compose down

# To remove all data as well:
docker compose down -v
```

**Note:** If continuing to Module 2, leave the containers running!

---

## 🚀 Next Steps

Ready for more? Proceed to Module 2 where you'll build a Python producer from scratch!

**[→ Go to Module 2: Producers & Consumers](../../module-2-producers-consumers/)**

---

## 🆘 Troubleshooting

### Docker Containers Won't Start

```bash
# Check if ports are already in use
lsof -i :9092
lsof -i :2181

# Kill processes using those ports or change ports in docker-compose.yml
```

### Can't Connect to Kafka

```bash
# Verify Kafka is running
docker logs kafka

# Check for errors in the logs
```

### Messages Not Appearing

```bash
# Make sure you're using the correct topic name
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list

# Verify messages were sent (check producer output for errors)
```

---

**Great job!** You've completed the hands-on portion of Module 1.
