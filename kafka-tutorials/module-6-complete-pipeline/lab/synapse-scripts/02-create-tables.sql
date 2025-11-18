-- ============================================================================
-- Script: 02-create-tables.sql
-- Purpose: Create fact tables, staging tables, and dimension tables
-- Database: VehicleDataWarehouse (Dedicated SQL Pool)
-- Execution Time: < 2 minutes
-- ============================================================================

PRINT 'Starting table creation...';
PRINT '';
GO

-- ============================================================================
-- PART 1: MAIN FACT TABLE - VehicleTelemetry
-- ============================================================================

PRINT '========================================';
PRINT 'Creating Main Fact Table';
PRINT '========================================';

-- Drop table if exists (for dev/testing only - remove in production)
IF OBJECT_ID('[dbo].[VehicleTelemetry]', 'U') IS NOT NULL
BEGIN
    DROP TABLE [dbo].[VehicleTelemetry];
    PRINT 'Dropped existing VehicleTelemetry table';
END
GO

CREATE TABLE [dbo].[VehicleTelemetry]
(
    -- Primary Key (Identity)
    TelemetryID BIGINT IDENTITY(1,1) NOT NULL,

    -- Vehicle Information
    VehicleID NVARCHAR(50) NOT NULL,

    -- Timestamp
    RecordedTimestamp DATETIME2 NOT NULL,

    -- Location Data
    Latitude DECIMAL(10, 7) NULL,      -- Range: -90.0000000 to 90.0000000
    Longitude DECIMAL(10, 7) NULL,     -- Range: -180.0000000 to 180.0000000

    -- Telemetry Metrics
    Speed DECIMAL(5, 2) NULL,          -- Speed in km/h (0.00 to 999.99)
    FuelLevel DECIMAL(5, 2) NULL,      -- Fuel percentage (0.00 to 100.00)
    EngineTemp DECIMAL(5, 2) NULL,     -- Engine temperature in Celsius

    -- Status Fields
    Status NVARCHAR(20) NULL,          -- 'moving', 'idle', 'stopped'
    AlertType NVARCHAR(50) NULL,       -- 'speeding', 'lowfuel', 'overheating', NULL

    -- ETL Audit Fields
    LoadTimestamp DATETIME2 NOT NULL DEFAULT GETDATE(),
    SourceFileName NVARCHAR(500) NULL,
    BatchID NVARCHAR(100) NULL,

    -- Primary Key Constraint
    CONSTRAINT PK_VehicleTelemetry PRIMARY KEY NONCLUSTERED (TelemetryID)
)
WITH
(
    -- HASH distribution on VehicleID for efficient joins and queries
    DISTRIBUTION = HASH(VehicleID),

    -- Clustered Columnstore Index for best compression and query performance
    CLUSTERED COLUMNSTORE INDEX
);
GO

-- Create non-clustered indexes for frequently queried columns
CREATE NONCLUSTERED INDEX IX_VehicleTelemetry_VehicleID_Timestamp
ON [dbo].[VehicleTelemetry] (VehicleID, RecordedTimestamp);
GO

CREATE NONCLUSTERED INDEX IX_VehicleTelemetry_RecordedTimestamp
ON [dbo].[VehicleTelemetry] (RecordedTimestamp);
GO

CREATE NONCLUSTERED INDEX IX_VehicleTelemetry_AlertType
ON [dbo].[VehicleTelemetry] (AlertType)
WHERE AlertType IS NOT NULL;  -- Filtered index for alerts only
GO

-- Create statistics for query optimization
CREATE STATISTICS stat_VehicleTelemetry_VehicleID ON [dbo].[VehicleTelemetry](VehicleID);
CREATE STATISTICS stat_VehicleTelemetry_RecordedTimestamp ON [dbo].[VehicleTelemetry](RecordedTimestamp);
CREATE STATISTICS stat_VehicleTelemetry_Speed ON [dbo].[VehicleTelemetry](Speed);
GO

PRINT '✓ Created table: VehicleTelemetry';
PRINT '  - Distribution: HASH(VehicleID)';
PRINT '  - Index: Clustered Columnstore';
PRINT '  - Non-clustered indexes: 3';
PRINT '  - Statistics: 3';
PRINT '';
GO

-- ============================================================================
-- PART 2: STAGING TABLE - VehicleTelemetry_Staging
-- ============================================================================

PRINT '========================================';
PRINT 'Creating Staging Table';
PRINT '========================================';

-- Drop staging table if exists
IF OBJECT_ID('[dbo].[VehicleTelemetry_Staging]', 'U') IS NOT NULL
BEGIN
    DROP TABLE [dbo].[VehicleTelemetry_Staging];
    PRINT 'Dropped existing VehicleTelemetry_Staging table';
