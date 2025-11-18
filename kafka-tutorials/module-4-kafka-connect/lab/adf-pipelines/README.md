# Azure Data Factory Pipeline Templates

This directory contains ADF pipeline JSON templates for loading vehicle telemetry data from Azure Blob Storage to Azure Synapse Analytics.

---

## Pipeline Templates

### 1. `01-simple-copy-blob-to-synapse.json`
**Purpose**: Basic copy pipeline for learning ADF fundamentals

**Flow**:
```
Azure Blob Storage (Parquet) → Synapse Analytics (SQL Table)
```

**Features**:
- Single Copy Activity
- Auto-detect schema
- PolyBase for fast loading
- Column mapping (snake_case → PascalCase)
- Retry logic (3 attempts)

**Use Case**: Development, testing, small datasets

**Parameters**:
- `loadDate` - Date to load (default: today)

**Estimated Runtime**: 2-5 minutes for 100K rows

---

### 2. `02-staged-load-with-validation.json`
**Purpose**: Production-grade pipeline with data quality checks

**Flow**:
```
Blob Storage → Synapse Staging Table → Validation → Main Table
                                      ↓
                                 Log & Audit
```

**Activities**:
1. **GetWatermark** - Lookup last loaded timestamp
2. **CopyToStagingTable** - Load only new data since watermark
3. **ValidateDataQuality** - Check for invalid/missing values
4. **CheckValidationResults** - If validation passes:
   - **MergeStagingToMain** - Upsert into main table
   - **LogSuccessfulLoad** - Audit trail
5. If validation fails:
   - **LogValidationFailure** - Record error details

**Data Quality Rules**:
- Speed: Must be between 0-200 km/h
- Fuel Level: Must be between 0-100%
- Engine Temp: Must be between -50 to 200°C
- Required fields: VehicleID, RecordedTimestamp
- **Threshold**: < 5% invalid records allowed

**Parameters**:
- `windowStart` - Start of time window (default: 1 hour ago)
- `windowEnd` - End of time window (default: now)

**Estimated Runtime**: 10-20 minutes for 500K rows

---

## Prerequisites

### Azure Resources Required
1. **Azure Data Factory** instance
2. **Azure Blob Storage** account (with vehicle telemetry Parquet files)
3. **Azure Synapse Analytics** workspace with:
   - Dedicated SQL pool (DW-100c or higher)
   - Tables created (see Module 6 for SQL scripts)
   - Stored procedures deployed

### Linked Services
Create these in ADF before importing pipelines:

#### LS_AzureBlobStorage
```json
{
  "name": "LS_AzureBlobStorage",
  "type": "AzureBlobStorage",
  "typeProperties": {
    "serviceEndpoint": "https://<storage-account>.blob.core.windows.net",
    "authentication": "ManagedIdentity"
  }
}
```

#### LS_AzureSynapse
```json
{
  "name": "LS_AzureSynapse",
  "type": "AzureSqlDW",
  "typeProperties": {
    "connectionString": "Server=<synapse-workspace>.sql.azuresynapse.net;Database=<database>;",
    "authentication": "ManagedIdentity"
  }
}
```

### Datasets
Create these in ADF:

#### DS_BlobStorage_VehicleTelemetry_Parquet
```json
{
  "name": "DS_BlobStorage_VehicleTelemetry_Parquet",
  "type": "Parquet",
  "linkedServiceName": {
    "referenceName": "LS_AzureBlobStorage",
    "type": "LinkedServiceReference"
  },
  "typeProperties": {
    "location": {
      "type": "AzureBlobStorageLocation",
      "container": "vehicle-telemetry",
      "folderPath": "@dataset().folderPath",
      "fileName": ""
    },
    "compressionCodec": "snappy"
  },
  "parameters": {
    "folderPath": {
      "type": "string",
      "defaultValue": "2025/11/17/10"
    }
  }
}
```

