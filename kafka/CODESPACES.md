# GitHub Codespaces Setup Guide

## Why Use Codespaces?

The Azure Blob Storage Kafka Connector requires **Linux x86_64** architecture. If you're developing on:
- 🍎 **Mac with Apple Silicon (M1/M2/M3)** - ARM64 architecture
- 💻 **Windows on ARM** - ARM64 architecture

The connector will fail with a native library error. GitHub Codespaces provides a **free Linux x86_64 environment** where everything works perfectly.

---

## Quick Start (5 Minutes)

### Step 1: Launch Codespace

1. Go to your repository: `https://github.com/j4jessay/codebasics`
2. Click the **green "Code" button** (top right)
3. Select the **"Codespaces"** tab
4. Click **"Create codespace on main"**

Wait 2-3 minutes for the environment to set up automatically.

### Step 2: Start Kafka Stack

Once the codespace opens, run in the terminal:

```bash
cd kafka
docker compose up -d
```

Wait ~60 seconds for all services to start, then verify:

```bash
docker ps
# All services should show "Up" status
```

### Step 3: Deploy Azure Connector

```bash
scripts/deploy_azure_connector.sh
```

**Expected output:**
```
✅ Connector deployed successfully!
📊 Checking connector status...
{
  "connector": {"state": "RUNNING"},
  "tasks": [{"state": "RUNNING"}]  ← ✅ Success!
}
```

### Step 4: Start Producer

```bash
docker compose --profile producer up producer
```

---

## Accessing Services

Codespaces automatically forwards ports. Click the **"PORTS"** tab at the bottom of VS Code:

| Service | Port | Access |
|---------|------|--------|
| **Control Center** | 9021 | Click 🌐 globe icon → Opens Kafka UI |
| **ksqlDB** | 8088 | `curl localhost:8088/info` |
| **Kafka Connect** | 8083 | `curl localhost:8083/connectors` |
| **Kafka Broker** | 9092 | Used by producer/consumer |

---

## Common Commands

### Check Connector Status
```bash
curl localhost:8083/connectors/azure-blob-sink-connector/status | jq '.'
```

### View Kafka Topics
```bash
docker exec -it kafka kafka-topics --bootstrap-server localhost:9092 --list
```

### Access ksqlDB CLI
```bash
docker exec -it ksqldb-cli ksql http://ksqldb-server:8088
```

### View Logs
```bash
# Kafka Connect logs
docker logs kafka-connect

# Producer logs
docker logs producer

# All services
docker compose logs -f
```

### Stop All Services
```bash
docker compose down
```

---

## Verifying Azure Integration

### 1. Check Data in Azure Blob Storage

**Option A: Azure Portal**
1. Go to portal.azure.com
2. Navigate to Storage Accounts → `codebasics`
3. Click Containers → `vehicleiotdata`
4. You should see folders: `year=2025/month=11/day=09/...`

**Option B: Azure CLI (in Codespace)**
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login
az login

# List blobs
az storage blob list \
  --account-name codebasics \
  --container-name vehicleiotdata \
  --output table
```

### 2. Monitor Data Flow

```bash
# Watch Kafka Connect logs for uploads
docker logs -f kafka-connect | grep -i "azure\|upload\|blob"

# Check consumer lag
docker exec kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --describe \
  --group compose-connect-group
```

---

## Troubleshooting

### Issue: "Out of disk space"

**Check disk usage:**
```bash
df -h
```

**Clean up Docker:**
```bash
docker system prune -a --volumes
```

### Issue: "Container exited with code 137"

This means out of memory. The codespace needs more resources.

**Solution:** Update `.devcontainer/devcontainer.json`:
```json
"hostRequirements": {
  "cpus": 8,
  "memory": "16gb"
}
```

Then rebuild codespace: Cmd/Ctrl + Shift + P → "Codespaces: Rebuild Container"

### Issue: Ports not forwarding

**Check port forwarding:**
1. Click "PORTS" tab at bottom
2. Right-click the port → "Port Visibility" → "Public"

### Issue: Connector still fails

**Verify architecture:**
```bash
# Should show: x86_64
uname -m

# Check Docker platform
docker version
# Should show: linux/amd64 (or linux/x86_64)
```

---

## Cost & Limits

### Free Tier
- **60 hours/month** for 4-core codespace
- **120 hours/month** for 2-core codespace
- **15 GB storage**

### Your Usage
- Development: ~2-3 hours/day
- Monthly: ~60 hours
- **Cost: $0** ✅

### Paid Rates (if you exceed free tier)
- 4-core: $0.18/hour
- 2-core: $0.09/hour

### Auto-Stop
Codespaces automatically stop after **30 minutes of inactivity** to save hours.

**Manual stop:**
- GitHub UI → Your repository → "Code" → "Codespaces" → ⋮ → "Stop"

---

## Best Practices

### 1. Commit Often
```bash
git add .
git commit -m "Your changes"
git push
```

Codespaces can be deleted/rebuilt, so push your work regularly.

### 2. Stop When Done
Don't leave codespace running overnight. It counts against your free hours.

### 3. Use .gitignore
Never commit:
- `config/azure-credentials.env` (already in .gitignore)
- Large data files
- Docker volumes

### 4. Monitor Resources
```bash
# Check memory usage
docker stats

# Check CPU usage
htop  # (install: sudo apt install htop)
```

---

## Comparison: Local vs Codespaces

| Feature | Local Mac (ARM64) | GitHub Codespaces |
|---------|-------------------|-------------------|
| **Architecture** | ARM64 | x86_64 ✅ |
| **Connector Status** | FAILED ❌ | RUNNING ✅ |
| **Cost** | $0 | $0 (free tier) |
| **Internet Required** | No | Yes |
| **Setup Time** | 0 (done) | 2-3 min |
| **Production-Like** | 70% | 95% ✅ |

---

## Advanced: Connecting from Local Tools

### Access Codespace Kafka from Local Mac

**1. Get codespace URL:**
```bash
# In codespace terminal
gh codespace ports
```

**2. Forward port locally:**
```bash
# On your Mac
gh codespace ports forward 9092:9092
```

**3. Use local tools:**
```bash
# Kafkacat on Mac
kafkacat -b localhost:9092 -L
```

---

## Cleanup

### Delete Codespace
When you're done with the project:

1. Go to github.com
2. Click your profile → Settings → Codespaces
3. Find your codespace → Delete

**Note:** Your code is safe in GitHub. Only the running environment is deleted.

---

## Support

**GitHub Codespaces Docs:** https://docs.github.com/en/codespaces
**Kafka Documentation:** https://kafka.apache.org/documentation/
**Confluent Docs:** https://docs.confluent.io/

---

## Summary

✅ **Codespaces solves the ARM64 compatibility issue**
✅ **Free for personal use (60 hours/month)**
✅ **Production-like x86_64 environment**
✅ **Access from browser or VS Code**
✅ **Auto-stops to save resources**

Now you can develop and test your Kafka pipeline with full Azure Blob Storage integration! 🎉