END
GO

CREATE TABLE [dbo].[VehicleTelemetry_Staging]
(
    -- Same columns as main fact table (no identity)
    VehicleID NVARCHAR(50) NOT NULL,
    RecordedTimestamp DATETIME2 NOT NULL,
    Latitude DECIMAL(10, 7) NULL,
    Longitude DECIMAL(10, 7) NULL,
    Speed DECIMAL(5, 2) NULL,
    FuelLevel DECIMAL(5, 2) NULL,
    EngineTemp DECIMAL(5, 2) NULL,
    Status NVARCHAR(20) NULL,
    AlertType NVARCHAR(50) NULL,
    SourceFileName NVARCHAR(500) NULL,
    BatchID NVARCHAR(100) NULL
)
WITH
(
    -- ROUND_ROBIN distribution for fast loading
    DISTRIBUTION = ROUND_ROBIN,

    -- HEAP (no indexes) for fastest insert performance
    HEAP
);
GO

PRINT '✓ Created table: VehicleTelemetry_Staging';
PRINT '  - Distribution: ROUND_ROBIN (fast loading)';
PRINT '  - Index: HEAP (no indexes for fast inserts)';
PRINT '';
GO

-- ============================================================================
-- PART 3: AUDIT TABLE - PipelineLog
-- ============================================================================

PRINT '========================================';
PRINT 'Creating Audit Tables';
PRINT '========================================';

-- Drop table if exists
IF OBJECT_ID('[dbo].[PipelineLog]', 'U') IS NOT NULL
BEGIN
    DROP TABLE [dbo].[PipelineLog];
    PRINT 'Dropped existing PipelineLog table';
END
GO

CREATE TABLE [dbo].[PipelineLog]
(
    LogID BIGINT IDENTITY(1,1) NOT NULL,
    PipelineName NVARCHAR(200) NOT NULL,
    RunID NVARCHAR(100) NOT NULL,
    ActivityName NVARCHAR(200) NULL,
    TableName NVARCHAR(100) NULL,
    StartTime DATETIME2 NOT NULL,
    EndTime DATETIME2 NULL,
    Status NVARCHAR(50) NOT NULL,             -- 'Success', 'Failed', 'In Progress'
    RowsRead INT NULL,
    RowsWritten INT NULL,
    RowsRejected INT NULL,
    ErrorMessage NVARCHAR(MAX) NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_PipelineLog PRIMARY KEY NONCLUSTERED (LogID)
)
WITH
(
    DISTRIBUTION = ROUND_ROBIN,  -- Small audit table, round-robin is fine
    CLUSTERED COLUMNSTORE INDEX
);
GO

CREATE NONCLUSTERED INDEX IX_PipelineLog_RunID ON [dbo].[PipelineLog](RunID);
CREATE NONCLUSTERED INDEX IX_PipelineLog_StartTime ON [dbo].[PipelineLog](StartTime);
GO

PRINT '✓ Created table: PipelineLog';
PRINT '  - Distribution: ROUND_ROBIN';
PRINT '  - Index: Clustered Columnstore + 2 non-clustered';
PRINT '';
GO

-- ============================================================================
-- PART 4: DATA QUALITY LOG TABLE
-- ============================================================================

-- Drop table if exists
IF OBJECT_ID('[dbo].[DataQualityLog]', 'U') IS NOT NULL
BEGIN
    DROP TABLE [dbo].[DataQualityLog];
    PRINT 'Dropped existing DataQualityLog table';
END
GO

CREATE TABLE [dbo].[DataQualityLog]
(
    QualityLogID BIGINT IDENTITY(1,1) NOT NULL,
    TableName NVARCHAR(100) NOT NULL,
    ValidationRule NVARCHAR(200) NOT NULL,
    FailedRows INT NOT NULL,
    TotalRows INT NOT NULL,
    FailurePercentage DECIMAL(5, 2) NULL,
    ValidationTimestamp DATETIME2 NOT NULL DEFAULT GETDATE(),
    ErrorDetails NVARCHAR(MAX) NULL,

    CONSTRAINT PK_DataQualityLog PRIMARY KEY NONCLUSTERED (QualityLogID)
)
WITH
(
    DISTRIBUTION = ROUND_ROBIN,
    CLUSTERED COLUMNSTORE INDEX
);
GO

PRINT '✓ Created table: DataQualityLog';
PRINT '  - Distribution: ROUND_ROBIN';
PRINT '  - Index: Clustered Columnstore';
PRINT '';
GO