#### DS_Synapse_VehicleTelemetry_Table
```json
{
  "name": "DS_Synapse_VehicleTelemetry_Table",
  "type": "AzureSqlDWTable",
  "linkedServiceName": {
    "referenceName": "LS_AzureSynapse",
    "type": "LinkedServiceReference"
  },
  "typeProperties": {
    "schema": "dbo",
    "table": "VehicleTelemetry"
  }
}
```

#### DS_Synapse_VehicleTelemetry_Staging
```json
{
  "name": "DS_Synapse_VehicleTelemetry_Staging",
  "type": "AzureSqlDWTable",
  "linkedServiceName": {
    "referenceName": "LS_AzureSynapse",
    "type": "LinkedServiceReference"
  },
  "typeProperties": {
    "schema": "dbo",
    "table": "VehicleTelemetry_Staging"
  }
}
```

---

## How to Import Pipelines into ADF

### Method 1: Azure Portal (GUI)
1. Open Azure Portal → Your Data Factory → Author & Monitor
2. Click "Author" (pencil icon) → Pipelines → + New pipeline
3. Click "{}" (Code view) in top-right corner
4. Paste the JSON content from template files
5. Click "OK"
6. Validate: Click "Validate" button
7. Publish: Click "Publish all"

### Method 2: Azure CLI
```bash
# Login to Azure
az login

# Set variables
RESOURCE_GROUP="rg-kafka-tutorials"
ADF_NAME="adf-vehicle-telemetry"

# Import pipeline
az datafactory pipeline create \
  --resource-group $RESOURCE_GROUP \
  --factory-name $ADF_NAME \
  --name "SimpleCopyBlobToSynapse" \
  --pipeline @01-simple-copy-blob-to-synapse.json
```

### Method 3: PowerShell
```powershell
# Login
Connect-AzAccount

# Set variables
$resourceGroupName = "rg-kafka-tutorials"
$dataFactoryName = "adf-vehicle-telemetry"

# Import pipeline
Set-AzDataFactoryV2Pipeline `
  -ResourceGroupName $resourceGroupName `
  -DataFactoryName $dataFactoryName `
  -Name "SimpleCopyBlobToSynapse" `
  -DefinitionFile "01-simple-copy-blob-to-synapse.json"
```

---

## Testing the Pipelines

### Test Pipeline 1: Simple Copy

**Step 1: Prepare test data**
```bash
# Ensure Parquet files exist in Blob Storage
# Path: vehicle-telemetry/2025/11/17/*.parquet
```

**Step 2: Debug run in ADF**
1. Open pipeline in ADF Author view
2. Click "Debug"
3. Provide parameter: `loadDate` = "2025-11-17"
4. Click "OK"
5. Monitor progress in Output tab

**Expected Result**:
- Status: Succeeded
- Rows copied: ~10,000 (for 1 hour of data)
- Duration: 2-5 minutes

**Verification Query**:
```sql
-- Check loaded data in Synapse
SELECT TOP 100 *
FROM dbo.VehicleTelemetry
ORDER BY RecordedTimestamp DESC;

-- Count records
SELECT COUNT(*) AS TotalRecords
FROM dbo.VehicleTelemetry;
```

---

### Test Pipeline 2: Staged Load with Validation

**Step 1: Create required tables**
```sql
-- In Synapse, create main table
CREATE TABLE dbo.VehicleTelemetry (
    VehicleID NVARCHAR(50),
    RecordedTimestamp DATETIME2,
    Latitude DECIMAL(10,7),
    Longitude DECIMAL(10,7),
    Speed DECIMAL(5,2),
    FuelLevel DECIMAL(5,2),
    EngineTemp DECIMAL(5,2),
    Status NVARCHAR(20)
);

-- Create staging table (same schema)
CREATE TABLE dbo.VehicleTelemetry_Staging (
    VehicleID NVARCHAR(50),
    RecordedTimestamp DATETIME2,
    Latitude DECIMAL(10,7),
    Longitude DECIMAL(10,7),
    Speed DECIMAL(5,2),
    FuelLevel DECIMAL(5,2),
    EngineTemp DECIMAL(5,2),
    Status NVARCHAR(20)
);

-- Create audit log table
CREATE TABLE dbo.PipelineLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    PipelineName NVARCHAR(100),
    RunID NVARCHAR(100),
    Status NVARCHAR(50),
    RecordsLoaded INT,
    WindowStart DATETIME2,
    WindowEnd DATETIME2,
    ErrorMessage NVARCHAR(MAX),
    LogTime DATETIME2 DEFAULT GETDATE()
);
```

