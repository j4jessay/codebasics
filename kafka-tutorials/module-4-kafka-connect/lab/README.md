# Module 4 Lab: Kafka Connect & Azure Integration

## ⏱️ Duration: 40 minutes

---

## 🎯 Lab Objectives

By the end of this lab, you will:

- ✅ Create an Azure Storage Account and container
- ✅ Configure the Azure Blob Storage sink connector
- ✅ Deploy the connector using REST API
- ✅ Verify data flowing to Azure Blob Storage
- ✅ Understand time-based partitioning

---

## ✅ Prerequisites

- [ ] Modules 1, 2, and 3 completed
- [ ] Producer running (sending vehicle telemetry)
- [ ] ksqlDB streams created (speeding, lowfuel)
- [ ] Azure account (free tier works)

---

## 🛠️ Setup Azure Storage Account (10 minutes)

### Step 1: Login to Azure Portal

1. Go to https://portal.azure.com
2. Sign in with your Microsoft account
3. If you don't have an account, create a free trial

---

### Step 2: Create Storage Account

1. **Click** "Create a resource" (top left)
2. **Search** for "Storage Account"
3. **Click** "Create"

**Fill in details:**
- **Subscription:** Your subscription
- **Resource Group:** Create new → "kafka-tutorial-rg"
- **Storage Account Name:** `vehicleiotXXXXX` (replace XXXXX with your name/numbers - must be globally unique, lowercase, no hyphens)
- **Region:** Select nearest region (e.g., East US, West Europe)
- **Performance:** Standard
- **Redundancy:** LRS (Locally Redundant Storage) - cheapest option

4. **Click** "Review + Create"
5. **Click** "Create"

**⏱️ Wait:** 1-2 minutes for deployment

---

### Step 3: Create Blob Container

1. **Go to** your storage account (click "Go to resource" after deployment)
2. **Left menu** → Data storage → **Containers**
3. **Click** "+ Container"
4. **Name:** `vehicle-telemetry-data`
5. **Public access level:** Private (default)
6. **Click** "Create"

**✅ Success Checkpoint:** Container created

---

### Step 4: Get Access Keys

1. **Left menu** → Security + networking → **Access keys**
2. **Click** "Show" next to key1
3. **Copy:**
   - Storage account name: `vehicleiotXXXXX`
   - key1 value: (long string of characters)

**⚠️ IMPORTANT:** Keep these credentials secure!

---

## ⚙️ Configure Connector (10 minutes)

### Step 1: Navigate to Lab Directory

```bash
cd kafka-tutorials/module-4-kafka-connect/lab
```

---

### Step 2: Update Configuration

**Edit the connector configuration:**
```bash
nano config/azure-blob-sink.json
```

**OR use your preferred editor (VS Code, vim, etc.)**

**Find and replace these values:**
```json
{
  "name": "azure-blob-sink-connector",
  "config": {
    ...
    "azblob.account.name": "vehicleiotXXXXX",  ← YOUR STORAGE ACCOUNT NAME
    "azblob.account.key": "YOUR_KEY_HERE",     ← YOUR ACCESS KEY
    "azblob.container.name": "vehicle-telemetry-data",
    ...
  }
}
```

**Save the file**

**✅ Success Checkpoint:** Configuration file updated

---

## 🚀 Deploy Connector (10 minutes)

### Step 1: Start Full Kafka Stack

```bash
docker compose up -d
```

This starts:
- Zookeeper
- Kafka
- ksqlDB Server
- Kafka Connect (with Azure Blob connector)
- Schema Registry
- Control Center

**⏱️ Wait:** 2-3 minutes for all services to initialize

---

### Step 2: Verify Kafka Connect is Running

```bash
docker ps | grep kafka-connect
```

**Expected:** Container running

**Check if connector plugin is installed:**
```bash
curl http://localhost:8083/connector-plugins | grep -i azure
```

**Expected output:**
```
"class":"io.confluent.connect.azure.blob.AzureBlobStorageSinkConnector"
```

**✅ Success Checkpoint:** Kafka Connect and Azure plugin ready

---

### Step 3: Deploy the Connector

**Option A: Use the deployment script (Recommended)**
```bash
cd scripts
bash deploy_connector.sh
```

**Option B: Manual deployment**
```bash
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @config/azure-blob-sink.json
```

**Expected output:**
```json
{
  "name": "azure-blob-sink-connector",
  "config": { ... },
  "tasks": [],
  "type": "sink"
}
```

**✅ Success Checkpoint:** Connector deployed

---

### Step 4: Check Connector Status

```bash
curl http://localhost:8083/connectors/azure-blob-sink-connector/status | python3 -m json.tool
```

**Expected output:**
```json
{
  "name": "azure-blob-sink-connector",
  "connector": {
    "state": "RUNNING",  ← Should be RUNNING
    "worker_id": "kafka-connect:8083"
  },
  "tasks": [
    {
      "id": 0,
      "state": "RUNNING",  ← Should be RUNNING
      "worker_id": "kafka-connect:8083"
    }
  ]
}
```