-- ============================================================================
-- PART 5: DIMENSION TABLES (OPTIONAL - Star Schema Design)
-- ============================================================================

PRINT '========================================';
PRINT 'Creating Dimension Tables (Optional)';
PRINT '========================================';
PRINT 'These tables support star schema analytics.';
PRINT 'Uncomment to create if needed for your use case.';
PRINT '';

/*
-- ----------------------------------------
-- DimVehicle - Vehicle Master Data
-- ----------------------------------------

IF OBJECT_ID('[dbo].[DimVehicle]', 'U') IS NOT NULL
    DROP TABLE [dbo].[DimVehicle];
GO

CREATE TABLE [dbo].[DimVehicle]
(
    VehicleKey INT IDENTITY(1,1) NOT NULL,
    VehicleID NVARCHAR(50) NOT NULL,
    VehicleType NVARCHAR(50) NULL,            -- 'Sedan', 'SUV', 'Truck', 'Van'
    Model NVARCHAR(100) NULL,
    Manufacturer NVARCHAR(100) NULL,
    Year INT NULL,
    RegistrationDate DATE NULL,
    RegistrationState NVARCHAR(50) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    EffectiveStartDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    EffectiveEndDate DATETIME2 NULL,
    IsCurrent BIT NOT NULL DEFAULT 1,

    CONSTRAINT PK_DimVehicle PRIMARY KEY NONCLUSTERED (VehicleKey),
    CONSTRAINT UQ_DimVehicle_VehicleID UNIQUE (VehicleID)
)
WITH
(
    DISTRIBUTION = REPLICATED,  -- Small dimension, replicate to all nodes
    CLUSTERED COLUMNSTORE INDEX
);
GO

CREATE NONCLUSTERED INDEX IX_DimVehicle_VehicleID ON [dbo].[DimVehicle](VehicleID);
GO

PRINT '✓ Created table: DimVehicle';
PRINT '  - Distribution: REPLICATED (small lookup table)';
PRINT '';

-- ----------------------------------------
-- DimDateTime - Time Dimension
-- ----------------------------------------

IF OBJECT_ID('[dbo].[DimDateTime]', 'U') IS NOT NULL
    DROP TABLE [dbo].[DimDateTime];
GO

CREATE TABLE [dbo].[DimDateTime]
(
    DateTimeKey INT IDENTITY(1,1) NOT NULL,
    Date DATE NOT NULL,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    Month INT NOT NULL,
    MonthName NVARCHAR(20) NOT NULL,
    Day INT NOT NULL,
    DayOfWeek INT NOT NULL,
    DayOfWeekName NVARCHAR(20) NOT NULL,
    IsWeekend BIT NOT NULL,
    Hour INT NOT NULL,
    HourName NVARCHAR(20) NOT NULL,
    IsBusinessHour BIT NOT NULL,

    CONSTRAINT PK_DimDateTime PRIMARY KEY NONCLUSTERED (DateTimeKey)
)
WITH
(
    DISTRIBUTION = REPLICATED,  -- Small dimension, replicate
    CLUSTERED COLUMNSTORE INDEX
);
GO

CREATE NONCLUSTERED INDEX IX_DimDateTime_Date ON [dbo].[DimDateTime](Date);
CREATE NONCLUSTERED INDEX IX_DimDateTime_Year_Month ON [dbo].[DimDateTime](Year, Month);
GO

PRINT '✓ Created table: DimDateTime';
PRINT '  - Distribution: REPLICATED';
PRINT '';

-- ----------------------------------------
-- DimLocation - Location Master Data
-- ----------------------------------------

IF OBJECT_ID('[dbo].[DimLocation]', 'U') IS NOT NULL
    DROP TABLE [dbo].[DimLocation];
GO

CREATE TABLE [dbo].[DimLocation]
(
    LocationKey INT IDENTITY(1,1) NOT NULL,
    Latitude DECIMAL(10, 7) NOT NULL,
    Longitude DECIMAL(10, 7) NOT NULL,
    City NVARCHAR(100) NULL,
    State NVARCHAR(50) NULL,
    Country NVARCHAR(50) NULL,
    Region NVARCHAR(100) NULL,
    LocationType NVARCHAR(50) NULL,           -- 'Highway', 'Urban', 'Rural'

    CONSTRAINT PK_DimLocation PRIMARY KEY NONCLUSTERED (LocationKey)
)
WITH
(
    DISTRIBUTION = HASH(LocationKey),
    CLUSTERED COLUMNSTORE INDEX
);
GO

CREATE NONCLUSTERED INDEX IX_DimLocation_LatLong ON [dbo].[DimLocation](Latitude, Longitude);
GO

PRINT '✓ Created table: DimLocation';
PRINT '  - Distribution: HASH(LocationKey)';
PRINT '';
*/

