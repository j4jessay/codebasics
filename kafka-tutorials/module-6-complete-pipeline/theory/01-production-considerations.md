# Production Considerations

## 📖 Reading Time: 7 minutes

---

## Overview

You've learned how to build a Kafka pipeline in a development environment. But deploying Kafka in **production** requires additional considerations for:

- **High availability** - System stays up even if components fail
- **Security** - Protect data and prevent unauthorized access
- **Performance** - Handle production scale and load
- **Capacity planning** - Ensure adequate resources

Let's explore what changes when you go from development to production.

---

## 1. High Availability & Fault Tolerance

### Development (What We Did)

```
Single broker:
┌─────────────┐
│   Broker 1  │  If this fails → EVERYTHING STOPS ❌
└─────────────┘
```

**Problem:** Single point of failure. If the broker crashes, no Kafka!

### Production (What You Should Do)

```
Multi-broker cluster with replication:
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   Broker 1  │  │   Broker 2  │  │   Broker 3  │
│   Leader    │  │   Follower  │  │   Follower  │
└─────────────┘  └─────────────┘  └─────────────┘
```

**Key configuration:**
```properties
# Minimum 3 brokers
num.brokers = 3

# Replication factor = 3 (each partition has 3 copies)
default.replication.factor = 3

# Minimum in-sync replicas = 2 (at least 2 copies must acknowledge writes)
min.insync.replicas = 2

# Producer acknowledgment
acks = all  # Wait for all in-sync replicas
```

**Result:** If 1 broker fails, system continues with 2 remaining brokers! ✅

---

### Zookeeper High Availability

**Development:**
```
Single Zookeeper:
┌─────────────┐
│  Zookeeper  │  If this fails → Kafka can't elect leaders ❌
└─────────────┘
```

**Production:**
```
Zookeeper ensemble (3 or 5 nodes):
┌────────┐  ┌────────┐  ┌────────┐
│   ZK1  │  │   ZK2  │  │   ZK3  │
│ Leader │  │Follower│  │Follower│
└────────┘  └────────┘  └────────┘
```

**Rule:** Always use an **odd number** of Zookeeper nodes (3, 5, or 7).

**Why odd?** For consensus. With 3 nodes:
- If 1 fails → 2 remaining (majority) → System continues ✅
- If 2 fail → 1 remaining (minority) → System stops ❌

---

### KRaft Mode (Future of Kafka)

**New approach:** Kafka is removing Zookeeper dependency!

**KRaft mode:**
- Kafka manages metadata internally (no Zookeeper needed)
- Available in Kafka 3.3+ (production-ready in 3.5+)
- Simpler architecture, faster metadata operations

**Example docker-compose for KRaft:**
```yaml
kafka:
  environment:
    KAFKA_PROCESS_ROLES: 'broker,controller'
    KAFKA_CONTROLLER_QUORUM_VOTERS: '1@kafka1:9093,2@kafka2:9093,3@kafka3:9093'
    KAFKA_CONTROLLER_LISTENER_NAMES: 'CONTROLLER'
```

**Recommendation:** For new production deployments, consider KRaft mode.

---

## 2. Security Best Practices

### Development (What We Did)

```
NO SECURITY:
- No authentication (anyone can connect)
- No encryption (data sent in plain text)
- No authorization (anyone can do anything)
```

**Why it's okay for development:** Easy to set up, fast iteration.

**Why it's NOT okay for production:** Data breaches, unauthorized access, compliance violations!

---

### Production Security Layers

#### Layer 1: Encryption (SSL/TLS)

**Encrypt data in transit:**
```properties
# Enable SSL
listeners=SSL://kafka:9093
security.protocol=SSL

# SSL certificates
ssl.keystore.location=/var/private/ssl/kafka.server.keystore.jks
ssl.keystore.password=your-keystore-password
ssl.truststore.location=/var/private/ssl/kafka.server.truststore.jks
ssl.truststore.password=your-truststore-password
```

**Result:** All data encrypted between producers, brokers, and consumers.