**⚠️ If state is FAILED:** Check logs with `docker logs kafka-connect`

**✅ Success Checkpoint:** Connector state = RUNNING

---

## 🔍 Verify Data in Azure (10 minutes)

### Step 1: Wait for Data

**⏱️ Wait:** 1-2 minutes for data to be exported

The connector batches messages (flush.size=10), so it waits until 10 messages accumulate or 60 seconds pass.

---

### Step 2: Check Azure Portal

1. **Go to** Azure Portal → Your storage account
2. **Navigate to** Containers → `vehicle-telemetry-data`
3. **You should see folders:**

```
year=2024/
  month=11/
    day=10/
      hour=14/
        vehicle.speeding+0+0000000000.json
        vehicle.lowfuel+0+0000000000.json
```

---

### Step 3: Download and View Data

1. **Click** on a JSON file
2. **Click** "Download"
3. **Open** with text editor

**Expected content:**
```json
{"vehicle_id":"VEH-0003","speed_kmph":95.67,"timestamp_utc":"2024-11-10T14:30:15Z","location":{"lat":28.6139,"lon":77.2090},"alert_type":"SPEEDING_ALERT"}
{"vehicle_id":"VEH-0005","speed_kmph":87.23,"timestamp_utc":"2024-11-10T14:30:20Z","location":{"lat":28.6140,"lon":77.2091},"alert_type":"SPEEDING_ALERT"}
...
```

**✅ Success Checkpoint:** JSON files with vehicle data in Azure!

---

## 📊 Understanding the Data Structure

### Time-Based Partitioning

The connector organizes data by time:

```
vehicle-telemetry-data/
├── year=2024/
│   ├── month=11/
│   │   ├── day=10/
│   │   │   ├── hour=14/
│   │   │   │   ├── vehicle.speeding+0+0000000000.json
│   │   │   │   ├── vehicle.lowfuel+0+0000000000.json
│   │   │   ├── hour=15/
│   │   │   │   ├── vehicle.speeding+0+0000000010.json
```

**Benefits:**
- Easy to query by date/time
- Efficient for analytics
- Compatible with data warehouses (Hive-style partitions)

---

### File Naming Convention

```
vehicle.speeding+0+0000000000.json
    │            │      │
    │            │      └─ Starting offset
    │            └──────── Partition number
    └───────────────────── Topic name
```

---

## 🎓 Lab Summary

Congratulations! You've completed Module 4 Lab. You now know how to:

- ✅ Create Azure Storage Account and container
- ✅ Configure Kafka Connect sink connector
- ✅ Deploy connector using REST API
- ✅ Export Kafka data to cloud storage
- ✅ Verify data with time-based partitioning

---

## 🔧 Additional Commands

### List All Connectors
```bash
curl http://localhost:8083/connectors
```

### Get Connector Configuration
```bash
curl http://localhost:8083/connectors/azure-blob-sink-connector | python3 -m json.tool
```

### Pause Connector
```bash
curl -X PUT http://localhost:8083/connectors/azure-blob-sink-connector/pause
```

### Resume Connector
```bash
curl -X PUT http://localhost:8083/connectors/azure-blob-sink-connector/resume
```

### Delete Connector
```bash
curl -X DELETE http://localhost:8083/connectors/azure-blob-sink-connector
```

---

## 🧹 Cleanup (Optional)

**Stop containers:**
```bash
docker compose down
```

**Delete Azure resources:**
1. Azure Portal → Resource Groups
2. Select "kafka-tutorial-rg"
3. Click "Delete resource group"
4. Type the resource group name to confirm
5. Click "Delete"

---

## 🚀 Next Steps

Ready for monitoring? Proceed to Module 5!

**[→ Go to Module 5: Monitoring & Operations](../../module-5-monitoring-operations/)**

---

## 🆘 Troubleshooting

### Connector State = FAILED

```bash
# Check logs
docker logs kafka-connect --tail 100

# Common issues:
# - Wrong Azure credentials
# - Container doesn't exist
# - Network connectivity
```

### No Data in Azure

```bash
# Verify topics have data
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic vehicle.speeding \
  --from-beginning \
  --max-messages 5

# Check connector status
curl http://localhost:8083/connectors/azure-blob-sink-connector/status

# Check if flush.size threshold met (10 messages)
```

### Connector Won't Deploy

```bash
# Verify Kafka Connect is running
curl http://localhost:8083/

# Check if plugin is installed
curl http://localhost:8083/connector-plugins | grep -i azure

# Restart Kafka Connect
docker restart kafka-connect
sleep 30
bash scripts/deploy_connector.sh
```

---

**Excellent work!** Your streaming data is now in the cloud!
