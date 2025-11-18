-- ============================================================================
-- Script: 03-stored-procedures.sql
-- Purpose: Create stored procedures for ETL operations
-- Database: VehicleDataWarehouse (Dedicated SQL Pool)
-- Execution Time: < 1 minute
-- ============================================================================

PRINT 'Starting stored procedure creation...';
PRINT '';
GO

-- ============================================================================
-- PROCEDURE 1: sp_MergeVehicleTelemetry
-- Purpose: Merge data from staging table to main fact table with validation
-- ============================================================================

PRINT '========================================';
PRINT 'Creating sp_MergeVehicleTelemetry';
PRINT '========================================';

-- Drop procedure if exists
IF OBJECT_ID('[dbo].[sp_MergeVehicleTelemetry]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[sp_MergeVehicleTelemetry];
GO

CREATE PROCEDURE [dbo].[sp_MergeVehicleTelemetry]
    @BatchID NVARCHAR(100) = NULL,
    @RowsInserted INT OUTPUT,
    @RowsUpdated INT OUTPUT,
    @RowsDeleted INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    DECLARE @StartTime DATETIME2 = GETDATE();

    BEGIN TRY
        -- Initialize output parameters
        SET @RowsInserted = 0;
        SET @RowsUpdated = 0;
        SET @RowsDeleted = 0;

        PRINT 'Starting merge operation...';
        PRINT 'Batch ID: ' + ISNULL(@BatchID, 'NULL');

        -- Step 1: Data Validation - Remove invalid records from staging
        PRINT 'Step 1: Validating data...';

        DELETE FROM [dbo].[VehicleTelemetry_Staging]
        WHERE
            -- Invalid speed (must be between 0 and 250 km/h)
            Speed < 0 OR Speed > 250
            -- Invalid fuel level (must be between 0 and 100%)
            OR FuelLevel < 0 OR FuelLevel > 100
            -- Invalid engine temperature (must be between -50 and 200°C)
            OR EngineTemp < -50 OR EngineTemp > 200
            -- Missing required fields
            OR VehicleID IS NULL
            OR RecordedTimestamp IS NULL;

        SET @RowsDeleted = @@ROWCOUNT;

        IF @RowsDeleted > 0
            PRINT '  ⚠ Removed ' + CAST(@RowsDeleted AS NVARCHAR(10)) + ' invalid records from staging';
        ELSE
            PRINT '  ✓ All records are valid';

        -- Step 2: Remove duplicates from staging (keep latest by timestamp)
        PRINT 'Step 2: Removing duplicates...';

        WITH CTE_Duplicates AS (
            SELECT *,
                ROW_NUMBER() OVER (
                    PARTITION BY VehicleID, RecordedTimestamp
                    ORDER BY RecordedTimestamp DESC
                ) AS RowNum
            FROM [dbo].[VehicleTelemetry_Staging]
        )
        DELETE FROM CTE_Duplicates WHERE RowNum > 1;

        DECLARE @DuplicatesRemoved INT = @@ROWCOUNT;
        IF @DuplicatesRemoved > 0
            PRINT '  ⚠ Removed ' + CAST(@DuplicatesRemoved AS NVARCHAR(10)) + ' duplicate records';
        ELSE
            PRINT '  ✓ No duplicates found';

        -- Step 3: Merge staging data into main table (UPSERT)
        PRINT 'Step 3: Merging data into main table...';

        -- Since MERGE is not supported in Synapse, use INSERT + UPDATE pattern
        -- First, UPDATE existing records
        UPDATE t
        SET
            t.Latitude = s.Latitude,
            t.Longitude = s.Longitude,
            t.Speed = s.Speed,
            t.FuelLevel = s.FuelLevel,
            t.EngineTemp = s.EngineTemp,
            t.Status = s.Status,
            t.AlertType = s.AlertType,
            t.LoadTimestamp = GETDATE(),
            t.SourceFileName = s.SourceFileName,
            t.BatchID = ISNULL(@BatchID, s.BatchID)
        FROM [dbo].[VehicleTelemetry] t
        INNER JOIN [dbo].[VehicleTelemetry_Staging] s
            ON t.VehicleID = s.VehicleID
            AND t.RecordedTimestamp = s.RecordedTimestamp;

        SET @RowsUpdated = @@ROWCOUNT;
        PRINT '  ✓ Updated ' + CAST(@RowsUpdated AS NVARCHAR(10)) + ' existing records';

        -- Then, INSERT new records
        INSERT INTO [dbo].[VehicleTelemetry] (
            VehicleID,
            RecordedTimestamp,
            Latitude,
            Longitude,
            Speed,
            FuelLevel,
            EngineTemp,
            Status,
            AlertType,
            LoadTimestamp,
            SourceFileName,
            BatchID
        )
        SELECT
            s.VehicleID,
            s.RecordedTimestamp,
            s.Latitude,
            s.Longitude,
            s.Speed,
            s.FuelLevel,
            s.EngineTemp,
            s.Status,
            s.AlertType,
            GETDATE() AS LoadTimestamp,
            s.SourceFileName,
            ISNULL(@BatchID, s.BatchID) AS BatchID
        FROM [dbo].[VehicleTelemetry_Staging] s
        WHERE NOT EXISTS (
            SELECT 1
            FROM [dbo].[VehicleTelemetry] t
            WHERE t.VehicleID = s.VehicleID
                AND t.RecordedTimestamp = s.RecordedTimestamp
        );

        SET @RowsInserted = @@ROWCOUNT;
        PRINT '  ✓ Inserted ' + CAST(@RowsInserted AS NVARCHAR(10)) + ' new records';

        -- Step 4: Truncate staging table
        PRINT 'Step 4: Cleaning up staging table...';
        TRUNCATE TABLE [dbo].[VehicleTelemetry_Staging];
        PRINT '  ✓ Staging table truncated';

        -- Step 5: Update statistics on main table
        PRINT 'Step 5: Updating statistics...';
        UPDATE STATISTICS [dbo].[VehicleTelemetry];
        PRINT '  ✓ Statistics updated';

        DECLARE @EndTime DATETIME2 = GETDATE();
        DECLARE @DurationSeconds INT = DATEDIFF(SECOND, @StartTime, @EndTime);

        PRINT '';
        PRINT '========================================';
        PRINT 'Merge completed successfully!';
        PRINT '========================================';
        PRINT 'Summary:';
        PRINT '  - Rows inserted: ' + CAST(@RowsInserted AS NVARCHAR(10));
        PRINT '  - Rows updated: ' + CAST(@RowsUpdated AS NVARCHAR(10));
        PRINT '  - Rows rejected: ' + CAST(@RowsDeleted AS NVARCHAR(10));
        PRINT '  - Duration: ' + CAST(@DurationSeconds AS NVARCHAR(10)) + ' seconds';
        PRINT '';

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorState = ERROR_STATE();

        PRINT '';
        PRINT '========================================';
        PRINT 'ERROR: Merge operation failed';
        PRINT '========================================';
        PRINT 'Error Message: ' + @ErrorMessage;
        PRINT 'Error Severity: ' + CAST(@ErrorSeverity AS NVARCHAR(10));
        PRINT 'Error State: ' + CAST(@ErrorState AS NVARCHAR(10));

        -- Re-throw error to caller
        THROW;
    END CATCH
END;
GO

PRINT '✓ Created procedure: sp_MergeVehicleTelemetry';
PRINT '';
GO

-- ============================================================================
-- PROCEDURE 2: sp_ValidateDataQuality
-- Purpose: Validate data quality in a table and log results
-- ============================================================================

PRINT '========================================';
PRINT 'Creating sp_ValidateDataQuality';
PRINT '========================================';

IF OBJECT_ID('[dbo].[sp_ValidateDataQuality]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[sp_ValidateDataQuality];
GO

CREATE PROCEDURE [dbo].[sp_ValidateDataQuality]
    @TableName NVARCHAR(100),
    @IsValid BIT OUTPUT,
    @ErrorMessage NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @TotalRows INT;
    DECLARE @InvalidRows INT;
    DECLARE @ValidationResults TABLE (
        RuleName NVARCHAR(200),
        FailedRows INT
    );

    BEGIN TRY
        SET @IsValid = 1;  -- Assume valid until proven otherwise
        SET @ErrorMessage = '';

        PRINT 'Starting data quality validation for table: ' + @TableName;

        -- Get total row count
        SET @SQL = N'SELECT @TotalRows = COUNT(*) FROM [dbo].[' + @TableName + ']';
        EXEC sp_executesql @SQL, N'@TotalRows INT OUTPUT', @TotalRows OUTPUT;

        PRINT 'Total rows: ' + CAST(@TotalRows AS NVARCHAR(10));

        -- Rule 1: Check for NULL VehicleIDs
        SET @SQL = N'SELECT @InvalidRows = COUNT(*) FROM [dbo].[' + @TableName + '] WHERE VehicleID IS NULL';
        EXEC sp_executesql @SQL, N'@InvalidRows INT OUTPUT', @InvalidRows OUTPUT;

        IF @InvalidRows > 0
        BEGIN
            INSERT INTO @ValidationResults VALUES ('NULL VehicleID', @InvalidRows);
            SET @IsValid = 0;
        END

        -- Rule 2: Check for invalid Speed values
        SET @SQL = N'SELECT @InvalidRows = COUNT(*) FROM [dbo].[' + @TableName + '] WHERE Speed < 0 OR Speed > 250';
        EXEC sp_executesql @SQL, N'@InvalidRows INT OUTPUT', @InvalidRows OUTPUT;

        IF @InvalidRows > 0
        BEGIN
            INSERT INTO @ValidationResults VALUES ('Invalid Speed (< 0 or > 250)', @InvalidRows);
            SET @IsValid = 0;
        END

        -- Rule 3: Check for invalid FuelLevel values
        SET @SQL = N'SELECT @InvalidRows = COUNT(*) FROM [dbo].[' + @TableName + '] WHERE FuelLevel < 0 OR FuelLevel > 100';
        EXEC sp_executesql @SQL, N'@InvalidRows INT OUTPUT', @InvalidRows OUTPUT;

        IF @InvalidRows > 0
        BEGIN
            INSERT INTO @ValidationResults VALUES ('Invalid FuelLevel (< 0 or > 100)', @InvalidRows);
            SET @IsValid = 0;
        END

        -- Rule 4: Check for invalid EngineTemp values
        SET @SQL = N'SELECT @InvalidRows = COUNT(*) FROM [dbo].[' + @TableName + '] WHERE EngineTemp < -50 OR EngineTemp > 200';
        EXEC sp_executesql @SQL, N'@InvalidRows INT OUTPUT', @InvalidRows OUTPUT;

        IF @InvalidRows > 0
        BEGIN
            INSERT INTO @ValidationResults VALUES ('Invalid EngineTemp (< -50 or > 200)', @InvalidRows);
            SET @IsValid = 0;
        END

        -- Rule 5: Check for future timestamps
        SET @SQL = N'SELECT @InvalidRows = COUNT(*) FROM [dbo].[' + @TableName + '] WHERE RecordedTimestamp > GETDATE()';
        EXEC sp_executesql @SQL, N'@InvalidRows INT OUTPUT', @InvalidRows OUTPUT;

        IF @InvalidRows > 0
        BEGIN
            INSERT INTO @ValidationResults VALUES ('Future timestamps', @InvalidRows);
            SET @IsValid = 0;
        END

        -- Log results to DataQualityLog table
        IF EXISTS (SELECT 1 FROM @ValidationResults)
        BEGIN
            INSERT INTO [dbo].[DataQualityLog] (
                TableName,
                ValidationRule,
                FailedRows,
                TotalRows,
                FailurePercentage,
                ErrorDetails
            )
            SELECT
                @TableName,
                RuleName,
                FailedRows,
                @TotalRows,
                CAST((FailedRows * 100.0 / NULLIF(@TotalRows, 0)) AS DECIMAL(5, 2)),
                'Validation failed: ' + CAST(FailedRows AS NVARCHAR(10)) + ' out of ' + CAST(@TotalRows AS NVARCHAR(10)) + ' rows failed'
            FROM @ValidationResults;

            -- Build error message
            SELECT @ErrorMessage = @ErrorMessage + RuleName + ': ' + CAST(FailedRows AS NVARCHAR(10)) + ' rows; '
            FROM @ValidationResults;

            PRINT '';
            PRINT 'Validation FAILED:';
            SELECT * FROM @ValidationResults;
        END
        ELSE
        BEGIN
            PRINT 'Validation PASSED: All data quality checks passed ✓';
        END

    END TRY
    BEGIN CATCH
        SET @IsValid = 0;
        SET @ErrorMessage = ERROR_MESSAGE();
        PRINT 'ERROR during validation: ' + @ErrorMessage;
        THROW;
    END CATCH
END;
GO

PRINT '✓ Created procedure: sp_ValidateDataQuality';
PRINT '';
GO

-- ============================================================================
-- PROCEDURE 3: sp_LogPipelineRun
-- Purpose: Log pipeline execution details for audit trail
-- ============================================================================

PRINT '========================================';
PRINT 'Creating sp_LogPipelineRun';
PRINT '========================================';

IF OBJECT_ID('[dbo].[sp_LogPipelineRun]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[sp_LogPipelineRun];
GO

CREATE PROCEDURE [dbo].[sp_LogPipelineRun]
    @PipelineName NVARCHAR(200),
    @RunID NVARCHAR(100),
    @ActivityName NVARCHAR(200) = NULL,
    @TableName NVARCHAR(100) = NULL,
    @StartTime DATETIME2,
    @EndTime DATETIME2 = NULL,
    @Status NVARCHAR(50),  -- 'Success', 'Failed', 'In Progress'
    @RowsRead INT = NULL,
    @RowsWritten INT = NULL,
    @RowsRejected INT = NULL,
    @ErrorMessage NVARCHAR(MAX) = NULL,
    @LogID BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO [dbo].[PipelineLog] (
            PipelineName,
            RunID,
            ActivityName,
            TableName,
            StartTime,
            EndTime,
            Status,
            RowsRead,
            RowsWritten,
            RowsRejected,
            ErrorMessage
        )
        VALUES (
            @PipelineName,
            @RunID,
            @ActivityName,
            @TableName,
            @StartTime,
            @EndTime,
            @Status,
            @RowsRead,
            @RowsWritten,
            @RowsRejected,
            @ErrorMessage
        );

        SET @LogID = SCOPE_IDENTITY();

        PRINT 'Pipeline run logged successfully';
        PRINT '  - LogID: ' + CAST(@LogID AS NVARCHAR(20));
        PRINT '  - Pipeline: ' + @PipelineName;
        PRINT '  - Status: ' + @Status;

    END TRY
    BEGIN CATCH
        PRINT 'ERROR: Failed to log pipeline run - ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

PRINT '✓ Created procedure: sp_LogPipelineRun';
PRINT '';
GO

-- ============================================================================
-- PROCEDURE 4: sp_GetWatermark
-- Purpose: Get the last loaded timestamp for incremental loads
-- ============================================================================

PRINT '========================================';
PRINT 'Creating sp_GetWatermark';
PRINT '========================================';

IF OBJECT_ID('[dbo].[sp_GetWatermark]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[sp_GetWatermark];
GO

CREATE PROCEDURE [dbo].[sp_GetWatermark]
    @TableName NVARCHAR(100),
    @WatermarkValue DATETIME2 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT @WatermarkValue = WatermarkValue
        FROM [dbo].[Watermark]
        WHERE TableName = @TableName;

        IF @WatermarkValue IS NULL
        BEGIN
            -- If no watermark exists, return minimum date
            SET @WatermarkValue = '1900-01-01';

            -- Insert default watermark
            INSERT INTO [dbo].[Watermark] (TableName, WatermarkValue)
            VALUES (@TableName, @WatermarkValue);

            PRINT 'No watermark found for ' + @TableName + ', initialized to ' + CAST(@WatermarkValue AS NVARCHAR(30));
        END
        ELSE
        BEGIN
            PRINT 'Watermark for ' + @TableName + ': ' + CAST(@WatermarkValue AS NVARCHAR(30));
        END

    END TRY
    BEGIN CATCH
        PRINT 'ERROR: Failed to get watermark - ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

PRINT '✓ Created procedure: sp_GetWatermark';
PRINT '';
GO

-- ============================================================================
-- PROCEDURE 5: sp_UpdateWatermark
-- Purpose: Update the watermark after successful data load
-- ============================================================================

PRINT '========================================';
PRINT 'Creating sp_UpdateWatermark';
PRINT '========================================';

IF OBJECT_ID('[dbo].[sp_UpdateWatermark]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[sp_UpdateWatermark];
GO

CREATE PROCEDURE [dbo].[sp_UpdateWatermark]
    @TableName NVARCHAR(100),
    @NewWatermarkValue DATETIME2
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Update existing watermark
        UPDATE [dbo].[Watermark]
        SET
            WatermarkValue = @NewWatermarkValue,
            LastUpdateTime = GETDATE()
        WHERE TableName = @TableName;

        -- If no rows updated, insert new watermark
        IF @@ROWCOUNT = 0
        BEGIN
            INSERT INTO [dbo].[Watermark] (TableName, WatermarkValue, LastUpdateTime)
            VALUES (@TableName, @NewWatermarkValue, GETDATE());

            PRINT 'Watermark created for ' + @TableName;
        END
        ELSE
        BEGIN
            PRINT 'Watermark updated for ' + @TableName;
        END

        PRINT '  - New watermark: ' + CAST(@NewWatermarkValue AS NVARCHAR(30));

    END TRY
    BEGIN CATCH
        PRINT 'ERROR: Failed to update watermark - ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

PRINT '✓ Created procedure: sp_UpdateWatermark';
PRINT '';
GO

-- ============================================================================
-- VERIFY PROCEDURE CREATION
-- ============================================================================

PRINT '========================================';
PRINT 'Stored Procedures Summary';
PRINT '========================================';

SELECT
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS ProcedureName,
    create_date AS CreatedDate,
    modify_date AS ModifiedDate
FROM sys.procedures
WHERE name IN (
    'sp_MergeVehicleTelemetry',
    'sp_ValidateDataQuality',
    'sp_LogPipelineRun',
    'sp_GetWatermark',
    'sp_UpdateWatermark'
)
ORDER BY name;
GO

PRINT '';
PRINT '========================================';
PRINT 'Stored procedure creation completed successfully!';
PRINT 'Next step: Execute 04-create-views.sql (optional)';
PRINT '========================================';
GO

-- ============================================================================
-- USAGE EXAMPLES
-- ============================================================================

/*
-- Example 1: Merge staging data into main table
DECLARE @RowsInserted INT, @RowsUpdated INT, @RowsDeleted INT;

EXEC [dbo].[sp_MergeVehicleTelemetry]
    @BatchID = 'BATCH_2025_11_18_001',
    @RowsInserted = @RowsInserted OUTPUT,
    @RowsUpdated = @RowsUpdated OUTPUT,
    @RowsDeleted = @RowsDeleted OUTPUT;

SELECT @RowsInserted AS RowsInserted, @RowsUpdated AS RowsUpdated, @RowsDeleted AS RowsDeleted;

-- Example 2: Validate data quality
DECLARE @IsValid BIT, @ErrorMessage NVARCHAR(MAX);

EXEC [dbo].[sp_ValidateDataQuality]
    @TableName = 'VehicleTelemetry_Staging',
    @IsValid = @IsValid OUTPUT,
    @ErrorMessage = @ErrorMessage OUTPUT;

SELECT @IsValid AS IsValid, @ErrorMessage AS ErrorMessage;

-- Example 3: Log pipeline run
DECLARE @LogID BIGINT;

EXEC [dbo].[sp_LogPipelineRun]
    @PipelineName = 'StagedLoadWithValidation',
    @RunID = NEWID(),
    @ActivityName = 'CopyVehicleTelemetry',
    @TableName = 'VehicleTelemetry',
    @StartTime = GETDATE(),
    @EndTime = GETDATE(),
    @Status = 'Success',
    @RowsRead = 1000,
    @RowsWritten = 995,
    @RowsRejected = 5,
    @LogID = @LogID OUTPUT;

SELECT @LogID AS LogID;

-- Example 4: Get and update watermark
DECLARE @Watermark DATETIME2;

-- Get current watermark
EXEC [dbo].[sp_GetWatermark]
    @TableName = 'VehicleTelemetry',
    @WatermarkValue = @Watermark OUTPUT;

PRINT 'Current watermark: ' + CAST(@Watermark AS NVARCHAR(30));

-- Update watermark after successful load
EXEC [dbo].[sp_UpdateWatermark]
    @TableName = 'VehicleTelemetry',
    @NewWatermarkValue = GETDATE();
*/