---

#### Layer 2: Authentication (SASL)

**Verify identity of clients:**

Common authentication methods:
1. **SASL/PLAIN** - Username/password (simple, but not most secure)
2. **SASL/SCRAM** - Salted Challenge Response (better than PLAIN)
3. **SASL/GSSAPI (Kerberos)** - Enterprise-grade
4. **OAuth 2.0** - Modern, token-based

**Example (SASL/SCRAM):**
```properties
# Broker config
listeners=SASL_SSL://kafka:9093
security.protocol=SASL_SSL
sasl.mechanism=SCRAM-SHA-512

# Create user
kafka-configs --zookeeper localhost:2181 \
  --alter --add-config 'SCRAM-SHA-512=[password=secret]' \
  --entity-type users --entity-name alice
```

**Producer config:**
```python
producer = KafkaProducer(
    bootstrap_servers='kafka:9093',
    security_protocol='SASL_SSL',
    sasl_mechanism='SCRAM-SHA-512',
    sasl_plain_username='alice',
    sasl_plain_password='secret'
)
```

---

#### Layer 3: Authorization (ACLs)

**Control what authenticated users can do:**

```bash
# Allow user 'alice' to READ from topic 'vehicle.telemetry'
kafka-acls --bootstrap-server kafka:9093 \
  --add --allow-principal User:alice \
  --operation Read --topic vehicle.telemetry

# Allow user 'bob' to WRITE to topic 'vehicle.telemetry'
kafka-acls --bootstrap-server kafka:9093 \
  --add --allow-principal User:bob \
  --operation Write --topic vehicle.telemetry

# Deny user 'eve' from all topics
kafka-acls --bootstrap-server kafka:9093 \
  --add --deny-principal User:eve \
  --operation All --topic '*'
```

**Principle of Least Privilege:**
- Producers: WRITE access only to specific topics
- Consumers: READ access only to specific topics
- Admins: Full access

---

#### Layer 4: Encryption at Rest

**Encrypt data stored on disk:**

Options:
1. **Disk-level encryption** - Encrypt the entire disk (Linux dm-crypt, AWS EBS encryption)
2. **Kafka encryption** - Not natively supported, use disk encryption

**Example (AWS EBS):**
```
Enable EBS volume encryption when creating Kafka brokers
All data written to disk automatically encrypted
```

---

## 3. Performance Tuning

### Broker Configuration

**Key settings for production:**

```properties
# Number of threads for network requests
num.network.threads=8

# Number of threads for I/O operations
num.io.threads=16

# Socket send/receive buffer
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400

# Log segment size (1 GB)
log.segment.bytes=1073741824

# Flush messages to disk (balance between durability and performance)
log.flush.interval.messages=10000
log.flush.interval.ms=1000
```

**Tuning guideline:**
- More network threads → Handle more concurrent connections
- More I/O threads → Better disk utilization
- Larger segments → Less overhead for log management

---

### OS-Level Tuning

**Linux kernel parameters:**

```bash
# Increase file descriptor limit
ulimit -n 100000

# Increase TCP buffer sizes
sysctl -w net.core.rmem_max=134217728
sysctl -w net.core.wmem_max=134217728
sysctl -w net.ipv4.tcp_rmem="4096 87380 67108864"
sysctl -w net.ipv4.tcp_wmem="4096 65536 67108864"

# Enable TCP window scaling
sysctl -w net.ipv4.tcp_window_scaling=1

# Swappiness (minimize swapping)
sysctl -w vm.swappiness=1
```

---

### Disk Selection

**Development:** Any disk works (even spinning HDD)

**Production:**
- **SSDs strongly recommended** - 10-100x faster than HDDs
- **NVMe SSDs best** - Lowest latency
- **RAID 10** - Balance between performance and redundancy
- **Separate disks for OS and Kafka data**

**Benchmark:**
```
HDD: 100-200 IOPS, 100-150 MB/s
SSD: 10,000-100,000 IOPS, 500-3,000 MB/s
NVMe: 100,000-1,000,000 IOPS, 2,000-7,000 MB/s
```

