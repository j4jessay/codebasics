# Synapse SQL Scripts

This directory contains SQL scripts to set up the Azure Synapse Analytics data warehouse for the vehicle telemetry pipeline.

---

## Overview

These scripts create the complete database schema including:
- Fact tables for vehicle telemetry data
- Staging tables for ETL processes
- Stored procedures for data validation and loading
- Analytical views for BI consumption
- Audit and logging tables

---

## Prerequisites

### 1. Azure Synapse Workspace Deployed

You must have already deployed Azure resources using the ARM template from Module 4:

```bash
cd module-4-kafka-connect/lab/arm-templates
./deploy.sh
```

This creates:
- Azure Synapse Analytics workspace
- Dedicated SQL Pool (`VehicleDataWarehouse`)
- Azure Data Factory
- Azure Blob Storage

### 2. Synapse SQL Pool Running

Resume the SQL pool if it's paused:

```bash
az synapse sql pool resume \
  --name VehicleDataWarehouse \
  --workspace-name <your-workspace-name> \
  --resource-group kafka-tutorials-rg
```

**Cost Warning:** Dedicated SQL Pool DW100c costs ~$1.20/hour when running. Pause when not in use!

### 3. Firewall Access Configured

Add your IP address to Synapse firewall:

```bash
# Get your public IP
MY_IP=$(curl -s ifconfig.me)

# Add firewall rule
az synapse workspace firewall-rule create \
  --name AllowMyIP \
  --workspace-name <your-workspace-name> \
  --resource-group kafka-tutorials-rg \
  --start-ip-address $MY_IP \
  --end-ip-address $MY_IP
```

---

## Connection Information

### SQL Endpoint
```
Server: <workspace-name>.sql.azuresynapse.net
Database: VehicleDataWarehouse
Port: 1433
```

### Authentication
- **Username**: `sqladmin` (or your configured SQL admin)
- **Password**: (from ARM template deployment)

### Connection Tools

**Option 1: Azure Portal Query Editor**
1. Navigate to Azure Portal → Synapse workspace
2. Click "SQL pools" → `VehicleDataWarehouse`
3. Click "Query editor" → Login with SQL credentials

**Option 2: Azure Data Studio (Recommended)**
- Download: https://docs.microsoft.com/en-us/sql/azure-data-studio/
- Connection type: "Microsoft SQL Server"
- Server: `<workspace-name>.sql.azuresynapse.net`
- Database: `VehicleDataWarehouse`
- Authentication: SQL Login

**Option 3: SQL Server Management Studio (SSMS)**
- Download: https://docs.microsoft.com/en-us/sql/ssms/
- Connect using same credentials as Azure Data Studio

**Option 4: sqlcmd (Command Line)**
```bash
sqlcmd -S <workspace-name>.sql.azuresynapse.net \
  -d VehicleDataWarehouse \
  -U sqladmin \
  -P '<your-password>' \
  -i 01-create-schema.sql
```

---

## Execution Order

**IMPORTANT:** Execute scripts in the following order:

### Step 1: Create Schema and Settings
```sql
-- Execute first
:r 01-create-schema.sql
```
- Sets up database-level configurations
- Creates schemas if needed
- Grants permissions to ADF managed identity

### Step 2: Create Tables
```sql
-- Execute second
:r 02-create-tables.sql
```
- Creates main fact table: `VehicleTelemetry`
- Creates staging table: `VehicleTelemetry_Staging`
- Creates audit tables: `PipelineLog`, `DataQualityLog`
- Creates optional dimension tables

### Step 3: Create Stored Procedures
```sql
-- Execute third
:r 03-stored-procedures.sql
```
- Creates ETL stored procedures
- Creates validation and logging procedures
- Creates watermark tracking procedures

### Step 4: Create Views (Optional)
```sql
-- Execute fourth (optional for analytics)
:r 04-create-views.sql
```
- Creates analytical views for BI tools
- Aggregated metrics and summaries

---

## Verification

After executing all scripts, verify the setup:

### Check Tables Created
```sql
SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    t.create_date AS CreatedDate
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY t.name;
```

**Expected tables:**
- `dbo.VehicleTelemetry`
- `dbo.VehicleTelemetry_Staging`
- `dbo.PipelineLog`
- `dbo.DataQualityLog`
- `dbo.DimVehicle` (optional)
- `dbo.DimDateTime` (optional)
- `dbo.DimLocation` (optional)

### Check Stored Procedures Created
```sql
SELECT
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS ProcedureName,
    create_date AS CreatedDate
FROM sys.procedures
ORDER BY name;
```

**Expected procedures:**
- `sp_MergeVehicleTelemetry`
- `sp_ValidateDataQuality`
- `sp_LogPipelineRun`
- `sp_GetWatermark`
- `sp_UpdateWatermark`

