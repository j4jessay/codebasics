# Architecture Documentation

## Azure Kafka ETL Architecture - Data Engineering Pipeline

This directory contains the reference architecture diagram for a **data engineering pipeline** that processes vehicle fleet telemetry data using Apache Kafka and Azure cloud services. The pipeline ingests, transforms, and loads data into a cloud data warehouse, ready for downstream analytics and BI consumption.

---

## Diagram Files

### `azure-kafka-etl-architecture.drawio`
**Format:** draw.io XML
**Tool:** Open with [diagrams.net](https://app.diagrams.net/) or draw.io desktop app
**Purpose:** Editable architecture diagram showing the complete data pipeline

### `azure-kafka-etl-architecture.png` (To be exported)
**Format:** PNG image
**Purpose:** Static image for documentation and presentations

---

## Architecture Overview

### 🎯 System Purpose
**Data Engineering pipeline** for vehicle fleet monitoring that ingests, processes, and loads telemetry data into a cloud data warehouse using:
- **Streaming layer**: Apache Kafka + ksqlDB
- **Integration layer**: Kafka Connect + Azure Data Factory
- **Storage layer**: Azure Blob Storage (Data Lake - Bronze/Silver)
- **Warehouse layer**: Azure Synapse Analytics (Gold layer)

**Output**: Curated data warehouse ready for consumption by BI tools, analysts, and data scientists

---

## Architecture Layers

### 1️⃣ Data Ingestion Layer
**Components:**
- Python vehicle simulators (10 vehicles)
- Apache Kafka cluster (3 partitions per topic)
- ksqlDB for real-time stream processing

**Data Flow:**
- **Input**: 5 messages/second (10 vehicles × 0.5 msg/sec)
- **Format**: JSON events with vehicle telemetry
- **Topics**: `vehicle.telemetry`, `speeding`, `lowfuel`, `overheating`, `vehicle_stats_1min`

**Real-time Processing:**
- Speed-based filtering (speed > 80 km/h)
- Fuel level alerts (fuel < 15%)
- Temperature warnings (temp > 100°C)
- 1-minute windowed aggregations

---

### 2️⃣ Data Integration Layer
**Components:**
- Kafka Connect (Azure Blob sink connector)
- Azure Blob Storage (Bronze layer - raw data)
- Azure Data Factory (ETL orchestration)
- Optional: Silver layer (cleaned/validated data)

**Data Flow:**
- **Kafka Connect**: Exports Parquet files every 5 minutes
- **Partitioning**: `/year/month/day/hour/` folder structure
- **ADF Pipelines**:
  - Copy activity: Blob → Synapse
  - Data transformations (optional)
  - Scheduled triggers (daily batch)
  - Event-based triggers (file arrival)

**Data Quality:**
- Schema validation
- Null value handling
- Data type conversions
- Duplicate detection

---

### 3️⃣ Data Warehouse Layer (Final DE Output)
**Components:**
- Azure Synapse Analytics (Dedicated SQL Pool)
- Star schema data model
- Materialized views and aggregates

**This is the endpoint of the Data Engineering pipeline** - all data is curated, validated, and ready for downstream consumption.

**Schema Design:**

**Fact Table:**
```sql
dbo.FactVehicleTelemetry
├── TelemetryKey (PK)
├── VehicleKey (FK)
├── DateTimeKey (FK)
├── LocationKey (FK)
├── Speed
├── FuelLevel
├── EngineTemp
└── RecordedTimestamp
```

**Dimension Tables:**
```sql
dbo.DimVehicle
├── VehicleKey (PK)
├── VehicleID
├── VehicleType
├── Model
└── RegistrationDate

dbo.DimDateTime
├── DateTimeKey (PK)
├── Date
├── Hour
├── DayOfWeek
└── Month

dbo.DimLocation
├── LocationKey (PK)
├── Latitude
├── Longitude
├── City
└── Region
```

**Aggregate Views (DE creates these for downstream users):**
- `vw_VehicleMetrics` - Current status of all vehicles
- `vw_IdleVehicles` - Vehicles idle > 30 minutes
- `vw_DailyStats` - Daily aggregated statistics

**Downstream Consumption:**
After data is loaded into Synapse, it can be consumed by:
- BI tools (Power BI, Tableau, etc.)
- Data analysts (SQL queries)
- Data scientists (notebooks, ML models)
- Reporting systems
- APIs and applications

---

## Data Flow Summary

```
┌──────────────────────────────────────────────────────────────────┐
│ Data Engineering Pipeline - End-to-End Flow                      │
└──────────────────────────────────────────────────────────────────┘

Real-time Stream Processing:
Python Producers → Kafka → ksqlDB → Alert Topics

Batch Data Warehouse Loading:
Kafka → Kafka Connect → Blob (Bronze) → ADF → Synapse (Gold)
                                                    ↓
                                        [Ready for BI/Analytics]
```

**Pipeline Characteristics:**
- **Real-time latency**: < 5 seconds (stream processing)
- **Batch latency**: 15-30 minutes (warehouse loading)
- **Data freshness**: 5-minute micro-batches (Kafka Connect)

---

## Key Metrics

### Data Volume
| Metric | Value |
|--------|-------|
| **Streaming throughput** | 5 messages/sec |
| **Daily raw data** | ~200 MB/day |
| **Kafka retention** | 7 days |
| **Synapse retention** | Unlimited (configurable) |
| **Blob storage growth** | ~6 GB/month |

### Latency
| Pipeline Stage | Latency |
|----------------|---------|
| **Producer → Kafka** | < 100 ms |
| **ksqlDB processing** | < 5 seconds |
| **Kafka → Blob export** | 5 minutes (batch interval) |
| **ADF batch load** | 15-30 minutes |
| **Data warehouse ready** | End of DE pipeline |

### Cost Estimate (Lab Scale - DE Infrastructure Only)
| Service | Monthly Cost (USD) |
|---------|-------------------|
| **Kafka cluster** | Self-hosted (Docker - free) |
| **Azure Blob Storage** | $2-5 (6 GB) |
| **Azure Data Factory** | $10-20 (pipeline runs) |
| **Azure Synapse** | $30-60 (DW-100c, 8 hrs/day) |
| **Total (DE pipeline)** | **$45-85/month** |

**Note**: BI tools (Power BI, Tableau, etc.) are separate and used by analysts/business users.

💡 **Cost optimization tips:**
- Pause Synapse SQL pool when not in use
- Use serverless SQL pool for dev/test
- Implement lifecycle policies on Blob Storage
- Use consumption-based ADF pricing

---

## Technology Stack

### Open Source
- **Apache Kafka** 7.5.0 - Event streaming platform
- **ksqlDB** 0.29.0 - Stream processing engine
- **Kafka Connect** 7.5.0 - Data integration framework
- **Python** 3.8+ - Application development
- **Docker & Docker Compose** - Container orchestration

### Azure Services (Data Engineering Stack)
- **Azure Blob Storage** - Data Lake (Bronze/Silver layers)
- **Azure Data Factory** - ETL orchestration
- **Azure Synapse Analytics** - Cloud data warehouse (Gold layer)
- **Azure Monitor** - Pipeline observability & monitoring

---

## Monitoring & Operations

### Kafka Monitoring (Confluent Control Center)
- Broker health & resource usage
- Topic throughput & latency
- Consumer lag tracking
- ksqlDB query performance
- Kafka Connect task status

### Azure Monitoring (Azure Monitor)
- ADF pipeline success/failure rates
- Data movement activity duration
- Synapse query performance
- Resource utilization & costs
- Alert rules for failures

---

## Security Considerations

### Data in Transit
- Kafka: SSL/TLS encryption (production)
- Azure: HTTPS for all API calls
- Private endpoints for Synapse (optional)

### Data at Rest
- Blob Storage: Server-side encryption (SSE)
- Synapse: Transparent Data Encryption (TDE)
- Backup & disaster recovery policies






---

## How to Use This Diagram

### Viewing the Diagram
1. **Online (Recommended)**:
   - Go to [diagrams.net](https://app.diagrams.net/)
   - Click "Open Existing Diagram"
   - Select `azure-kafka-etl-architecture.drawio`