**Kafka is disk I/O intensive!** Fast disks = better performance.

---

### Producer Tuning

```python
producer = KafkaProducer(
    # Batch multiple messages together
    batch_size=32768,  # 32 KB (default: 16 KB)

    # Wait up to 10ms to batch more messages
    linger_ms=10,  # (default: 0)

    # Compress messages (reduces network and disk usage)
    compression_type='lz4',  # or 'snappy', 'gzip', 'zstd'

    # Buffer size for batching
    buffer_memory=67108864,  # 64 MB (default: 32 MB)

    # Acknowledgment level
    acks='all',  # Wait for all replicas (safest)

    # Retries
    retries=2147483647,  # Retry forever (or until timeout)
    max_in_flight_requests_per_connection=5,
)
```

**Trade-offs:**
- Larger batches → Better throughput, higher latency
- Compression → Less network/disk, more CPU
- `acks=all` → Safer, slower

---

### Consumer Tuning

```python
consumer = KafkaConsumer(
    # Fetch more data per request
    fetch_min_bytes=1024,  # Wait for 1 KB (default: 1 byte)
    fetch_max_wait_ms=500,  # Max wait 500ms

    # Max records returned per poll
    max_poll_records=500,  # (default: 500)

    # Session timeout (heartbeat)
    session_timeout_ms=30000,  # 30 seconds
    heartbeat_interval_ms=10000,  # 10 seconds

    # Auto-commit offsets
    enable_auto_commit=True,
    auto_commit_interval_ms=5000,  # Every 5 seconds
)
```

---

## 4. Capacity Planning

### Estimating Disk Requirements

**Formula:**
```
Disk needed = (Message rate) × (Avg message size) × (Retention period) × (Replication factor)
```

**Example:**
```
Message rate: 1,000 msg/sec
Avg message size: 1 KB
Retention: 7 days = 604,800 seconds
Replication factor: 3

Disk needed = 1,000 × 1,024 × 604,800 × 3
            = 1,858,060,800,000 bytes
            = 1.73 TB

Add 20% buffer: 2.08 TB
```

**Recommendation:** Monitor disk usage weekly, plan capacity 3-6 months ahead.

---

### Estimating Broker Count

**Factors:**
1. **Throughput requirements**
2. **Partition count**
3. **Replication factor**
4. **Disk capacity**

**Example:**
```
Required throughput: 100,000 msg/sec
Single broker capacity: 50,000 msg/sec
Brokers needed: 100,000 / 50,000 = 2

With replication factor 3:
Actual brokers needed: 3 (minimum for HA)

Recommendation: 3-5 brokers
```

---

### Partition Planning

**How many partitions per topic?**

**Formula:**
```
Partitions = max(
  (Target throughput) / (Single consumer throughput),
  (Total consumers you want)
)
```

**Example:**
```
Target: 10,000 msg/sec
Single consumer: 2,000 msg/sec
Partitions needed: 10,000 / 2,000 = 5 partitions

You want 10 consumers for redundancy:
Use 10 partitions (so each consumer gets 1 partition)
```

**Trade-offs:**
- More partitions → Better parallelism, but more overhead
- Too few → Can't scale consumers
- Too many → Leader election slower, more file handles

**Rule of thumb:** 10-100 partitions per topic is common.

---

## 5. Monitoring & Alerting

### Key Metrics to Alert On

1. **Broker availability**
   - Alert if any broker down for > 5 minutes

2. **Consumer lag**
   - Warning: Lag > 10,000 for 5 minutes
   - Critical: Lag > 100,000 for 5 minutes

3. **Disk usage**
   - Warning: > 70%
   - Critical: > 85%

4. **Under-replicated partitions**
   - Critical: Any under-replicated partitions (data at risk!)

5. **Network throughput**
   - Warning: > 80% of network capacity

6. **Request latency**
   - Warning: P99 > 100ms

---

### Monitoring Stack

