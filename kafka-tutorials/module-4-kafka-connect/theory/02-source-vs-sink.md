# Source vs Sink Connectors

## 📖 Reading Time: 7 minutes

---

## Overview

Kafka Connect has two types of connectors:
1. **Source Connectors** - Import data TO Kafka
2. **Sink Connectors** - Export data FROM Kafka

---

## Source Connectors (Import TO Kafka)

### Purpose

Continuously import data from external systems into Kafka topics.

### Data Flow

```
External System → Source Connector → Kafka Topic
```

### Common Examples

**1. Database Source (JDBC)**
```
PostgreSQL table → JDBC Source Connector → Kafka topic
```

**2. File Source**
```
Log files → File Source Connector → Kafka topic
```

**3. Change Data Capture (Debezium)**
```
MySQL binlog → Debezium Connector → Kafka topic
```

---

## Sink Connectors (Export FROM Kafka)

### Purpose

Continuously export data from Kafka topics to external systems.

### Data Flow

```
Kafka Topic → Sink Connector → External System
```

### Common Examples

**1. Azure Blob Storage Sink**
```
Kafka topic → Azure Blob Sink → Azure Blob Storage
```

**2. Elasticsearch Sink**
```
Kafka topic → Elasticsearch Sink → Elasticsearch index
```

**3. JDBC Sink**
```
Kafka topic → JDBC Sink → Database table
```

---

## Comparison

| Aspect | Source Connector | Sink Connector |
|--------|------------------|----------------|
| **Direction** | External → Kafka | Kafka → External |
| **Role** | Producer | Consumer |
| **Reads from** | External system | Kafka topics |
| **Writes to** | Kafka topics | External system |
| **Example** | Database → Kafka | Kafka → S3 |

---

## Azure Blob Storage Sink Connector

### What We'll Use

In this module, we'll use the **Azure Blob Storage Sink Connector** to export processed vehicle data to the cloud.

### Configuration

```json
{
  "name": "azure-blob-sink",
  "config": {
    "connector.class": "AzureBlobStorageSinkConnector",
    "topics": "vehicle.speeding,vehicle.lowfuel",
    "azblob.account.name": "YOUR_ACCOUNT",
    "azblob.account.key": "YOUR_KEY",
    "azblob.container.name": "vehicle-data",
    "format.class": "JsonFormat",
    "flush.size": "10"
  }
}
```

### Features

- **Time-based partitioning:** year=2024/month=11/day=10/hour=14/
- **Format options:** JSON, Avro, Parquet
- **Automatic batching:** Groups messages for efficiency
- **Error handling:** Retries, dead letter queue

---

## Key Takeaways

1. **Source connectors** import TO Kafka
2. **Sink connectors** export FROM Kafka
3. **Azure Blob Sink** exports to cloud storage
4. **Time-partitioning** organizes data by date/time

---

**→ Next: [Connector Configuration](03-connector-configuration.md)**
