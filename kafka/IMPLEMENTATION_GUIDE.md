# Vehicle IoT Real-Time Streaming Analytics
## Complete Implementation Guide

This guide provides **step-by-step instructions** to implement a real-time vehicle telemetry streaming pipeline using Kafka, ksqlDB, and Azure Blob Storage.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Compatibility](#architecture-compatibility)
3. [Project Overview](#project-overview)
4. [Understanding the Data Pipeline](#understanding-the-data-pipeline)
5. [Environment Options](#environment-options)
6. [Implementation Steps](#implementation-steps)
7. [Verification & Troubleshooting](#verification--troubleshooting)
8. [Azure Blob Storage Setup](#azure-blob-storage-setup)
9. [Power BI Dashboard](#power-bi-dashboard)
10. [Cleanup](#cleanup)

---

## Prerequisites

### Required Software
- ✅ **Docker Desktop** (installed and running)
- ✅ **Git** (for cloning repository)
- ✅ **Azure Account** (free tier is sufficient)
- ⚠️ **8GB RAM minimum** (Docker containers are resource-intensive)
- ⚠️ **20GB free disk space**

### Verify Docker Installation
```bash
docker --version
docker compose version
```

### Check Your System Architecture
```bash
uname -m
```

**Expected output:**
- `x86_64` or `amd64` - ✅ Full compatibility
- `arm64` or `aarch64` - ⚠️ Partial compatibility (see Architecture Compatibility section below)

---

## Architecture Compatibility

### ⚠️ Important: Azure Blob Storage Connector Requirements

The **Azure Blob Storage Sink Connector** requires **Linux x86_64** architecture. If you're running on:

| Your System | Architecture | Status | Recommended Solution |
|-------------|-------------|--------|----------------------|
| **Mac Intel** | x86_64 | ✅ Full support | Run locally |
| **Mac M1/M2/M3** | ARM64 | ⚠️ Partial support | Use GitHub Codespaces |
| **Windows Intel/AMD** | x86_64 | ✅ Full support | Run locally |
| **Windows ARM** | ARM64 | ⚠️ Partial support | Use GitHub Codespaces |
| **Linux x86_64** | x86_64 | ✅ Full support | Run locally |
| **Linux ARM64** | ARM64 | ⚠️ Partial support | Use cloud VM |

### What Works on ARM64 (Mac M1/M2/M3)?

✅ **Fully Functional:**
- Kafka broker and message streaming
- ksqlDB Server and stream processing
- Producer and data generation
- Schema Registry
- Control Center UI

❌ **Does NOT Work:**
- Azure Blob Storage Connector (native library incompatibility)
- Data export to Azure Blob Storage

### Why This Happens

The Azure connector uses an older networking library (Netty) that is hardcoded for x86_64 Linux. When it tries to run on ARM64:

```
Connector attempts to load: libnetty_transport_native_epoll_x86_64.so
Your Mac has: ARM64 architecture (no x86_64 libraries)
Result: UnsatisfiedLinkError → Connector FAILED
```

### Your Options

**Option 1: GitHub Codespaces (Recommended - FREE)**
- ✅ Free 60 hours/month
- ✅ Linux x86_64 in the cloud
- ✅ Everything works perfectly
- ✅ [See CODESPACES.md](./CODESPACES.md) for setup

**Option 2: Azure Virtual Machine**
- ✅ Production-like environment
- ✅ Same Azure region as Blob Storage (faster)
- 💰 ~$15-30/month (can stop when not using)

**Option 3: Local Testing (ARM64)**
- ✅ Test Kafka, ksqlDB, Producer locally
- ❌ Skip Azure Blob Storage connector
- ✅ Learn core concepts without Azure integration

### Decision Matrix

```
┌─────────────────────────────────────────────────────────────┐
│ Goal: Learn Kafka/ksqlDB Only                              │
│ ├─► Run locally on Mac (ARM64)                             │
│ └─► Skip Step 8 (Azure connector deployment)               │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Goal: Complete End-to-End Pipeline with Azure              │
│ ├─► Mac M1/M2/M3: Use GitHub Codespaces (FREE)            │
│ ├─► Mac Intel: Run locally                                 │
│ └─► Production: Azure VM (Linux x86_64)                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Project Overview

### Architecture
```
Python Simulator → Kafka → ksqlDB → Kafka Connect → Azure Blob Storage → Power BI
```

### Components
| Component | Purpose | Port |
|-----------|---------|------|
| **Zookeeper** | Kafka coordination | 2181 |
| **Kafka Broker** | Message streaming | 9092, 29092 |
| **ksqlDB Server** | Stream processing | 8088 |
| **Kafka Connect** | Azure integration | 8083 |
| **Schema Registry** | Schema management | 8081 |
| **Control Center** | Monitoring UI | 9021 |

### Data Topics
- `vehicle.telemetry` - Raw vehicle data
- `vehicle.speeding` - Speeding alerts (>80 km/h)
- `vehicle.lowfuel` - Low fuel alerts (<15%)
- `vehicle.overheating` - Engine overheating alerts (>100°C)
- `vehicle.alerts.all` - Combined alerts
- `vehicle.stats.1min` - 1-minute aggregated statistics

---

## Understanding the Data Pipeline

### Three-Component Architecture

The pipeline consists of **THREE separate but connected components** that must ALL be running:

```
┌──────────────────────────────────────────────────────────────────┐
│ Component 1: INFRASTRUCTURE                                      │
│ Command: docker compose up -d                                    │
│                                                                   │
│ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐               │
│ │  Zookeeper  │  │    Kafka    │  │   ksqlDB    │               │
│ └─────────────┘  └─────────────┘  └─────────────┘               │
│ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐               │
│ │ Kafka       │  │   Schema    │  │   Control   │               │
│ │ Connect     │  │  Registry   │  │   Center    │               │
│ └─────────────┘  └─────────────┘  └─────────────┘               │
│                                                                   │
│ Status: Creates the "highway system" for data to flow            │
│ At this point: NO DATA is flowing yet!                           │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ Component 2: CONNECTOR CONFIGURATION                             │
│ Command: scripts/deploy_azure_connector.sh                       │
│                                                                   │
│ ┌─────────────────────────────────────────────────────────────┐  │
│ │  Kafka Connect Connector                                    │  │
│ │  - Which topics to read from                                │  │
│ │  - Where to write (Azure Blob Storage)                      │  │
│ │  - Azure credentials                                        │  │
│ │  - Data format and partitioning rules                       │  │
│ └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│ Status: Connector is WAITING for data                            │
│ At this point: Still NO DATA flowing!                            │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ Component 3: DATA PRODUCER                                       │
│ Command: docker compose --profile producer up producer           │
│                                                                   │
│ ┌─────────────────────────────────────────────────────────────┐  │
│ │  Vehicle IoT Simulator (producer.py)                        │  │
│ │  - Generates vehicle telemetry data                         │  │
│ │  - Sends to Kafka every 2 seconds                           │  │
│ │  - Simulates 10 vehicles                                    │  │
│ └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│ Status: NOW data flows through the entire pipeline!              │
│ At this point: Data → Kafka → ksqlDB → Connect → Azure ✅        │
└──────────────────────────────────────────────────────────────────┘
```

### Why Is the Producer Separate?

You might notice the producer uses a special command: `docker compose --profile producer up`

This is intentional because:

1. **Infrastructure First**: Kafka and ksqlDB need time to start up completely (~60 seconds)
2. **Testing Flexibility**: You can test ksqlDB queries without generating new data
3. **Resource Control**: The producer runs continuously and can consume resources
4. **Manual Control**: You decide WHEN to start generating data

### Complete Data Flow

```
1. Producer generates telemetry
   └─► {"vehicle_id": "VEH-001", "speed_kmph": 95.5, ...}
        │
        ▼
2. Kafka stores in topic
   └─► Topic: vehicle.telemetry
        │
        ▼
3. ksqlDB processes streams
   ├─► Filter: speed > 80 → vehicle.speeding topic
   ├─► Filter: fuel < 15 → vehicle.lowfuel topic
   └─► Filter: temp > 100 → vehicle.overheating topic
        │
        ▼
4. Kafka Connect reads topics
   └─► Reads: vehicle.speeding, vehicle.lowfuel, vehicle.overheating
        │
        ▼
5. Azure Blob Storage
   └─► Files: year=2025/month=11/day=09/hour=15/vehicle_data.json
```

### What Happens If You Skip a Component?

| Missing Component | Result |
|-------------------|--------|
| **Infrastructure** | Nothing runs - no Kafka, no topics |
| **Connector** | Data stays in Kafka, never reaches Azure |
| **Producer** | Empty topics, connector has nothing to send |

**All three must run for end-to-end data flow!**

---

## Environment Options

### Option A: Local Development (Mac ARM64 - Partial)

**What to use this for:**
- Learning Kafka concepts
- Testing ksqlDB queries
- Developing producer logic
- Understanding stream processing

**Steps:**
1. Run infrastructure: `docker compose up -d` ✅
2. Start producer: `docker compose --profile producer up` ✅
3. Test ksqlDB queries ✅
4. **SKIP** Azure connector deployment (won't work on ARM64) ❌

**Limitations:**
- No Azure Blob Storage integration
- Connector will FAIL if attempted

---

### Option B: GitHub Codespaces (Full Pipeline - FREE)

**What to use this for:**
- Complete end-to-end pipeline
- Azure Blob Storage integration
- Production-like environment
- Learning full data flow

**Setup (5 minutes):**
1. Go to: https://github.com/j4jessay/codebasics
2. Click: Code → Codespaces → Create codespace
3. Wait 2-3 minutes for setup
4. See [CODESPACES.md](./CODESPACES.md) for detailed instructions

**Benefits:**
- ✅ Everything works (x86_64 architecture)
- ✅ Free 60 hours/month
- ✅ No local resource usage
- ✅ Browser-based or VS Code
- ✅ Production-like environment

**Quickstart in Codespaces:**
```bash
cd kafka
docker compose up -d                           # Start infrastructure
scripts/deploy_azure_connector.sh              # Deploy connector ✅ WORKS!
docker compose --profile producer up producer  # Start producer
```

---

## Implementation Steps

### STEP 1: Start Kafka Infrastructure

Navigate to the kafka directory:
```bash
cd kafka
```

Start all Docker containers:
```bash
docker compose up -d
```

**Expected output:**
```
✔ Container zookeeper         Started
✔ Container kafka             Started
✔ Container schema-registry   Started
✔ Container ksqldb-server     Started
✔ Container kafka-connect     Started
✔ Container ksqldb-cli        Started
✔ Container control-center    Started
```

**⏱️ Wait time:** 2-3 minutes for all services to initialize

Verify all containers are running:
```bash
docker ps
```

You should see 7 containers running.

---

### STEP 2: Verify Kafka Setup

Run the verification script:
```bash
bash scripts/verify_setup.sh
```

**Key checkpoints:**
- ✅ All 7 containers running
- ✅ Kafka accessible on port 9092
- ✅ ksqlDB Server responding on port 8088
- ✅ Kafka Connect responding on port 8083
- ✅ Control Center UI accessible at http://localhost:9021

**Optional:** Access Control Center UI:
```
Open browser: http://localhost:9021
```

---

### STEP 3: Start Vehicle IoT Simulator

**Note:** The producer uses a Docker Compose profile, so it requires a special command.

Build and start the producer container:
```bash
docker compose --profile producer up producer
```

**Why `--profile producer`?**
The producer is intentionally separated so you can:
- Start infrastructure first (Kafka needs ~60 seconds to be ready)
- Test ksqlDB queries without generating new data
- Control when data generation begins

**Expected output:**
```
[+] Running 1/1
 ✔ Container producer  Started
Attaching to producer
producer  | 🚀 Starting vehicle IoT simulator...
producer  |    Topic: vehicle.telemetry
producer  |    Vehicles: 10
producer  |    Rate: 2.0 msg/sec per vehicle
producer  |    Duration: Indefinite
producer  | ======================================================================
producer  | ✓ Connected to Kafka broker at kafka:29092
producer  | 📡 VEH-0001: active | Speed: 45.23 km/h | Fuel: 78.5%
producer  | ⚠️  VEH-0003: SPEEDING | Speed: 95.67 km/h | Fuel: 65.2% | Temp: 92.3°C
producer  | 📡 VEH-0002: active | Speed: 52.10 km/h | Fuel: 82.1%
```

**⚠️ Keep this terminal running!** The producer continuously sends data to Kafka.

**To run producer in detached mode (background):**
```bash
docker compose --profile producer up -d producer
```

**To view producer logs:**
```bash
docker logs producer -f
```

**To stop the producer:**
```bash
docker compose stop producer
```

**⚠️ Note:** If you see "no configuration file provided", make sure you're in the `kafka/` directory.

---

### STEP 4: Verify Data is Flowing to Kafka

Open a **new terminal window**.

Check if the topic was created:
```bash
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list
```

You should see: `vehicle.telemetry`

Consume messages from the topic (Ctrl+C to stop):
```bash
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic vehicle.telemetry \
  --from-beginning \
  --max-messages 5
```

**Expected output (JSON messages):**
```json
{"vehicle_id":"VEH-0001","timestamp_utc":"2024-11-06T12:34:56.789Z","location":{"lat":28.5234,"lon":77.1234},"speed_kmph":45.23,"fuel_percent":78.5,"engine_temp_c":88.2,"status":"active"}
```

---

### STEP 5: Setup ksqlDB Streams

Access the ksqlDB CLI:
```bash
docker exec -it ksqldb-cli ksql http://ksqldb-server:8088
```

You should see:
```
                  ===========================================
                  =       _              _ ____  ____       =
                  =      | | _____  __ _| |  _ \| __ )      =
                  =      | |/ / __|/ _` | | | | |  _ \      =
                  =      |   <\__ \ (_| | | |_| | |_) |     =
                  =      |_|\_\___/\__, |_|____/|____/      =
                  =                   |_|                   =
                  =  Event Streaming Database purpose-built =
                  =        for stream processing apps       =
                  ===========================================

ksql>
```

**Now run the setup script** (copy-paste the entire contents of `scripts/ksqldb_setup.sql` line by line or in blocks):

#### Create Base Stream:
```sql
SET 'auto.offset.reset' = 'earliest';

CREATE STREAM vehicle_stream (
  vehicle_id VARCHAR,
  timestamp_utc VARCHAR,
  location STRUCT<lat DOUBLE, lon DOUBLE>,
  speed_kmph DOUBLE,
  fuel_percent DOUBLE,
  engine_temp_c DOUBLE,
  status VARCHAR
) WITH (
  KAFKA_TOPIC='vehicle.telemetry',
  VALUE_FORMAT='JSON',
  PARTITIONS=1
);
```

**Expected output:**
```
 Message
----------------
 Stream created
----------------
```

#### Create Speeding Alert Stream:
```sql
CREATE STREAM speeding_stream
WITH (
  KAFKA_TOPIC='vehicle.speeding',
  VALUE_FORMAT='JSON',
  PARTITIONS=1
) AS
SELECT
  vehicle_id,
  speed_kmph,
  timestamp_utc,
  location,
  'SPEEDING_ALERT' AS alert_type
FROM vehicle_stream
WHERE speed_kmph > 80
EMIT CHANGES;
```

#### Create Low Fuel Alert Stream:
```sql
CREATE STREAM lowfuel_stream
WITH (
  KAFKA_TOPIC='vehicle.lowfuel',
  VALUE_FORMAT='JSON',
  PARTITIONS=1
) AS
SELECT
  vehicle_id,
  fuel_percent,
  timestamp_utc,
  location,
  'LOW_FUEL_ALERT' AS alert_type
FROM vehicle_stream
WHERE fuel_percent < 15
EMIT CHANGES;
```

#### Create Overheating Alert Stream:
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
  location,
  'OVERHEATING_ALERT' AS alert_type
FROM vehicle_stream
WHERE engine_temp_c > 100
EMIT CHANGES;
```

#### Create Aggregated Statistics Table:
```sql
CREATE TABLE vehicle_stats_1min
WITH (
  KAFKA_TOPIC='vehicle.stats.1min',
  VALUE_FORMAT='JSON',
  PARTITIONS=1
) AS
SELECT
  vehicle_id,
  COUNT(*) AS event_count,
  AVG(speed_kmph) AS avg_speed,
  MAX(speed_kmph) AS max_speed,
  MIN(fuel_percent) AS min_fuel,
  AVG(engine_temp_c) AS avg_engine_temp,
  MAX(engine_temp_c) AS max_engine_temp
FROM vehicle_stream
WINDOW TUMBLING (SIZE 1 MINUTE)
GROUP BY vehicle_id
EMIT CHANGES;
```

#### Verify Streams and Tables:
```sql
SHOW STREAMS;
SHOW TABLES;
```

**Expected output:**
```
 Stream Name         | Kafka Topic         | Format
----------------------------------------------------------------
 VEHICLE_STREAM      | vehicle.telemetry   | JSON
 SPEEDING_STREAM     | vehicle.speeding    | JSON
 LOWFUEL_STREAM      | vehicle.lowfuel     | JSON
 OVERHEATING_STREAM  | vehicle.overheating | JSON
```

#### Query Live Data (Optional):
```sql
-- View raw vehicle data (Ctrl+C to stop)
SELECT * FROM vehicle_stream EMIT CHANGES LIMIT 5;

-- View speeding alerts (Ctrl+C to stop)
SELECT * FROM speeding_stream EMIT CHANGES LIMIT 5;

-- View low fuel alerts (Ctrl+C to stop)
SELECT * FROM lowfuel_stream EMIT CHANGES LIMIT 5;
```

Exit ksqlDB CLI:
```sql
exit;
```

---

### STEP 6: Verify ksqlDB Created Topics

Check all topics created by ksqlDB:
```bash
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list
```

**You should see:**
```
vehicle.telemetry
vehicle.speeding
vehicle.lowfuel
vehicle.overheating
vehicle.stats.1min
```

Check messages in speeding topic:
```bash
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic vehicle.speeding \
  --from-beginning \
  --max-messages 5
```

---

### STEP 7: Setup Azure Blob Storage

#### 7.1 Create Azure Storage Account

1. **Login to Azure Portal**: https://portal.azure.com

2. **Create Storage Account:**
   - Click "Create a resource"
   - Search for "Storage Account"
   - Click "Create"

3. **Fill in details:**
   - **Subscription**: Your subscription
   - **Resource Group**: Create new → "vehicle-iot-rg"
   - **Storage Account Name**: `vehicleiotdata<yourname>` (must be globally unique, lowercase, no hyphens)
   - **Region**: Select nearest region (e.g., East US)
   - **Performance**: Standard
   - **Redundancy**: LRS (Locally Redundant Storage) - cheapest option

4. **Click "Review + Create"** → **Create**

5. **Wait for deployment** (1-2 minutes)

#### 7.2 Get Access Keys

1. **Navigate to your storage account**
2. **Left menu** → Security + networking → **Access keys**
3. **Click "Show keys"**
4. **Copy the following:**
   - Storage account name: `vehicleiotdata<yourname>`
   - key1: `<long-string-of-characters>`

#### 7.3 Create Blob Container

1. **Left menu** → Data storage → **Containers**
2. **Click "+ Container"**
3. **Name**: `vehicle-telemetry-data`
4. **Public access level**: Private
5. **Click "Create"**

#### 7.4 Configure Connector Credentials

Create a credentials file:
```bash
cd kafka/config
cp azure-credentials.env.example azure-credentials.env
nano azure-credentials.env  # or use your preferred editor
```

**Fill in your Azure credentials:**
```bash
AZURE_STORAGE_ACCOUNT_NAME=vehicleiotdatayourname
AZURE_STORAGE_ACCOUNT_KEY=your_copied_access_key_here
AZURE_CONTAINER_NAME=vehicle-telemetry-data
```

**Save and exit.**

**Alternative:** Manually edit `config/azure-blob-sink.json`:
```json
"azblob.account.name": "vehicleiotdatayourname",
"azblob.account.key": "your_copied_access_key_here",
"azblob.container.name": "vehicle-telemetry-data",
```

---

### STEP 8: Deploy Azure Blob Storage Connector

Deploy the connector using the deployment script:
```bash
bash scripts/deploy_azure_connector.sh
```

**Expected output:**
```
============================================
Azure Blob Storage Connector Deployment
============================================
📋 Loading Azure credentials...
🔧 Updating configuration with environment variables...
⏳ Waiting for Kafka Connect to be ready...
✅ Kafka Connect is ready
🔍 Checking if connector already exists...
🚀 Deploying Azure Blob Storage Sink Connector...
✅ Connector deployed successfully!

Connector Details:
{
  "name": "azure-blob-sink-connector",
  "config": { ... },
  "tasks": [],
  "type": "sink"
}

📊 Checking connector status...
{
  "name": "azure-blob-sink-connector",
  "connector": {
    "state": "RUNNING",
    "worker_id": "kafka-connect:8083"
  },
  "tasks": [
    {
      "id": 0,
      "state": "RUNNING",
      "worker_id": "kafka-connect:8083"
    }
  ],
  "type": "sink"
}

============================================
✅ Deployment Complete!
============================================
```

**⚠️ Important:** Make sure the connector state is **"RUNNING"**

---

### STEP 9: Verify Data in Azure Blob Storage

#### Method 1: Azure Portal

1. **Go to Azure Portal** → Your storage account
2. **Navigate to**: Containers → `vehicle-telemetry-data`
3. **You should see folders** organized by date/time:
   ```
   year=2024/
     month=11/
       day=06/
         hour=12/
           vehicle.speeding+0+0000000000.json
           vehicle.lowfuel+0+0000000000.json
           vehicle.overheating+0+0000000000.json
   ```

4. **Click on a JSON file** to download and view the data

#### Method 2: Azure Storage Explorer (Desktop App)

1. Download Azure Storage Explorer: https://azure.microsoft.com/features/storage-explorer/
2. Connect using your account
3. Navigate to your storage account → Containers → `vehicle-telemetry-data`
4. Browse and download files

#### Method 3: Azure CLI

```bash
# Install Azure CLI (if not installed)
# Linux/Mac: https://docs.microsoft.com/cli/azure/install-azure-cli
# Windows: https://aka.ms/installazurecliwindows

# Login
az login

# List blobs
az storage blob list \
  --account-name vehicleiotdatayourname \
  --container-name vehicle-telemetry-data \
  --output table
```

**⏱️ Wait time:** 1-2 minutes after connector deployment for first files to appear

---

### STEP 10: Monitor the Pipeline

#### Check Kafka Connect Logs
```bash
docker logs kafka-connect --tail 100 -f
```

Look for:
- ✅ `Connector azure-blob-sink-connector config updated`
- ✅ `WorkerSinkTask{id=azure-blob-sink-connector-0} Sink task finished initialization and start`
- ✅ `Successfully committed offset`

#### Check Connector Status
```bash
curl http://localhost:8083/connectors/azure-blob-sink-connector/status | jq '.'
```

#### List All Topics
```bash
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list
```

#### Access Control Center UI
```
Open browser: http://localhost:9021
```

Navigate to:
- **Topics** → View message flow
- **Connect** → Monitor connector status
- **ksqlDB** → View streams and queries

---

## Verification & Troubleshooting

### Common Issues

#### Issue 1: Azure Blob Storage Connector FAILS on Mac M1/M2/M3 (ARM64)

**Symptoms:**
```bash
curl http://localhost:8083/connectors/azure-blob-sink-connector/status

{
  "connector": {"state": "RUNNING"},
  "tasks": [{
    "state": "FAILED",
    "trace": "java.lang.UnsatisfiedLinkError: failed to load the required native library..."
  }]
}
```

**Root Cause:**
The Azure connector requires x86_64 Linux architecture. Mac M1/M2/M3 use ARM64, which is incompatible.

**Solutions:**

**Option A: Use GitHub Codespaces (Recommended - FREE)**
1. Go to https://github.com/j4jessay/codebasics
2. Click Code → Codespaces → Create codespace
3. Run all steps in Codespaces (x86_64 environment)
4. See [CODESPACES.md](./CODESPACES.md) for details

**Option B: Skip Azure Integration (Learn Kafka/ksqlDB Only)**
1. Complete Steps 1-7 (everything except Azure connector)
2. Learn Kafka topics, ksqlDB queries, stream processing
3. Deploy connector later when you have x86_64 access

**Option C: Use Azure VM or EC2**
1. Create Linux x86_64 virtual machine
2. Install Docker
3. Clone repository and run there

**Verification:**
```bash
# Check your architecture
uname -m

# arm64 or aarch64 → Use Codespaces
# x86_64 or amd64 → Can run locally
```

---

#### Issue 2: Containers won't start
```bash
# Check Docker logs
docker compose logs

# Check port conflicts
netstat -tulpn | grep -E '(9092|8088|8083|9021)'

# Stop conflicting services or change ports in docker-compose.yml
```

#### Issue 2: Producer can't connect to Kafka
```bash
# Check producer logs
docker logs producer

# Verify Kafka is accessible
docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:29092

# Check if topic exists
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list

# Restart producer
docker compose restart producer
```

#### Issue 3: ksqlDB queries fail
```bash
# Check ksqlDB Server logs
docker logs ksqldb-server --tail 100

# Restart ksqlDB
docker restart ksqldb-server

# Verify Kafka connectivity from ksqlDB
docker exec -it ksqldb-cli ksql http://ksqldb-server:8088
ksql> SHOW TOPICS;
```

#### Issue 4: Connector fails to deploy
```bash
# Check Kafka Connect logs
docker logs kafka-connect --tail 100

# Verify connector plugin installed
curl http://localhost:8083/connector-plugins | jq '.'

# Look for: AzureBlobStorageSinkConnector

# Re-install connector plugin
docker exec kafka-connect confluent-hub install --no-prompt confluentinc/kafka-connect-azure-blob-storage:1.6.11
docker restart kafka-connect
```

#### Issue 5: No data in Azure Blob Storage
```bash
# Check connector status
curl http://localhost:8083/connectors/azure-blob-sink-connector/status | jq '.'

# Verify credentials in config
cat config/azure-blob-sink.json

# Check connector logs for errors
docker logs kafka-connect | grep -i error

# Verify topics have data
docker exec kafka kafka-console-consumer --bootstrap-server localhost:29092 --topic vehicle.speeding --from-beginning --max-messages 1

# Check connector configuration
curl http://localhost:8083/connectors/azure-blob-sink-connector | jq '.config'
```

#### Issue 6: High CPU/Memory usage
```bash
# Check resource usage
docker stats

# Stop producer temporarily
docker compose stop producer

# Modify producer configuration (reduce vehicles or rate)
# Edit producer.py, then rebuild:
docker compose build producer
docker compose up producer

# Increase Docker memory allocation (Docker Desktop → Settings → Resources)
```

---

## Power BI Dashboard

### Download Data from Azure Blob Storage

1. **Azure Portal** → Storage account → Containers → `vehicle-telemetry-data`
2. **Download JSON files** for each alert type:
   - `vehicle.speeding+0+*.json`
   - `vehicle.lowfuel+0+*.json`
   - `vehicle.overheating+0+*.json`

### Create Power BI Dashboard

1. **Open Power BI Desktop** (free download: https://powerbi.microsoft.com/desktop/)

2. **Get Data** → JSON → Select downloaded files

3. **Transform Data:**
   - Expand JSON records
   - Set data types (timestamp = DateTime, speed = Decimal, etc.)
   - Rename columns for clarity

4. **Create Visualizations:**

   **Page 1: Overview**
   - Card: Total Vehicles (Count Distinct vehicle_id)
   - Card: Total Alerts (Count rows)
   - Card: Avg Speed (Average speed_kmph)
   - Line Chart: Alerts over time
   - Table: Recent alerts

   **Page 2: Speeding Analysis**
   - Bar Chart: Speeding events by vehicle
   - Line Chart: Speed trends over time
   - Map: Speeding locations (lat/lon)
   - Gauge: Max speed recorded

   **Page 3: Fuel Monitoring**
   - Bar Chart: Low fuel events by vehicle
   - Line Chart: Fuel levels over time
   - Table: Vehicles needing refuel

   **Page 4: Map Visualization**
   - Map: All vehicle locations
   - Slicer: Filter by vehicle_id
   - Slicer: Filter by alert_type

5. **Refresh Data:**
   - Schedule manual refresh by re-importing updated JSON files
   - For automatic refresh, consider Azure Synapse or Databricks integration (advanced)

---

## Cleanup

### Stop Producer
```bash
docker compose stop producer
```

### Stop All Docker Containers
```bash
cd kafka
docker compose down
```

### Remove Docker Volumes (complete reset)
```bash
docker compose down -v
```

### Delete Azure Resources
1. **Azure Portal** → Resource Groups
2. **Select** `vehicle-iot-rg`
3. **Click** "Delete resource group"
4. **Type the resource group name** to confirm
5. **Click** "Delete"

---

## Next Steps & Enhancements

### Immediate Extensions:
1. **Add more alert types** (tire pressure, brake wear, etc.)
2. **Create aggregation tables** (hourly, daily statistics)
3. **Add multiple producers** (different geographic regions)
4. **Implement data enrichment** (weather, traffic data)

### Advanced Extensions:
1. **Azure Synapse Integration** - Data warehousing
2. **Azure Databricks** - Advanced analytics and ML
3. **Azure Event Hubs** - Managed Kafka service
4. **Stream ML Models** - Predictive maintenance
5. **Power BI Service** - Published dashboards (requires Pro license)
6. **Real-time Alerting** - Email/SMS notifications
7. **Multi-region deployment** - Global vehicle fleets

---

## Resources

### Documentation:
- **Apache Kafka**: https://kafka.apache.org/documentation/
- **ksqlDB**: https://docs.ksqldb.io/
- **Kafka Connect**: https://docs.confluent.io/platform/current/connect/
- **Azure Blob Storage**: https://docs.microsoft.com/azure/storage/blobs/
- **Power BI**: https://docs.microsoft.com/power-bi/

### Confluent Resources:
- **Kafka Tutorials**: https://developer.confluent.io/
- **ksqlDB Tutorials**: https://kafka-tutorials.confluent.io/
- **Connector Hub**: https://www.confluent.io/hub/

### Community:
- **Confluent Community**: https://forum.confluent.io/
- **Stack Overflow**: Tag `apache-kafka`, `ksqldb`
- **GitHub Issues**: This repository

---

## Summary Checklist

- [ ] Docker containers running (7 infrastructure containers)
- [ ] Kafka accessible on port 9092
- [ ] Producer container running and sending data
- [ ] Topics created: `vehicle.telemetry`, `vehicle.speeding`, `vehicle.lowfuel`, `vehicle.overheating`
- [ ] ksqlDB streams and tables created
- [ ] Azure Storage Account created
- [ ] Azure Blob Container created
- [ ] Kafka Connect connector deployed and RUNNING
- [ ] Data appearing in Azure Blob Storage
- [ ] Power BI dashboard created (optional)

---

## Support

For issues or questions:
1. Check the **Troubleshooting** section above
2. Review Docker logs: `docker compose logs`
3. Check Kafka Connect logs: `docker logs kafka-connect`
4. Review ksqlDB logs: `docker logs ksqldb-server`
5. Open an issue in this repository

---

**🎉 Congratulations!** You've successfully built an end-to-end real-time streaming analytics pipeline!