-- ============================================================================
-- PART 6: VERIFY TABLE CREATION
-- ============================================================================

PRINT '========================================';
PRINT 'Table Creation Summary';
PRINT '========================================';
PRINT '';

-- List all tables created
SELECT
    t.name AS TableName,
    tp.distribution_policy_desc AS DistributionType,
    CASE
        WHEN i.type = 5 THEN 'Clustered Columnstore'
        WHEN i.type = 1 THEN 'Clustered'
        WHEN i.type = 0 THEN 'Heap'
        ELSE 'Other'
    END AS IndexType,
    ps.row_count AS [RowCount],
    CAST(ps.reserved_space_GB AS DECIMAL(10, 2)) AS ReservedSpace_GB
FROM sys.tables t
JOIN sys.pdw_table_distribution_properties tp ON t.object_id = tp.object_id
LEFT JOIN sys.indexes i ON t.object_id = i.object_id AND i.index_id IN (0, 1)
LEFT JOIN (
    SELECT
        object_id,
        SUM(row_count) AS row_count,
        SUM(reserved_space_KB) / 1024.0 / 1024.0 AS reserved_space_GB
    FROM sys.pdw_nodes_db_partition_stats
    GROUP BY object_id
) ps ON t.object_id = ps.object_id
WHERE t.name IN (
    'VehicleTelemetry',
    'VehicleTelemetry_Staging',
    'PipelineLog',
    'DataQualityLog',
    'DimVehicle',
    'DimDateTime',
    'DimLocation'
)
ORDER BY t.name;
GO

PRINT '';
PRINT 'Total Tables Created:';
SELECT COUNT(*) AS TableCount
FROM sys.tables
WHERE name IN (
    'VehicleTelemetry',
    'VehicleTelemetry_Staging',
    'PipelineLog',
    'DataQualityLog',
    'DimVehicle',
    'DimDateTime',
    'DimLocation'
);
GO

PRINT '';
PRINT '========================================';
PRINT 'Table creation completed successfully!';
PRINT 'Next step: Execute 03-stored-procedures.sql';
PRINT '========================================';
GO

-- ============================================================================
-- DESIGN NOTES
-- ============================================================================

/*
DISTRIBUTION STRATEGIES EXPLAINED:

1. HASH Distribution (VehicleTelemetry)
   - Used for large fact tables
   - Distributes rows across 60 compute nodes based on hash of VehicleID
   - Pros: Efficient for joins and queries filtering on VehicleID
   - Cons: Data skew if VehicleID distribution is uneven

2. ROUND_ROBIN Distribution (Staging, Audit tables)
   - Distributes rows evenly across all 60 compute nodes
   - Pros: Fastest loading performance
   - Cons: Requires data movement for joins

3. REPLICATED Distribution (Dimension tables)
   - Full copy of table on every compute node
   - Pros: No data movement for joins, fast lookups
   - Cons: Only suitable for small tables (< 2 GB)

INDEX STRATEGIES:

1. Clustered Columnstore Index (Default)
   - Best for analytical queries (scans, aggregations)
   - Excellent compression (5-10x)
   - Requires batch size > 102,400 rows for best compression
   - Automatic for Synapse tables

2. Non-Clustered Indexes
   - Created on frequently filtered columns (VehicleID, Timestamp)
   - Improves point lookups and range scans
   - Trade-off: Slower inserts/updates

3. Filtered Indexes
   - Index only subset of rows (e.g., AlertType IS NOT NULL)
   - Smaller index size, faster queries on filtered data

STATISTICS:

- Synapse uses statistics for query optimization
- Auto-created on first query, but manual creation is faster
- Update regularly: UPDATE STATISTICS dbo.VehicleTelemetry;
- Critical for optimal query performance

BEST PRACTICES:

1. Always use IDENTITY for surrogate keys
2. Use appropriate data types (DECIMAL for numbers, DATETIME2 for timestamps)
3. Add audit columns (LoadTimestamp, BatchID) to track ETL
4. Create staging tables with HEAP for fast loading
5. Use ROUND_ROBIN for temporary/staging data
6. Use HASH for large fact tables (> 60 million rows)
7. Use REPLICATED for small dimension tables (< 2 GB)
8. Always create statistics on join and filter columns
9. Consider partitioning for very large tables (> 1 billion rows)
10. Monitor distribution skew: SELECT * FROM sys.pdw_nodes_db_partition_stats
*/
