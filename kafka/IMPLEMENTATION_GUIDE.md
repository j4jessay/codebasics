# Vehicle IoT Real-Time Streaming Analytics
## Complete Implementation Guide

This guide provides **step-by-step instructions** to implement a real-time vehicle telemetry streaming pipeline using Kafka, ksqlDB, and Azure Blob Storage.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Project Overview](#project-overview)
3. [Implementation Steps](#implementation-steps)
4. [Verification & Troubleshooting](#verification--troubleshooting)
5. [Azure Blob Storage Setup](#azure-blob-storage-setup)
6. [Power BI Dashboard](#power-bi-dashboard)
7. [Cleanup](#cleanup)

---

## Prerequisites

### Required Software
- ✅ **Docker Desktop** (installed and running)
- ✅ **Python 3.8+** (with pip)
- ✅ **Git** (for cloning repository)
- ✅ **Azure Account** (free tier is sufficient)
- ⚠️ **8GB RAM minimum** (Docker containers are resource-intensive)
- ⚠️ **20GB free disk space**

### Verify Docker Installation
```bash
docker --version
docker-compose --version
```

### Verify Python Installation
```bash
python --version
python3 --version
pip --version
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

## Implementation Steps

### STEP 1: Start Kafka Infrastructure

Navigate to the kafka directory:
```bash
cd kafka
```

Start all Docker containers:
```bash
docker-compose up -d
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

### STEP 3: Install Python Dependencies

Install the Kafka Python client:
```bash
pip install -r requirements.txt
```

Or manually:
```bash
pip install kafka-python==2.0.2
```

**Verify installation:**
```bash
python -c "import kafka; print(kafka.__version__)"
```

Expected output: `2.0.2`

---

### STEP 4: Start Vehicle IoT Simulator

Open a **new terminal window** and navigate to the kafka directory:
```bash
cd kafka
```

Start the producer:
```bash
python producer.py
```

**Expected output:**
```
🚀 Starting vehicle IoT simulator...
   Topic: vehicle.telemetry
   Vehicles: 10
   Rate: 2.0 msg/sec per vehicle
   Duration: Indefinite
======================================================================
✓ Connected to Kafka broker at localhost:9092
📡 VEH-0001: active | Speed: 45.23 km/h | Fuel: 78.5%
⚠️  VEH-0003: SPEEDING | Speed: 95.67 km/h | Fuel: 65.2% | Temp: 92.3°C
📡 VEH-0002: active | Speed: 52.10 km/h | Fuel: 82.1%
```

**⚠️ Keep this terminal running!** The producer continuously sends data to Kafka.

**Optional producer arguments:**
```bash
# Run for 5 minutes only
python producer.py --duration 300

# Increase message rate to 5 per second
python producer.py --rate 5.0

# Custom Kafka broker
python producer.py --broker localhost:9092

# Custom topic name
python producer.py --topic my.custom.topic
```

---

### STEP 5: Verify Data is Flowing to Kafka

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

### STEP 6: Setup ksqlDB Streams

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

### STEP 7: Verify ksqlDB Created Topics

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

### STEP 8: Setup Azure Blob Storage

#### 8.1 Create Azure Storage Account

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

#### 8.2 Get Access Keys

1. **Navigate to your storage account**
2. **Left menu** → Security + networking → **Access keys**
3. **Click "Show keys"**
4. **Copy the following:**
   - Storage account name: `vehicleiotdata<yourname>`
   - key1: `<long-string-of-characters>`

#### 8.3 Create Blob Container

1. **Left menu** → Data storage → **Containers**
2. **Click "+ Container"**
3. **Name**: `vehicle-telemetry-data`
4. **Public access level**: Private
5. **Click "Create"**

#### 8.4 Configure Connector Credentials

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

### STEP 9: Deploy Azure Blob Storage Connector

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

### STEP 10: Verify Data in Azure Blob Storage

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

### STEP 11: Monitor the Pipeline

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

#### Issue 1: Containers won't start
```bash
# Check Docker logs
docker-compose logs

# Check port conflicts
netstat -tulpn | grep -E '(9092|8088|8083|9021)'

# Stop conflicting services or change ports in docker-compose.yml
```

#### Issue 2: Producer can't connect to Kafka
```bash
# Verify Kafka is accessible
docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:29092

# Check if topic exists
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list

# Try alternative port
python producer.py --broker localhost:9092
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

# Reduce producer rate
python producer.py --rate 0.5

# Reduce number of vehicles in producer.py (edit file)

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

### Stop Producers
```bash
# In producer terminal, press Ctrl+C
```

### Stop Docker Containers
```bash
cd kafka
docker-compose down
```

### Remove Docker Volumes (complete reset)
```bash
docker-compose down -v
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

- [ ] Docker containers running (7 containers)
- [ ] Kafka accessible on port 9092
- [ ] Python producer sending data
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
2. Review Docker logs: `docker-compose logs`
3. Check Kafka Connect logs: `docker logs kafka-connect`
4. Review ksqlDB logs: `docker logs ksqldb-server`
5. Open an issue in this repository

---

**🎉 Congratulations!** You've successfully built an end-to-end real-time streaming analytics pipeline!
