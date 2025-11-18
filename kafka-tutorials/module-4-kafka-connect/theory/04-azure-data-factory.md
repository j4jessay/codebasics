# Azure Data Factory (ADF) - ETL Orchestration

## Overview

Azure Data Factory is Microsoft's cloud-based **ETL (Extract, Transform, Load)** and **data integration** service. It allows you to create data-driven workflows for orchestrating and automating data movement and data transformation.

In our Kafka-to-Azure pipeline, ADF acts as the **orchestration layer** that:
- Moves data from Azure Blob Storage to Azure Synapse Analytics
- Transforms data during the transfer process
- Schedules and monitors pipeline execution
- Handles dependencies and error recovery

---

## Why Use ADF with Kafka?

### The Problem
While Kafka Connect efficiently exports data to Azure Blob Storage, we still need:
1. **Data warehouse loading** - Moving files from Blob to Synapse
2. **Data transformation** - Cleaning, validating, and enriching data
3. **Orchestration** - Coordinating multiple data workflows
4. **Monitoring** - Tracking pipeline success/failures
5. **Scheduling** - Running batch loads at specific times

### The Solution
Azure Data Factory provides a **no-code/low-code** visual interface to:
- Create robust data pipelines
- Transform data without writing complex ETL code
- Schedule and trigger workflows
- Monitor all data movements in one place

---

