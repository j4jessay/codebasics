# Quick Start Guide - Vehicle IoT Streaming Pipeline

This is a condensed version for experienced users. For detailed explanations, see [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md).

---

## Prerequisites
- Docker Desktop (running)
- Python 3.8+
- Azure Account (free tier)
- 8GB RAM, 20GB disk space

---

## Steps

### 1. Start Infrastructure
```bash
cd kafka
docker-compose up -d
```
⏱️ Wait 2-3 minutes for services to initialize.

### 2. Install Python Dependencies
```bash
pip install -r requirements.txt
```

### 3. Start Producer
```bash
python producer.py
```
Keep running in separate terminal.

### 4. Setup ksqlDB Streams
```bash
docker exec -it ksqldb-cli ksql http://ksqldb-server:8088
```

Copy-paste contents from `scripts/ksqldb_setup.sql` and run each statement.

Exit with `exit;`

### 5. Setup Azure Blob Storage

1. **Azure Portal** (portal.azure.com):
   - Create Storage Account: `vehicleiotdata<yourname>`
   - Create Container: `vehicle-telemetry-data`
   - Copy Access Keys

2. **Configure Credentials:**
```bash
cd config
cp azure-credentials.env.example azure-credentials.env
nano azure-credentials.env
```

Fill in:
```
AZURE_STORAGE_ACCOUNT_NAME=vehicleiotdatayourname
AZURE_STORAGE_ACCOUNT_KEY=your_access_key
AZURE_CONTAINER_NAME=vehicle-telemetry-data
```

### 6. Deploy Connector
```bash
bash scripts/deploy_azure_connector.sh
```

Verify status: `RUNNING`

### 7. Verify Data in Azure
Wait 1-2 minutes, then check:
- **Azure Portal** → Storage Account → Containers → `vehicle-telemetry-data`
- Look for folders: `year=2024/month=XX/day=XX/hour=XX/`

---

## Verification Commands

```bash
# Check all containers running
docker ps

# List Kafka topics
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list

# Consume messages
docker exec kafka kafka-console-consumer --bootstrap-server localhost:29092 --topic vehicle.speeding --from-beginning --max-messages 5

# Check connector status
curl http://localhost:8083/connectors/azure-blob-sink-connector/status | jq '.'

# Run verification script
bash scripts/verify_setup.sh
```

---

## Access Points

| Service | URL |
|---------|-----|
| Kafka | localhost:9092 |
| Control Center | http://localhost:9021 |
| ksqlDB | http://localhost:8088 |
| Kafka Connect | http://localhost:8083 |

---

## Cleanup

```bash
# Stop producer (Ctrl+C in producer terminal)

# Stop containers
docker-compose down

# Remove all data (full reset)
docker-compose down -v

# Delete Azure resources
Azure Portal → Resource Groups → Delete 'vehicle-iot-rg'
```

---

## Troubleshooting

### Connector not deploying?
```bash
docker logs kafka-connect --tail 100
docker restart kafka-connect
bash scripts/deploy_azure_connector.sh
```

### No data in Azure?
```bash
# Check connector status
curl http://localhost:8083/connectors/azure-blob-sink-connector/status | jq '.'

# Verify topics have data
docker exec kafka kafka-console-consumer --bootstrap-server localhost:29092 --topic vehicle.speeding --from-beginning --max-messages 1

# Check logs
docker logs kafka-connect | grep -i error
```

### Producer can't connect?
```bash
# Verify Kafka is running
docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:29092

# Use alternate port
python producer.py --broker localhost:9092
```

---

## Next Steps
- See [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) for Power BI dashboard setup
- Check `exercise_document` for project overview
- Explore Control Center UI at http://localhost:9021

---

**Done! 🎉** Your streaming pipeline is live.
