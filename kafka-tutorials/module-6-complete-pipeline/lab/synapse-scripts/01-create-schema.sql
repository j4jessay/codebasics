-- ============================================================================
-- Script: 01-create-schema.sql
-- Purpose: Configure database settings and create schemas for Synapse
-- Database: VehicleDataWarehouse (Dedicated SQL Pool)
-- Execution Time: < 1 minute
-- ============================================================================

PRINT 'Starting Synapse database configuration...';
GO

-- ============================================================================
-- STEP 1: Enable Result Set Caching (Performance Optimization)
-- ============================================================================

PRINT 'Configuring result set caching...';

-- Enable result set caching at database level
-- This caches query results for repeated queries (up to 1 TB cache)
ALTER DATABASE SCOPED CONFIGURATION
SET RESULT_SET_CACHING = ON;

PRINT '✓ Result set caching enabled';
GO

-- ============================================================================
-- STEP 2: Configure Query Store (Optional - for query performance monitoring)
-- ============================================================================

PRINT 'Configuring Query Store...';

-- Enable Query Store for query performance insights
ALTER DATABASE [VehicleDataWarehouse]
SET QUERY_STORE = ON
(
    OPERATION_MODE = READ_WRITE,
    CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30),
    DATA_FLUSH_INTERVAL_SECONDS = 900,
    INTERVAL_LENGTH_MINUTES = 60,
    MAX_STORAGE_SIZE_MB = 1000,
    QUERY_CAPTURE_MODE = AUTO
);

PRINT '✓ Query Store enabled';
GO

-- ============================================================================
-- STEP 3: Create Custom Schemas (Optional)
-- ============================================================================

PRINT 'Creating schemas...';

-- Use default dbo schema for simplicity
-- Uncomment below to create separate schemas for staging, analytics, etc.

/*
-- Staging schema for temporary/intermediate tables
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'staging')
BEGIN
    EXEC('CREATE SCHEMA staging');
    PRINT '✓ Schema [staging] created';
END
ELSE
BEGIN
    PRINT '  Schema [staging] already exists';
END
GO

-- Analytics schema for views and aggregated tables
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'analytics')
BEGIN
    EXEC('CREATE SCHEMA analytics');
    PRINT '✓ Schema [analytics] created';
END
ELSE
BEGIN
    PRINT '  Schema [analytics] already exists';
END
GO

-- Audit schema for logging tables
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'audit')
BEGIN
    EXEC('CREATE SCHEMA audit');
    PRINT '✓ Schema [audit] created';
END
ELSE
BEGIN
    PRINT '  Schema [audit] already exists';
END
GO
*/

PRINT '  Using default [dbo] schema';
GO

-- ============================================================================
-- STEP 4: Grant Permissions to Azure Data Factory Managed Identity
-- ============================================================================

PRINT 'Configuring permissions for Azure Data Factory...';

-- Replace '<your-adf-name>' with your actual Data Factory name
-- Example: 'kafka-etl-adf-dev'
DECLARE @ADF_NAME NVARCHAR(100) = '<your-adf-name>';

-- Check if ADF user already exists
IF NOT EXISTS (
    SELECT * FROM sys.database_principals
    WHERE name = @ADF_NAME AND type = 'E'
)
BEGIN
    -- Create user for ADF managed identity
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = 'CREATE USER [' + @ADF_NAME + '] FROM EXTERNAL PROVIDER';
    EXEC sp_executesql @SQL;

    PRINT '✓ Created user for ADF managed identity: ' + @ADF_NAME;
END
ELSE
BEGIN
    PRINT '  User already exists: ' + @ADF_NAME;
END
GO

-- Grant necessary permissions to ADF
-- These permissions allow ADF to read, write, and execute stored procedures

DECLARE @ADF_NAME NVARCHAR(100) = '<your-adf-name>';
DECLARE @SQL NVARCHAR(MAX);

-- Grant SELECT permission (read data)
SET @SQL = 'GRANT SELECT ON SCHEMA::dbo TO [' + @ADF_NAME + ']';
EXEC sp_executesql @SQL;
PRINT '✓ Granted SELECT permission';

-- Grant INSERT permission (write data)
SET @SQL = 'GRANT INSERT ON SCHEMA::dbo TO [' + @ADF_NAME + ']';
EXEC sp_executesql @SQL;
PRINT '✓ Granted INSERT permission';

-- Grant UPDATE permission (modify data)
SET @SQL = 'GRANT UPDATE ON SCHEMA::dbo TO [' + @ADF_NAME + ']';
EXEC sp_executesql @SQL;
PRINT '✓ Granted UPDATE permission';