## ADF Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Azure Data Factory                        │
│                                                             │
│  ┌────────────────┐       ┌──────────────────┐             │
│  │  Linked        │       │   Datasets       │             │
│  │  Services      │◄──────┤  (Data schemas)  │             │
│  │                │       │                  │             │
│  │ • Blob Storage │       │ • Source: Parquet│             │
│  │ • Synapse      │       │ • Sink: SQL Table│             │
│  │ • Data Lake    │       │                  │             │
│  └────────────────┘       └──────────────────┘             │
│                                    │                        │
│                                    ▼                        │
│                           ┌──────────────────┐             │
│                           │    Pipelines     │             │
│                           │                  │             │
│                           │ • Copy Activity  │             │
│                           │ • Data Flow      │             │
│                           │ • Lookup         │             │
│                           │ • Execute SQL    │             │
│                           └──────────────────┘             │
│                                    │                        │
│                                    ▼                        │
│                           ┌──────────────────┐             │
│                           │    Triggers      │             │
│                           │                  │             │
│                           │ • Schedule       │             │
│                           │ • Event-based    │             │
│                           │ • Manual         │             │
│                           └──────────────────┘             │
└─────────────────────────────────────────────────────────────┘
```

---

## Key ADF Components

### 1. Linked Services
**What**: Connections to external data sources (like connection strings)

**Examples**:
```json
{
  "name": "AzureBlobStorageLinkedService",
  "type": "AzureBlobStorage",
  "properties": {
    "connectionString": "DefaultEndpointsProtocol=https;AccountName=...",
    "authentication": "Managed Identity"
  }
}
```

**In Our Pipeline**:
- Blob Storage linked service (source)
- Synapse Analytics linked service (destination)

---

### 2. Datasets
**What**: Structure and schema of your data

**Examples**:
```json
{
  "name": "VehicleTelemetryParquet",
  "type": "Parquet",
  "linkedServiceName": "AzureBlobStorageLinkedService",
  "properties": {
    "location": {
      "type": "AzureBlobFSLocation",
      "folderPath": "vehicle-telemetry/2025/11/17/10"
    }
  }
}
```

**In Our Pipeline**:
- Source dataset: Parquet files in Blob Storage
- Sink dataset: SQL tables in Synapse

---

### 3. Pipelines
**What**: Logical grouping of activities that perform a task

**Components**:
- **Activities**: Individual tasks (copy, transform, execute SQL)
- **Parameters**: Dynamic values passed at runtime
- **Variables**: Store intermediate values
- **Dependencies**: Control execution order

**Example Pipeline Structure**:
```
Pipeline: Load Vehicle Telemetry to Synapse
│
├── Activity 1: Lookup (Get latest load timestamp)
│   └── Success ──→
│
├── Activity 2: Copy Data (Blob → Synapse staging)
│   └── Success ──→
│
├── Activity 3: Stored Procedure (Merge staging → main table)
│   └── Success ──→
│
└── Activity 4: Delete Files (Clean up processed files)
```

---

### 4. Activities

#### Copy Activity
**Purpose**: Move data from source to destination

**Features**:
- Parallel data copying
- Fault tolerance (retry logic)
- Schema mapping
- Data type conversion
- Incremental loading

**Example Use Case**:
```
Source: /vehicle-telemetry/2025/11/17/*.parquet
Sink: dbo.VehicleTelemetry (Synapse table)
Mapping:
  - timestamp → RecordedTimestamp
  - vehicle_id → VehicleID
  - speed → Speed
```

#### Data Flow Activity
**Purpose**: Visual data transformation (like SSIS or Databricks)

**Transformations**:
- Filter rows (remove nulls)
- Derive columns (calculate new fields)
- Aggregate (group by vehicle_id)
- Join datasets
- Pivot/unpivot

**Example**:
```sql
-- Data Flow: Clean Vehicle Data
Source: Parquet files
  ↓
Filter: speed IS NOT NULL AND speed >= 0
  ↓
Derived Column: speed_kmh = speed * 1.60934 (mph to km/h conversion)
  ↓
Sink: Synapse table
```

#### Lookup Activity
**Purpose**: Retrieve metadata or configuration values

**Example**:
```sql
-- Get last processed timestamp
SELECT MAX(RecordedTimestamp) AS LastLoadTime
FROM dbo.VehicleTelemetry
```

#### Execute SQL Activity
**Purpose**: Run SQL commands on the destination database

**Example**:
```sql
-- Execute stored procedure to merge data
EXEC dbo.sp_MergeVehicleTelemetry
  @StartDate = '@{pipeline().parameters.startDate}',
  @EndDate = '@{pipeline().parameters.endDate}'
```

---

### 5. Triggers

#### Schedule Trigger
**Purpose**: Run pipeline on a recurring schedule

**Examples**:
```json
{
  "name": "DailyMidnightTrigger",
  "type": "ScheduleTrigger",
  "properties": {
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

**Use Cases**:
- Daily batch loads at midnight
- Hourly incremental loads
- Weekly aggregation jobs

#### Tumbling Window Trigger
**Purpose**: Process data in fixed, non-overlapping time windows

**Features**:
- Automatic backfill for missed windows
- Dependency on previous window completion
- Window start/end times passed as parameters

**Example**:
```json
{
  "name": "HourlyWindowTrigger",
  "type": "TumblingWindowTrigger",
  "properties": {
    "frequency": "Hour",
    "interval": 1,
    "startTime": "2025-01-01T00:00:00Z",
    "delay": "00:15:00"  // Wait 15 min after window closes
  }
}
```

#### Event Trigger
**Purpose**: Run pipeline when a file is created/deleted in Blob Storage

**Example**:
```json
{
  "name": "BlobCreatedTrigger",
  "type": "BlobEventsTrigger",
  "properties": {
    "events": ["Microsoft.Storage.BlobCreated"],
    "scope": "/subscriptions/.../blobServices/default/containers/vehicle-telemetry",
    "blobPathBeginsWith": "/2025/11/",
    "blobPathEndsWith": ".parquet"
  }
}
```

**Use Cases**:
- Process files immediately when Kafka Connect creates them
- Near real-time data loading

---

## ADF Integration with Kafka Pipeline

### End-to-End Flow

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│    Kafka     │       │ Kafka Connect│       │ Azure Blob   │
│   Topics     │──────▶│ (Every 5 min)│──────▶│   Storage    │
│              │       │              │       │ (Bronze/Raw) │
└──────────────┘       └──────────────┘       └──────┬───────┘
                                                      │
                                                      │ Event Trigger
                                                      │ (file created)
                                                      ▼
                                             ┌──────────────────┐
                                             │  ADF Pipeline    │
                                             │  - Copy Activity │
                                             │  - Validation    │
                                             │  - Transform     │
                                             └────────┬─────────┘
                                                      │
                                                      ▼
                                             ┌──────────────────┐
                                             │  Azure Synapse   │
                                             │  Analytics (DW)  │
                                             │  (Gold/Curated)  │
                                             └──────────────────┘
                                                      │
                                                      ▼
                                             ┌──────────────────┐
                                             │    Power BI      │
                                             │   Dashboards     │
                                             └──────────────────┘
```

---

## Pipeline Design Patterns

### Pattern 1: Simple Copy (Bronze → Gold)
**Use Case**: Direct load without transformation

```
Pipeline: Simple_Blob_to_Synapse
│
└── Copy Activity
    ├── Source: Parquet files (Blob)
    ├── Sink: SQL table (Synapse)
    └── Mapping: Auto-detect schema
```

**Pros**: Fast, simple
**Cons**: No data quality checks

---

### Pattern 2: Staged Load with Validation
**Use Case**: Production-grade pipeline with error handling

```
Pipeline: Staged_Load_Vehicle_Data
│
├── 1. Lookup: Get watermark (last loaded timestamp)
│   └── Output: @{activity('GetWatermark').output.firstRow.LastLoadTime}
│
├── 2. Copy Activity: Blob → Synapse Staging Table
│   ├── Filter: timestamp > watermark
│   └── On Success ──→
│
├── 3. Validation: Check row count
│   ├── If rowCount > 0 ──→
│   │
│   ├── 4. Stored Procedure: Merge Staging → Main Table
│   │   ├── Deduplication logic
│   │   └── Data quality checks
│   │
│   └── 5. Update Watermark
│       └── SET LastLoadTime = MAX(timestamp)
│
└── 6. On Failure: Send Alert (Logic App/Email)
```

---

### Pattern 3: Incremental Load (Delta/CDC)
**Use Case**: Load only new/changed records

```
Pipeline: Incremental_Load_with_ChangeTracking
│
├── Parameters:
│   ├── @{pipeline().parameters.windowStart}  // 2025-11-17 10:00:00
│   └── @{pipeline().parameters.windowEnd}    // 2025-11-17 11:00:00
│
├── 1. Copy Activity (Incremental)
│   ├── Source Query:
│   │   SELECT * FROM vehicle_telemetry
│   │   WHERE timestamp >= '@{windowStart}'
│   │     AND timestamp < '@{windowEnd}'
│   │
│   └── Sink: Append to Synapse table
│
└── 2. Log Pipeline Run
    └── INSERT INTO dbo.PipelineLog (RunID, Status, RecordsLoaded)
```

---

## Data Transformation in ADF

### Option 1: Mapping Data Flows (Visual)
**GUI-based transformations**

**Advantages**:
- No coding required
- Visual debugging
- Schema drift handling

**Disadvantages**:
- Higher cost (uses Spark clusters)
- Learning curve for complex transformations

**Example**:
```
Source (Parquet)
  ↓
Filter: fuel_level IS NOT NULL
  ↓
Derived Column:
  - distance_km = speed * (timestamp_diff / 3600)
  - alert_type = CASE
      WHEN speed > 120 THEN 'Speeding'
      WHEN fuel_level < 10 THEN 'Low Fuel'
      ELSE 'Normal'
    END
  ↓
Aggregate:
  - GROUP BY vehicle_id, DATE(timestamp)
  - avg_speed = AVG(speed)
  - total_distance = SUM(distance_km)
  ↓
Sink (Synapse: dbo.VehicleDailySummary)
```

---

### Option 2: SQL Transformations (Code-based)
**Use Synapse stored procedures**

**Advantages**:
- Faster execution (no Spark overhead)
- Familiar SQL syntax
- Lower cost

**Disadvantages**:
- Requires SQL knowledge
- Limited to SQL capabilities

**Example**:
```sql
-- ADF calls this stored procedure after copy activity

CREATE PROCEDURE dbo.sp_TransformVehicleData
AS
BEGIN
    -- Clean and validate staging data
    DELETE FROM dbo.VehicleTelemetry_Staging
    WHERE speed < 0 OR speed > 200  -- Invalid speeds
       OR fuel_level < 0 OR fuel_level > 100;  -- Invalid fuel

    -- Enrich with derived columns
    UPDATE dbo.VehicleTelemetry_Staging
    SET
        speed_category = CASE
            WHEN speed < 40 THEN 'Slow'
            WHEN speed < 80 THEN 'Normal'
            ELSE 'Fast'
        END,
        fuel_status = CASE
            WHEN fuel_level < 15 THEN 'Critical'
            WHEN fuel_level < 30 THEN 'Low'
            ELSE 'Normal'
        END;

    -- Merge staging into main table (upsert)
    MERGE dbo.VehicleTelemetry AS target
    USING dbo.VehicleTelemetry_Staging AS source
    ON target.vehicle_id = source.vehicle_id
       AND target.timestamp = source.timestamp
    WHEN MATCHED THEN
        UPDATE SET
            speed = source.speed,
            fuel_level = source.fuel_level,
            engine_temp = source.engine_temp
    WHEN NOT MATCHED THEN
        INSERT (vehicle_id, timestamp, speed, fuel_level, engine_temp)
        VALUES (source.vehicle_id, source.timestamp, source.speed,
                source.fuel_level, source.engine_temp);

    -- Truncate staging table
    TRUNCATE TABLE dbo.VehicleTelemetry_Staging;
END
```

---

## Monitoring & Debugging

### ADF Monitoring Dashboard
**Access**: Azure Portal → Data Factory → Monitor

**Key Metrics**:
- Pipeline runs (success/failed/in progress)
- Activity duration
- Data read/written
- Error messages

**Example**:
```
Pipeline: Load_Vehicle_Data_to_Synapse
Run ID: a1b2c3d4-e5f6-4789-012a-bcdef1234567
Start Time: 2025-11-17 10:05:00
Duration: 8 minutes 23 seconds
Status: Succeeded

Activity Details:
├── CopyData_Blob_to_Synapse
│   ├── Rows Read: 125,430
│   ├── Rows Written: 125,430
│   ├── Duration: 6m 15s
│   └── Throughput: 15 MB/s
│
└── StoredProcedure_MergeData
    ├── Duration: 2m 08s
    └── Status: Succeeded
```

---

### Common Issues & Troubleshooting

#### Issue 1: Timeout Errors
**Symptoms**: Activity fails after 30 minutes

**Solutions**:
- Increase timeout in activity settings
- Use parallel copy (increase DIU - Data Integration Units)
- Partition large files

#### Issue 2: Schema Mismatch
**Symptoms**: Copy fails with "Column X not found"

**Solutions**:
- Enable schema drift in dataset
- Use column mapping explicitly
- Validate Parquet schema matches SQL table

#### Issue 3: Permission Denied
**Symptoms**: "403 Forbidden" or "Access Denied"

**Solutions**:
- Use Managed Identity for authentication
- Grant ADF identity "Storage Blob Data Contributor" role
- Grant "db_datareader" and "db_datawriter" on Synapse

---

## Best Practices

### 1. Security
- Use **Managed Identities** instead of connection strings with passwords
- Store secrets in **Azure Key Vault**
- Enable **Private Endpoints** for Synapse (production)
- Use **Azure RBAC** for access control

### 2. Performance
- **Parallel copy**: Increase DIU (Data Integration Units) for large files
- **Partitioning**: Use partition options for large datasets
- **Compression**: Enable compression for data transfer
- **Incremental loads**: Load only new/changed data

### 3. Cost Optimization
- Use **Tumbling Window triggers** for efficient scheduling
- **Pause Synapse pool** when not in use
- Use **serverless SQL pools** for dev/test
- Monitor **pipeline runs** and optimize slow activities

### 4. Reliability
- Implement **retry policies** on activities
- Use **staging tables** for validation before loading
- Set up **email alerts** for pipeline failures
- Log pipeline runs to a **monitoring table**

---

## ADF vs. Other ETL Tools

| Feature | Azure Data Factory | Apache NiFi | AWS Glue | Talend |
|---------|-------------------|-------------|----------|--------|
| **Cloud-native** | Azure | Self-hosted | AWS | Hybrid |
| **Pricing** | Consumption-based | Free (OSS) | Consumption | License |
| **GUI** | Yes | Yes | Limited | Yes |
| **Code-first** | Yes (JSON/ARM) | No | Yes (Python) | Limited |
| **Real-time** | Limited | Yes | No | Limited |
| **Learning Curve** | Medium | Medium | Low | High |
| **Best For** | Azure ecosystems | Complex routing | AWS ecosystems | Enterprise ETL |

---

## When to Use ADF

### ✅ Use ADF When:
- Working in **Azure ecosystem** (Blob, Synapse, Data Lake)
- Need **visual pipeline design** (low-code)
- Require **managed service** (no infrastructure)
- Want **tight integration** with Azure services
- Need **event-driven** pipelines (Blob triggers)

### ❌ Don't Use ADF When:
- Need **complex real-time transformations** (use Databricks instead)
- Working entirely **on-premises** (use SSIS or Informatica)
- Need **streaming ETL** (use Kafka Streams or Flink)
- Budget is very limited (use open-source alternatives)

---

## Summary

### Key Takeaways

1. **ADF is an orchestration tool** - It coordinates data movement and transformation
2. **Complements Kafka Connect** - Handles warehouse loading after Kafka exports to Blob
3. **No-code/low-code** - Build pipelines visually or with JSON
4. **Scalable & reliable** - Built-in retry, monitoring, and error handling
5. **Cost-effective** - Pay only for pipeline runs and data movement

### In Our Kafka Pipeline
```
Kafka → Kafka Connect → Blob Storage → ADF → Synapse → Power BI
         (Streaming)   (Bronze Layer)   (ETL)  (Gold DW)  (Analytics)
```

ADF bridges the gap between **raw data lake** (Blob) and **curated data warehouse** (Synapse), enabling powerful analytics and reporting.

---

## Next Steps

In the hands-on lab, you will:
1. Create an Azure Data Factory instance
2. Set up linked services (Blob + Synapse)
3. Build a copy pipeline to load Parquet files into Synapse
4. Configure an event-based trigger to auto-run when files arrive
5. Monitor pipeline execution and troubleshoot issues

Let's move to the lab exercises to see ADF in action!

---

## Additional Resources

- [Azure Data Factory Documentation](https://learn.microsoft.com/en-us/azure/data-factory/)
- [ADF Pricing Calculator](https://azure.microsoft.com/en-us/pricing/details/data-factory/)
- [Data Factory GitHub Samples](https://github.com/Azure/Azure-DataFactory)
- [ADF Best Practices Guide](https://learn.microsoft.com/en-us/azure/data-factory/concepts-best-practices)

---

**Module 4 - Part B: Azure Data Factory**
**Duration**: 30 minutes theory + 30 minutes hands-on
**Next**: Hands-on Lab - Building Your First ADF Pipeline
