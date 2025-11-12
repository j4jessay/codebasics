# Connector Configuration

## 📖 Reading Time: 6 minutes

---

## Configuration Structure

Connectors are configured using JSON:

```json
{
  "name": "connector-name",
  "config": {
    "connector.class": "ConnectorClassName",
    "tasks.max": "1",
    "topics": "topic1,topic2",
    ...connector-specific parameters...
  }
}
```

---

## Common Parameters

| Parameter | Purpose | Example |
|-----------|---------|---------|
| `name` | Connector identifier | `"azure-blob-sink"` |
| `connector.class` | Connector type | `"AzureBlobStorageSinkConnector"` |
| `tasks.max` | Number of parallel tasks | `"1"` |
| `topics` | Topics to process | `"vehicle.speeding"` |
| `key.converter` | Key serialization | `"StringConverter"` |
| `value.converter` | Value serialization | `"JsonConverter"` |

---

## Azure Blob Sink Configuration

```json
{
  "name": "azure-blob-sink-connector",
  "config": {
    "connector.class": "io.confluent.connect.azure.blob.AzureBlobStorageSinkConnector",
    "tasks.max": "1",
    "topics": "vehicle.speeding,vehicle.lowfuel",
    "flush.size": "10",
    "azblob.account.name": "YOUR_STORAGE_ACCOUNT",
    "azblob.account.key": "YOUR_ACCESS_KEY",
    "azblob.container.name": "vehicle-telemetry-data",
    "format.class": "io.confluent.connect.azure.blob.format.json.JsonFormat",
    "partitioner.class": "io.confluent.connect.storage.partitioner.TimeBasedPartitioner",
    "path.format": "'year'=YYYY/'month'=MM/'day'=dd/'hour'=HH",
    "partition.duration.ms": "3600000",
    "timezone": "UTC"
  }
}
```

---

## REST API

### Deploy Connector

```bash
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @azure-blob-sink.json
```

### Check Status

```bash
curl http://localhost:8083/connectors/azure-blob-sink-connector/status
```

### List Connectors

```bash
curl http://localhost:8083/connectors
```

### Delete Connector

```bash
curl -X DELETE http://localhost:8083/connectors/azure-blob-sink-connector
```

---

## Key Takeaways

1. **JSON configuration** defines connector behavior
2. **REST API** for deployment and management
3. **Time-based partitioning** organizes output
4. **Monitor via REST** API or Control Center

---

**→ Next: [Go to Lab](../lab/README.md)**