**Step 2: Create stored procedures**
```sql
-- See module-6/lab/synapse-scripts/03-stored-procedures.sql
```

**Step 3: Debug run**
1. Open pipeline in ADF
2. Click "Debug"
3. Provide parameters:
   - `windowStart` = "2025-11-17T10:00:00Z"
   - `windowEnd` = "2025-11-17T11:00:00Z"
4. Monitor each activity's progress

**Expected Result**:
```
Activity 1: GetWatermark ✓ (5 sec)
Activity 2: CopyToStagingTable ✓ (3 min)
Activity 3: ValidateDataQuality ✓ (10 sec)
Activity 4: CheckValidationResults (If True)
  → MergeStagingToMain ✓ (2 min)
  → LogSuccessfulLoad ✓ (5 sec)

Total Duration: ~6 minutes
```

**Verification**:
```sql
-- Check audit log
SELECT * FROM dbo.PipelineLog
ORDER BY LogTime DESC;

-- Verify no duplicates
SELECT VehicleID, RecordedTimestamp, COUNT(*)
FROM dbo.VehicleTelemetry
GROUP BY VehicleID, RecordedTimestamp
HAVING COUNT(*) > 1;
```

---

## Triggering Pipelines

### Manual Trigger
```bash
# Trigger via Azure CLI
az datafactory pipeline create-run \
  --resource-group $RESOURCE_GROUP \
  --factory-name $ADF_NAME \
  --name "SimpleCopyBlobToSynapse" \
  --parameters loadDate="2025-11-17"
```

### Schedule Trigger (Daily at midnight)
```json
{
  "name": "DailyMidnightTrigger",
  "type": "ScheduleTrigger",
  "properties": {
    "pipelines": [
      {
        "pipelineReference": {
          "referenceName": "StagedLoadWithValidation",
          "type": "PipelineReference"
        },
        "parameters": {
          "windowStart": "@addDays(utcnow(), -1)",
          "windowEnd": "@utcnow()"
        }
      }
    ],
    "recurrence": {
      "frequency": "Day",
      "interval": 1,
      "startTime": "2025-01-01T00:00:00Z",
      "timeZone": "UTC",
      "schedule": {
        "hours": [0],
        "minutes": [0]
      }
    }
  }
}
```

### Event-Based Trigger (Blob created)
```json
{
  "name": "BlobCreatedTrigger",
  "type": "BlobEventsTrigger",
  "properties": {
    "pipelines": [
      {
        "pipelineReference": {
          "referenceName": "SimpleCopyBlobToSynapse",
          "type": "PipelineReference"
        }
      }
    ],
    "events": ["Microsoft.Storage.BlobCreated"],
    "scope": "/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage-account>",
    "blobPathBeginsWith": "/vehicle-telemetry/2025",
    "blobPathEndsWith": ".parquet"
  }
}
```

---

## Monitoring & Troubleshooting

### Monitor Pipeline Runs
**Azure Portal**:
1. Data Factory → Monitor → Pipeline runs
2. Filter by pipeline name, status, time range
3. Click run ID to see activity details

**Query via API**:
```bash
az datafactory pipeline-run query \
  --resource-group $RESOURCE_GROUP \
  --factory-name $ADF_NAME \
  --last-updated-after "2025-11-17T00:00:00Z" \
  --last-updated-before "2025-11-18T00:00:00Z"
```