-- Grant DELETE permission (remove data)
SET @SQL = 'GRANT DELETE ON SCHEMA::dbo TO [' + @ADF_NAME + ']';
EXEC sp_executesql @SQL;
PRINT '✓ Granted DELETE permission';

-- Grant EXECUTE permission (run stored procedures)
SET @SQL = 'GRANT EXECUTE ON SCHEMA::dbo TO [' + @ADF_NAME + ']';
EXEC sp_executesql @SQL;
PRINT '✓ Granted EXECUTE permission';

-- Grant CREATE TABLE permission (if ADF needs to create temp tables)
SET @SQL = 'GRANT CREATE TABLE TO [' + @ADF_NAME + ']';
EXEC sp_executesql @SQL;
PRINT '✓ Granted CREATE TABLE permission';

PRINT '✓ All permissions granted to ADF managed identity';
GO

-- ============================================================================
-- STEP 5: Create Watermark Tracking Table
-- ============================================================================

PRINT 'Creating watermark tracking table...';

-- Watermark table tracks last loaded timestamp for incremental loads
IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[Watermark]')
    AND type = 'U'
)
BEGIN
    CREATE TABLE [dbo].[Watermark]
    (
        TableName NVARCHAR(100) NOT NULL,
        WatermarkValue DATETIME2 NOT NULL,
        LastUpdateTime DATETIME2 NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_Watermark PRIMARY KEY NONCLUSTERED (TableName)
    )
    WITH
    (
        DISTRIBUTION = REPLICATED,  -- Small table, replicate to all nodes
        HEAP  -- No clustered index needed for tiny table
    );

    -- Insert initial watermark for VehicleTelemetry
    INSERT INTO [dbo].[Watermark] (TableName, WatermarkValue, LastUpdateTime)
    VALUES ('VehicleTelemetry', '1900-01-01', GETDATE());

    PRINT '✓ Watermark table created and initialized';
END
ELSE
BEGIN
    PRINT '  Watermark table already exists';
END
GO

-- ============================================================================
-- STEP 6: Verify Configuration
-- ============================================================================

PRINT '';
PRINT '========================================';
PRINT 'Configuration Summary';
PRINT '========================================';

-- Check result set caching
SELECT
    'Result Set Caching' AS Setting,
    CASE
        WHEN is_result_set_caching_on = 1 THEN 'Enabled ✓'
        ELSE 'Disabled'
    END AS Status
FROM sys.databases
WHERE name = DB_NAME();

-- Check Query Store
SELECT
    'Query Store' AS Setting,
    CASE actual_state_desc
        WHEN 'READ_WRITE' THEN 'Enabled ✓'
        WHEN 'READ_ONLY' THEN 'Read-Only'
        ELSE 'Disabled'
    END AS Status
FROM sys.database_query_store_options;

-- List all schemas
PRINT '';
PRINT 'Available Schemas:';
SELECT
    name AS SchemaName,
    SCHEMA_ID(name) AS SchemaID
FROM sys.schemas
WHERE name IN ('dbo', 'staging', 'analytics', 'audit')
ORDER BY name;

-- List database users and their permissions
PRINT '';
PRINT 'Database Users:';
SELECT
    dp.name AS UserName,
    dp.type_desc AS UserType,
    dp.create_date AS CreatedDate
FROM sys.database_principals dp
WHERE dp.type IN ('E', 'S', 'U')  -- External, SQL, Windows users
    AND dp.name NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys')
ORDER BY dp.name;

PRINT '';
PRINT '========================================';
PRINT 'Schema configuration completed successfully!';
PRINT 'Next step: Execute 02-create-tables.sql';
PRINT '========================================';
GO

-- ============================================================================
-- USAGE NOTES
-- ============================================================================

/*
IMPORTANT: Update ADF Managed Identity Name

Before executing this script, replace '<your-adf-name>' with your actual
Azure Data Factory name in STEP 4.

To find your ADF name:
1. Run in bash/terminal:
   az datafactory show \
     --resource-group kafka-tutorials-rg \
     --name <your-adf-name> \
     --query name -o tsv

2. Or check your deployment-config.txt file from ARM template deployment

Example:
   DECLARE @ADF_NAME NVARCHAR(100) = 'kafka-etl-adf-dev';

If you don't configure ADF managed identity permissions, ADF pipelines will
fail with "permission denied" errors when trying to load data.

ALTERNATIVE: Skip ADF permissions during initial setup
If you're not ready to configure ADF yet, you can skip STEP 4 and grant
permissions later using:
   GRANT CONTROL ON SCHEMA::dbo TO [your-adf-name];
*/