**Option 1: Confluent Control Center** (what we used)
- ✅ Easy to set up
- ❌ Commercial license for production

**Option 2: Prometheus + Grafana** (open source)
```
Kafka → JMX Exporter → Prometheus → Grafana
```

**Option 3: Cloud-managed monitoring**
- AWS CloudWatch (for AWS MSK)
- Confluent Cloud (fully managed)

---

## 6. Deployment Options

### Option 1: Self-Managed (What We Did with Docker)

**Pros:**
- ✅ Full control
- ✅ Lower cost

**Cons:**
- ❌ Complex to set up and maintain
- ❌ You handle all operations (upgrades, patches, scaling)

**Use case:** You have Kafka expertise in-house.

---

### Option 2: Managed Service (Cloud)

**Options:**
- **Confluent Cloud** - Fully managed Kafka by Confluent
- **AWS MSK** (Managed Streaming for Kafka)
- **Azure Event Hubs** (Kafka-compatible)
- **Google Cloud Pub/Sub** (alternative messaging)

**Pros:**
- ✅ Easy to set up and scale
- ✅ Automatic patches and upgrades
- ✅ Built-in monitoring

**Cons:**
- ❌ Higher cost
- ❌ Less control

**Use case:** Want to focus on application, not infrastructure.

---

### Option 3: Kubernetes (Container Orchestration)

**Using operators:**
- **Strimzi Kafka Operator**
- **Confluent Operator**

**Example (Strimzi):**
```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    replicas: 3
    storage:
      type: persistent-claim
      size: 100Gi
```

**Pros:**
- ✅ Easy to scale
- ✅ Self-healing (auto-restart failed pods)
- ✅ Declarative configuration

**Cons:**
- ❌ Requires Kubernetes expertise
- ❌ Stateful apps in Kubernetes can be tricky

---

## 7. Disaster Recovery

### Backup Strategies

**Option 1: Kafka-to-Kafka Replication (MirrorMaker)**

Replicate data between clusters (e.g., primary and DR datacenter):

```
Primary Cluster (US-East)    →    DR Cluster (US-West)
                         MirrorMaker
```

**Option 2: Export to Cloud Storage**

Use Kafka Connect (like we did with Azure Blob Storage):
- Continuous export to S3/Azure/GCS
- Can restore from cloud if needed

---

### Runbooks

Document procedures for common scenarios:

1. **Broker failure** - How to replace a broker
2. **Partition under-replicated** - How to force leader election
3. **Consumer lag** - How to scale consumers
4. **Disk full** - How to increase retention or add disk
5. **Upgrade** - Step-by-step upgrade procedure

**Example runbook:**
```markdown
## Broker Failure Recovery

1. Verify broker is down: `docker ps | grep kafka`
2. Check logs: `docker logs kafka`
3. Restart broker: `docker restart kafka`
4. Verify partitions are in-sync: Check Control Center
5. If still down, check Zookeeper connectivity
```

---

## Key Takeaways

1. **High Availability requires replication** - Minimum 3 brokers, replication factor 3

2. **Security is not optional in production** - SSL, authentication, authorization

3. **Performance tuning is critical** - SSDs, batch sizes, compression

4. **Capacity planning prevents outages** - Monitor disk, plan ahead

5. **Monitoring catches problems early** - Alert on lag, disk, broker health

6. **Choose deployment based on needs** - Self-managed vs managed service

7. **Disaster recovery is essential** - Backups, replication, runbooks

---

## What's Next?

Now that you understand production considerations, let's learn about scaling Kafka.

**→ Next: [Scaling Kafka](02-scaling-kafka.md)**

---

## 🤔 Self-Check Questions

Before moving on, make sure you can answer:

1. Why do you need at least 3 brokers in production?
2. What are the three layers of Kafka security?
3. What's the formula for calculating disk requirements?
4. Why are SSDs recommended for Kafka?
5. What's the difference between self-managed and managed Kafka?

---

**Great understanding!** You now know what it takes to run Kafka in production. Next, learn about scaling!
