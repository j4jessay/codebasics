# What is Kafka Connect?

## 📖 Reading Time: 7 minutes

---

## Overview

**Kafka Connect** is a framework for integrating Kafka with external systems (databases, cloud storage, search engines, etc.) without writing custom code.

**Think of it as:** Pre-built integrations for common data sources and sinks.

---

## The Problem: Custom Integration Code

### Without Kafka Connect

**Scenario:** Export Kafka data to Azure Blob Storage

```python
# Custom code you'd have to write:
from kafka import KafkaConsumer
from azure.storage.blob import BlobServiceClient
import json

consumer = KafkaConsumer('vehicle.speeding')
blob_client = BlobServiceClient(...)

for message in consumer:
    # Convert to JSON
    data = json.dumps(message.value)
    
    # Upload to Azure
    blob_client.upload_blob(data)
    
    # Handle errors, retries, batching, partitioning...
    # Manage offsets, handle failures...
```

**Problems:**
- ❌ Write and maintain custom code
- ❌ Handle errors and retries
- ❌ Manage offsets and consumer groups
- ❌ Deploy and monitor application
- ❌ Scale horizontally

---

### With Kafka Connect

**Same scenario using connector:**

```json
{
  "name": "azure-blob-sink",
  "config": {
    "connector.class": "AzureBlobStorageSinkConnector",
    "topics": "vehicle.speeding",
    "azblob.account.name": "mystorageaccount",
    "azblob.account.key": "...",
    "format.class": "JsonFormat"
  }
}
```

**Deploy with REST API:**
```bash
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @azure-blob-sink.json
```

**Benefits:**
- ✅ No code to write
- ✅ Built-in error handling
- ✅ Automatic offset management
- ✅ Simple deployment
- ✅ Scalable by default

---

## Kafka Connect Architecture

```
┌─────────────────────────────────────────────────┐
│          Kafka Connect Cluster                   │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ Worker 1 │  │ Worker 2 │  │ Worker 3 │     │
│  │          │  │          │  │          │     │
│  │ Task 1   │  │ Task 2   │  │ Task 3   │     │
│  │ Task 4   │  │          │  │          │     │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘     │
│       │             │             │            │
└───────┼─────────────┼─────────────┼────────────┘
        │             │             │
        ▼             ▼             ▼
   ┌─────────────────────────────────┐
   │         Kafka Cluster            │
   │  (Topics with data)              │
   └─────────────────────────────────┘
```

### Components

**1. Connect Workers**
- JVM processes that execute connectors
- Can run standalone or in distributed mode
- Handle task distribution and fault tolerance

**2. Connectors**
- Plugins that define how to copy data
- Source connector: Import data TO Kafka
- Sink connector: Export data FROM Kafka

**3. Tasks**
- Units of work within a connector
- Each task processes a subset of partitions
- Scalable (more tasks = higher throughput)

**4. Converters**
- Transform data between Kafka format and external system format
- JSON, Avro, String, etc.

---

## How Kafka Connect Works

### Data Flow

**Source Connector (Import):**
```
Database → Source Connector → Kafka Topic
```

**Sink Connector (Export):**
```
Kafka Topic → Sink Connector → Cloud Storage
```

### Step-by-Step: Sink Connector

1. **Consumer reads from topic**
   - Connect worker polls Kafka topics
   - Retrieves messages based on configuration

2. **Converter processes data**
   - Converts bytes to target format (JSON, Avro, etc.)

3. **Connector writes to destination**
   - Batches writes for efficiency
   - Handles errors and retries

4. **Offset management**
   - Commits offsets automatically
   - Ensures exactly-once delivery (when configured)

---

## Benefits of Kafka Connect

### 1. No Code Required

**Traditional:**
- Write producer/consumer code
- Handle serialization
- Manage offsets
- Deploy and monitor

**Kafka Connect:**
- JSON configuration file
- REST API deployment
- Done!

---

### 2. Fault Tolerance

- Worker failures handled automatically
- Tasks redistributed to healthy workers
- Automatic retries for transient errors
- Dead letter queue for failed records

---

### 3. Scalability

**Scale horizontally:**
```
1 worker = 1 task = X throughput
2 workers = 2 tasks = 2X throughput
3 workers = 3 tasks = 3X throughput
```

Add more workers to handle more data!

---

### 4. Common Integrations Pre-Built

**Don't reinvent the wheel:**
- 100+ connectors available
- Battle-tested in production
- Active community support

---

## Connect Modes

### Standalone Mode

**Use case:** Development, testing, simple deployments

**Characteristics:**
- Single worker process
- No fault tolerance
- Configuration in properties file

```bash
connect-standalone worker.properties connector1.properties
```

---

### Distributed Mode (Recommended)

**Use case:** Production deployments

**Characteristics:**
- Multiple worker processes
- Fault tolerant (worker failures handled)
- REST API for configuration
- Automatic rebalancing

```bash
connect-distributed worker.properties
```

---

## Popular Connectors

### Source Connectors (Import TO Kafka)

| Connector | Purpose |
|-----------|---------|
| **JDBC Source** | Database tables → Kafka |
| **Debezium** | Database CDC → Kafka |
| **File Source** | Files → Kafka |
| **MQTT Source** | IoT devices → Kafka |
| **HTTP Source** | REST APIs → Kafka |

---

### Sink Connectors (Export FROM Kafka)

| Connector | Purpose |
|-----------|---------|
| **JDBC Sink** | Kafka → Database |
| **Elasticsearch Sink** | Kafka → Elasticsearch |
| **S3 Sink** | Kafka → Amazon S3 |
| **Azure Blob Sink** | Kafka → Azure Blob Storage (we'll use this!) |
| **HDFS Sink** | Kafka → Hadoop HDFS |

---

## Real-World Example: Vehicle Telemetry Pipeline

### Our Use Case

```
┌──────────────┐
│ ksqlDB       │
│ (Processes)  │
│              │
│ • speeding   │
│ • lowfuel    │
│ • stats      │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Kafka Topics │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Azure Blob   │
│ Sink         │
│ Connector    │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Azure Blob   │
│ Storage      │
│ (JSON files) │
└──────────────┘
       │
       ▼
┌──────────────┐
│ Power BI     │
│ (Dashboard)  │
└──────────────┘
```

**Why Kafka Connect?**
- No custom code needed
- Handles partitioning by time (hourly folders)
- Automatic retries if Azure is temporarily unavailable
- Scalable (add more tasks if needed)

---

## Key Takeaways

1. **Kafka Connect** = Framework for integrating Kafka with external systems

2. **Connectors** = Pre-built integrations (no code needed)

3. **Source connectors** import data TO Kafka

4. **Sink connectors** export data FROM Kafka

5. **Distributed mode** for production (fault-tolerant)

6. **100+ connectors** available (databases, cloud, search, etc.)

---

## What's Next?

Learn about the differences between source and sink connectors!

**→ Next: [Source vs Sink Connectors](02-source-vs-sink.md)**

---

## 🤔 Self-Check Questions

1. What problem does Kafka Connect solve?
2. What's the difference between a connector and a task?
3. When would you use standalone vs distributed mode?
4. Name three benefits of using Kafka Connect vs writing custom code.

---
