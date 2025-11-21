# Quick Start Guide - Kafka Tutorials

## Project Overview

This tutorial teaches you to build a **Real-Time Vehicle Fleet Monitoring System**:

```
Vehicle Simulator → Kafka → ksqlDB → Kafka Connect → Azure Blob → ADF → Synapse
     (Python)      (Events)  (Stream)   (Export)      (Storage)   (ETL)  (DW)
```

**What You'll Learn:**
- Apache Kafka fundamentals
- Real-time stream processing with ksqlDB
- Data integration with Kafka Connect
- Cloud data warehousing with Azure Synapse

---

## Module Learning Path

| Order | Module | Duration | Prerequisites |
|-------|--------|----------|---------------|
| 1 | Kafka Fundamentals | 60 min | Docker installed |
| 2 | Producers & Consumers | 75 min | Module 1 |
| 3 | Stream Processing | 90 min | Module 2 |
| 4 | Kafka Connect & ADF | 90 min | Module 3 + Azure account |
| 5 | Monitoring & Operations | 45 min | Module 4 |
| 6 | Complete Pipeline | 85 min | All previous modules |

---

## Quick Setup Sequence

### Step 1: Environment Setup
```bash
# Verify Docker
docker --version
docker compose version
python3 --version
```

### Step 2: Start Kafka (Module 1)
```bash
cd module-1-kafka-fundamentals/lab
docker compose up -d
```

### Step 3: Run Vehicle Simulator (Module 2)
```bash
cd module-2-producers-consumers/lab
pip install -r requirements.txt
python vehicle_simulator.py
```

### Step 4: Create ksqlDB Streams (Module 3)
```bash
docker exec -it ksqldb-cli ksql http://ksqldb-server:8088
# Run queries from module-3-stream-processing/lab/ksql-queries/
```

### Step 5: Configure Kafka Connect (Module 4)
```bash
# Deploy Azure Blob connector
curl -X POST http://localhost:8083/connectors -d @connectors/azure-blob-sink.json
```

### Step 6: Deploy Azure Resources (Module 4)
```bash
# Use ARM templates in module-4-kafka-connect/lab/arm-templates/
az deployment group create --template-file main-template.json
```

### Step 7: Run ADF Pipelines (Module 4)
- Import pipelines from `module-4-kafka-connect/lab/adf-pipelines/`
- Configure linked services for Blob Storage and Synapse
- Run `pl_IngestTelemetryToSynapse` pipeline

### Step 8: Create Synapse Schema (Module 6)
```sql
-- Run scripts in order from module-6-complete-pipeline/lab/synapse-scripts/
-- 01-create-schema.sql
-- 02-create-tables.sql
-- 03-stored-procedures.sql
-- 04-create-views.sql
```

---

## Data Flow Explained

```
1. GENERATE    → Python simulator creates vehicle telemetry (GPS, speed, fuel, temp)
2. INGEST      → Kafka broker receives events into vehicle.telemetry topic
3. PROCESS     → ksqlDB filters alerts (speeding, low fuel, overheating)
4. EXPORT      → Kafka Connect writes to Azure Blob Storage (Parquet)
5. ORCHESTRATE → ADF pipelines copy data on schedule/events
6. WAREHOUSE   → Synapse stores data in star schema for analytics
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Starts Kafka stack (broker, ksqlDB, Connect, Control Center) |
| `vehicle_simulator.py` | Generates fake telemetry for 10 vehicles |
| `ksql-queries/*.sql` | Stream processing queries (alerts, aggregations) |
| `connectors/*.json` | Kafka Connect configurations |
| `arm-templates/*.json` | Azure resource deployment templates |
| `adf-pipelines/*.json` | Azure Data Factory pipeline definitions |
| `synapse-scripts/*.sql` | Data warehouse schema and ETL procedures |

---

## Accessing Components

| Component | URL | Purpose |
|-----------|-----|---------|
| Control Center | http://localhost:9021 | Monitor Kafka cluster |
| ksqlDB | http://localhost:8088 | Stream processing |
| Kafka Connect | http://localhost:8083 | Connector management |
| Schema Registry | http://localhost:8081 | Schema management |

---

## Next Steps

1. Start with [Module 1](../module-1-kafka-fundamentals/) for Kafka basics
2. Each module has its own `README.md` with detailed instructions
3. Check [reference/troubleshooting.md](../reference/troubleshooting.md) for common issues