### Check Views Created (if optional script ran)
```sql
SELECT
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS ViewName,
    create_date AS CreatedDate
FROM sys.views
ORDER BY name;
```

**Expected views:**
- `vw_VehicleCurrentStatus`
- `vw_IdleVehicles`
- `vw_DailyStatistics`
- `vw_AlertsSummary`

### Check Table Distributions
```sql
SELECT
    t.name AS TableName,
    tp.distribution_policy_desc AS DistributionType,
    c.name AS DistributionColumn
FROM sys.tables t
JOIN sys.pdw_table_distribution_properties tp ON t.object_id = tp.object_id
LEFT JOIN sys.pdw_table_mappings tm ON t.object_id = tm.object_id
LEFT JOIN sys.pdw_nodes_tables nt ON tm.physical_name = nt.name
LEFT JOIN sys.pdw_column_distribution_properties cdp ON nt.object_id = cdp.object_id AND cdp.distribution_ordinal = 1
LEFT JOIN sys.columns c ON t.object_id = c.object_id AND cdp.column_id = c.column_id
ORDER BY t.name;
```

---

## Testing the Setup

### 1. Insert Test Data into Staging
```sql
-- Insert a test record
INSERT INTO dbo.VehicleTelemetry_Staging (
    VehicleID, RecordedTimestamp, Latitude, Longitude,
    Speed, FuelLevel, EngineTemp, Status
)
VALUES (
    'TEST001', GETDATE(), 40.7128, -74.0060,
    65.5, 75.0, 85.0, 'moving'
);

-- Verify insert
SELECT * FROM dbo.VehicleTelemetry_Staging;
```

### 2. Test Merge Stored Procedure
```sql
-- Execute merge procedure
EXEC dbo.sp_MergeVehicleTelemetry;

-- Check data moved to main table
SELECT * FROM dbo.VehicleTelemetry WHERE VehicleID = 'TEST001';

-- Verify staging table is empty
SELECT COUNT(*) FROM dbo.VehicleTelemetry_Staging;
```

### 3. Test Data Validation
```sql
-- Insert invalid data
INSERT INTO dbo.VehicleTelemetry_Staging (
    VehicleID, RecordedTimestamp, Speed, FuelLevel, EngineTemp, Status
)
VALUES (
    'TEST002', GETDATE(), -10, 150, 300, 'moving'  -- Invalid values
);

-- Run validation
DECLARE @IsValid BIT, @ErrorMessage NVARCHAR(MAX);
EXEC dbo.sp_ValidateDataQuality
    @TableName = 'VehicleTelemetry_Staging',
    @IsValid = @IsValid OUTPUT,
    @ErrorMessage = @ErrorMessage OUTPUT;

-- Check results
SELECT @IsValid AS IsValid, @ErrorMessage AS ErrorMessage;
```

### 4. Clean Up Test Data
```sql
-- Remove test data
DELETE FROM dbo.VehicleTelemetry WHERE VehicleID LIKE 'TEST%';
TRUNCATE TABLE dbo.VehicleTelemetry_Staging;
```

---

## Schema Design

### Data Model

```
┌──────────────────────────────────────────────┐
│             STAR SCHEMA DESIGN               │
└──────────────────────────────────────────────┘

Fact Table (HASH Distribution on VehicleID):
┌───────────────────────┐
│ VehicleTelemetry      │
├───────────────────────┤
│ TelemetryID (PK)      │
│ VehicleID             │◀─┐
│ RecordedTimestamp     │  │
│ Latitude              │  │
│ Longitude             │  │
│ Speed                 │  │
│ FuelLevel             │  │
│ EngineTemp            │  │
│ Status                │  │
│ AlertType             │  │
│ LoadTimestamp         │  │
└───────────────────────┘  │
                           │
Staging Table (ROUND_ROBIN Distribution):    │
┌───────────────────────┐  │
│ VehicleTelemetry_     │  │
│ Staging               │  │
├───────────────────────┤  │
│ (Same columns as      │  │
│  main fact table)     │  │
└───────────────────────┘  │
                           │
Optional Dimension Tables: │
┌───────────────────────┐  │
│ DimVehicle (Replicated│  │
├───────────────────────┤  │
│ VehicleKey (PK)       │──┘
│ VehicleID             │
│ VehicleType           │
│ Model                 │
│ RegistrationDate      │
└───────────────────────┘
```

### Distribution Strategies

**HASH Distribution** (VehicleTelemetry):
- Used for large fact tables
- Distributes data across 60 compute nodes
- Hash on VehicleID ensures related data co-located
- Best for queries filtering/joining on VehicleID

**ROUND_ROBIN Distribution** (Staging tables):
- Used for temporary/staging tables
- Evenly distributes data across nodes
- Fast loading performance
- No join optimization needed