### Common Issues

#### Issue 1: Copy activity fails with "403 Forbidden"
**Cause**: ADF Managed Identity lacks permissions

**Solution**:
```bash
# Grant ADF Managed Identity access to Blob Storage
az role assignment create \
  --assignee <adf-managed-identity-object-id> \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage>

# Grant access to Synapse
# In Synapse SQL: GRANT SELECT, INSERT, UPDATE ON SCHEMA::dbo TO [<adf-name>]
```

#### Issue 2: Validation fails with high error rate
**Cause**: Source data quality issues in Kafka

**Solution**:
1. Check Kafka producer code for data generation logic
2. Review ksqlDB queries for filtering rules
3. Adjust validation threshold in pipeline (currently 5%)

#### Issue 3: Stored procedure not found
**Cause**: Procedures not deployed to Synapse

**Solution**:
```sql
-- Deploy required procedures (see module-6 scripts)
-- sp_MergeVehicleTelemetry
-- sp_LogPipelineRun
```

---

## Performance Tuning

### Optimize Copy Activity
| Setting | Default | Recommended | Impact |
|---------|---------|-------------|--------|
| **DIU** (Data Integration Units) | 4 | 8-16 for > 1 GB | 2x faster |
| **Parallel Copies** | Auto | 4-8 | Better throughput |
| **PolyBase** | Enabled | Enabled | 10x faster for Synapse |
| **Staging** | Disabled | Enable for transformations | Required for some scenarios |

**Example**:
```json
"translator": {
  "type": "TabularTranslator"
},
"enableStaging": true,
"stagingSettings": {
  "linkedServiceName": {
    "referenceName": "LS_AzureBlobStorage",
    "type": "LinkedServiceReference"
  },
  "path": "staging"
},
"dataIntegrationUnits": 16,
"parallelCopies": 8
```

### Partitioning Strategy
For large datasets (> 10 GB), use partition options:
```json
"partitionOption": "DynamicRange",
"partitionSettings": {
  "partitionColumnName": "RecordedTimestamp",
  "partitionUpperBound": "2025-12-31",
  "partitionLowerBound": "2025-01-01"
}
```

---

## Cost Estimates

### ADF Pricing (Pay-per-use)
| Activity | Price | Example Cost |
|----------|-------|--------------|
| **Pipeline orchestration** | $1.00 per 1,000 runs | $1 for 1,000 daily runs = $0.03/month |
| **Copy activity (Azure)** | $0.25 per DIU-hour | 1 hour at 4 DIU = $1.00 |
| **Data flow** | $0.27 per vCore-hour | Not used in simple pipelines |

**Monthly estimate for our use case**:
- 30 daily pipeline runs: $0.03
- 30 copy activities (avg 10 min each): $0.50
- **Total**: ~$0.60/month for ADF

**Note**: Synapse storage and compute costs are separate (see Module 6).

---

## Next Steps

1. Import pipelines into your ADF instance
2. Create required linked services and datasets
3. Run debug tests with sample data
4. Set up triggers for automation
5. Monitor pipeline runs and optimize performance

For Synapse table creation and stored procedures, see:
- **Module 6**: `module-6-complete-pipeline/lab/synapse-scripts/`

---

## Additional Resources

- [ADF Copy Activity Documentation](https://learn.microsoft.com/en-us/azure/data-factory/copy-activity-overview)
- [ADF Pipeline Best Practices](https://learn.microsoft.com/en-us/azure/data-factory/concepts-best-practices)
- [Synapse PolyBase Loading](https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/design-elt-data-loading)
- [ADF Monitoring Guide](https://learn.microsoft.com/en-us/azure/data-factory/monitor-visually)

---

**Last Updated**: November 17, 2025
**Version**: 1.0
**Module 4 - Lab**: Azure Data Factory Pipelines