**REPLICATED Distribution** (Dimension tables):
- Used for small lookup tables (< 2 GB)
- Full copy on every compute node
- Eliminates data movement during joins
- Best for dimension tables

### Index Strategy

**Clustered Columnstore Index** (default for all tables):
- Excellent compression (5-10x)
- Optimized for analytical queries
- Best for batch inserts (> 1 million rows)

**Nonclustered Indexes** (selective use):
- Created on frequently filtered columns (VehicleID, RecordedTimestamp)
- Improves point lookup queries
- Trade-off: Slower inserts/updates

---

## Troubleshooting

### Issue 1: "Login failed for user 'sqladmin'"

**Cause:** Incorrect password or firewall blocking connection

**Solution:**
1. Verify password from ARM template deployment
2. Check firewall rules:
   ```bash
   az synapse workspace firewall-rule list \
     --workspace-name <workspace-name> \
     --resource-group kafka-tutorials-rg
   ```
3. Add your IP if missing (see Firewall Access section above)

---

### Issue 2: "Database 'VehicleDataWarehouse' does not exist"

**Cause:** SQL Pool not created or wrong database name

**Solution:**
1. Check SQL pool exists:
   ```bash
   az synapse sql pool show \
     --name VehicleDataWarehouse \
     --workspace-name <workspace-name> \
     --resource-group kafka-tutorials-rg
   ```
2. Verify you're connecting to the dedicated pool, not master database

---

### Issue 3: "The service is currently busy. Please try again later"

**Cause:** SQL pool is paused or resuming

**Solution:**
1. Check SQL pool status:
   ```bash
   az synapse sql pool show \
     --name VehicleDataWarehouse \
     --workspace-name <workspace-name> \
     --resource-group kafka-tutorials-rg \
     --query status
   ```
2. Resume if paused:
   ```bash
   az synapse sql pool resume \
     --name VehicleDataWarehouse \
     --workspace-name <workspace-name> \
     --resource-group kafka-tutorials-rg
   ```
3. Wait 1-2 minutes for pool to fully resume

---

### Issue 4: "CREATE TABLE permission denied"

**Cause:** User doesn't have required permissions

**Solution:**
Connect as SQL admin (`sqladmin`) or grant permissions:
```sql
-- Run as admin
CREATE USER [adf-managed-identity] FROM EXTERNAL PROVIDER;
GRANT CREATE TABLE TO [adf-managed-identity];
GRANT ALTER ON SCHEMA::dbo TO [adf-managed-identity];
```

---

### Issue 5: "Tables created but queries are slow"

**Cause:** Missing statistics on tables

**Solution:**
Create statistics on frequently queried columns:
```sql
-- Manually create statistics
CREATE STATISTICS stat_VehicleTelemetry_VehicleID
ON dbo.VehicleTelemetry (VehicleID);

CREATE STATISTICS stat_VehicleTelemetry_RecordedTimestamp
ON dbo.VehicleTelemetry (RecordedTimestamp);

-- Or update all statistics
UPDATE STATISTICS dbo.VehicleTelemetry;
```

---

## Cost Management

### Pause SQL Pool When Not in Use

**Save ~$28.80/day ($864/month) by pausing DW100c:**

```bash
# Pause
az synapse sql pool pause \
  --name VehicleDataWarehouse \
  --workspace-name <workspace-name> \
  --resource-group kafka-tutorials-rg

# Resume when needed
az synapse sql pool resume \
  --name VehicleDataWarehouse \
  --workspace-name <workspace-name> \
  --resource-group kafka-tutorials-rg
```

**Best Practice:**
- Pause after completing lab exercises
- Resume only when actively working
- Use serverless SQL pool for ad-hoc queries during development

---

## Next Steps

After successfully setting up the Synapse database:

1. **Configure ADF Linked Service** (if not done):
   - See: `module-4-kafka-connect/lab/adf-pipelines/README.md`
   - Create linked service to Synapse using managed identity

2. **Test ADF Pipelines**:
   - Deploy simple copy pipeline
   - Test data flow from Blob → Synapse

3. **Monitor Pipeline**:
   - Check ADF pipeline runs
   - Query Synapse to verify data loaded
   - Review PipelineLog table for audit trail

4. **Connect BI Tools**:
   - Power BI Desktop: Connect to Synapse SQL endpoint
   - Create reports and dashboards
   - Share with stakeholders

---

## Additional Resources

- [Azure Synapse Analytics Documentation](https://learn.microsoft.com/en-us/azure/synapse-analytics/)
- [T-SQL Reference for Synapse](https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-reference-tsql-statements)
- [Best Practices for Dedicated SQL Pools](https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-best-practices)
- [Distribution Design Guidance](https://learn.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-tables-distribute)

---

**Last Updated**: November 18, 2025
**Module 6**: Complete Pipeline with Azure Synapse Integration
**Maintained By**: Codebasics Kafka Tutorials Team
