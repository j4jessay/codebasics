-- ============================================================================
-- Script: 04-create-views.sql
-- Purpose: Create analytical views for BI and reporting
-- Database: VehicleDataWarehouse (Dedicated SQL Pool)
-- Execution Time: < 1 minute
-- ============================================================================

PRINT 'Starting view creation...';
PRINT '';
PRINT 'These views provide pre-aggregated data for BI tools like Power BI.';
PRINT 'Views simplify queries and improve performance for common analytics.';
PRINT '';
GO

-- ============================================================================
-- VIEW 1: vw_VehicleCurrentStatus
-- Purpose: Get the latest telemetry data for each vehicle
-- Use Case: Real-time dashboard showing current vehicle status
-- ============================================================================

PRINT '========================================';
PRINT 'Creating vw_VehicleCurrentStatus';
PRINT '========================================';

IF OBJECT_ID('[dbo].[vw_VehicleCurrentStatus]', 'V') IS NOT NULL
    DROP VIEW [dbo].[vw_VehicleCurrentStatus];
GO

CREATE VIEW [dbo].[vw_VehicleCurrentStatus]
AS
WITH LatestTelemetry AS (
    SELECT
        VehicleID,
        MAX(RecordedTimestamp) AS LatestTimestamp
    FROM [dbo].[VehicleTelemetry]
    GROUP BY VehicleID
)
SELECT
    t.VehicleID,
    t.RecordedTimestamp AS LastReportedTime,
    t.Latitude,
    t.Longitude,
    t.Speed AS CurrentSpeed,
    t.FuelLevel AS CurrentFuelLevel,
    t.EngineTemp AS CurrentEngineTemp,
    t.Status,
    t.AlertType AS CurrentAlert,
    DATEDIFF(MINUTE, t.RecordedTimestamp, GETDATE()) AS MinutesSinceLastReport,
    CASE
        WHEN DATEDIFF(MINUTE, t.RecordedTimestamp, GETDATE()) > 30 THEN 'Offline'
        WHEN t.Status = 'stopped' THEN 'Stopped'
        WHEN t.Status = 'idle' THEN 'Idle'
        WHEN t.Status = 'moving' THEN 'Active'
        ELSE 'Unknown'
    END AS VehicleState,
    CASE
        WHEN t.AlertType IS NOT NULL THEN 'Alert'
        WHEN t.FuelLevel < 20 THEN 'Low Fuel Warning'
        WHEN t.EngineTemp > 90 THEN 'High Temperature Warning'
        ELSE 'Normal'
    END AS HealthStatus
FROM [dbo].[VehicleTelemetry] t
INNER JOIN LatestTelemetry lt
    ON t.VehicleID = lt.VehicleID
    AND t.RecordedTimestamp = lt.LatestTimestamp;
GO

PRINT '✓ Created view: vw_VehicleCurrentStatus';
PRINT '  - Use for: Real-time vehicle status dashboard';
PRINT '';
GO

-- ============================================================================
-- VIEW 2: vw_IdleVehicles
-- Purpose: Identify vehicles that have been idle for extended periods
-- Use Case: Fleet management to identify underutilized vehicles
-- ============================================================================

PRINT '========================================';
PRINT 'Creating vw_IdleVehicles';
PRINT '========================================';

IF OBJECT_ID('[dbo].[vw_IdleVehicles]', 'V') IS NOT NULL
    DROP VIEW [dbo].[vw_IdleVehicles];
GO

CREATE VIEW [dbo].[vw_IdleVehicles]
AS
WITH VehicleIdlePeriods AS (
    SELECT
        VehicleID,
        MIN(RecordedTimestamp) AS IdleStartTime,
        MAX(RecordedTimestamp) AS IdleEndTime,
        COUNT(*) AS IdleEventCount,
        AVG(Speed) AS AvgSpeed
    FROM [dbo].[VehicleTelemetry]
    WHERE Speed < 5  -- Speed less than 5 km/h considered idle
        AND Status IN ('idle', 'stopped')
        AND RecordedTimestamp >= DATEADD(DAY, -7, GETDATE())  -- Last 7 days
    GROUP BY VehicleID
)
SELECT
    VehicleID,
    IdleStartTime,
    IdleEndTime,
    DATEDIFF(MINUTE, IdleStartTime, IdleEndTime) AS IdleDurationMinutes,
    CAST(DATEDIFF(MINUTE, IdleStartTime, IdleEndTime) / 60.0 AS DECIMAL(10, 2)) AS IdleDurationHours,
    IdleEventCount,
    AvgSpeed,
    CASE
        WHEN DATEDIFF(MINUTE, IdleStartTime, IdleEndTime) > 240 THEN 'Critical' -- > 4 hours
        WHEN DATEDIFF(MINUTE, IdleStartTime, IdleEndTime) > 120 THEN 'High'    -- > 2 hours
        WHEN DATEDIFF(MINUTE, IdleStartTime, IdleEndTime) > 60 THEN 'Medium'    -- > 1 hour
        ELSE 'Low'
    END AS IdleSeverity
FROM VehicleIdlePeriods
WHERE DATEDIFF(MINUTE, IdleStartTime, IdleEndTime) > 30  -- Only show idle > 30 minutes
;
GO

PRINT '✓ Created view: vw_IdleVehicles';
PRINT '  - Use for: Identify underutilized vehicles';
PRINT '';
GO

-- ============================================================================
-- VIEW 3: vw_DailyStatistics
-- Purpose: Aggregated daily metrics for all vehicles
-- Use Case: Daily fleet performance reports
-- ============================================================================

PRINT '========================================';
PRINT 'Creating vw_DailyStatistics';
PRINT '========================================';

IF OBJECT_ID('[dbo].[vw_DailyStatistics]', 'V') IS NOT NULL
    DROP VIEW [dbo].[vw_DailyStatistics];
GO

CREATE VIEW [dbo].[vw_DailyStatistics]
AS
SELECT
    CAST(RecordedTimestamp AS DATE) AS ReportDate,
    VehicleID,

    -- Trip Statistics
    COUNT(*) AS TotalEvents,
    COUNT(DISTINCT CAST(RecordedTimestamp AS DATE)) AS ActiveDays,

    -- Speed Statistics
    AVG(Speed) AS AvgSpeed,
    MAX(Speed) AS MaxSpeed,
    MIN(Speed) AS MinSpeed,

    -- Fuel Statistics
    AVG(FuelLevel) AS AvgFuelLevel,
    MIN(FuelLevel) AS MinFuelLevel,
    MAX(FuelLevel) AS MaxFuelLevel,
    CAST(MAX(FuelLevel) - MIN(FuelLevel) AS DECIMAL(5, 2)) AS FuelConsumed,

    -- Engine Temperature Statistics
    AVG(EngineTemp) AS AvgEngineTemp,
    MAX(EngineTemp) AS MaxEngineTemp,

    -- Distance Calculation (approximation)
    -- Distance = Speed × Time (assuming 2-second intervals between readings)
    SUM(Speed * (2.0 / 3600.0)) AS EstimatedDistanceKm,  -- Speed × (2 sec / 3600 sec/hour)

    -- Alert Counts
    SUM(CASE WHEN AlertType = 'speeding' THEN 1 ELSE 0 END) AS SpeedingAlerts,
    SUM(CASE WHEN AlertType = 'lowfuel' THEN 1 ELSE 0 END) AS LowFuelAlerts,
    SUM(CASE WHEN AlertType = 'overheating' THEN 1 ELSE 0 END) AS OverheatingAlerts,

    -- Status Distribution
    SUM(CASE WHEN Status = 'moving' THEN 1 ELSE 0 END) AS MovingEvents,
    SUM(CASE WHEN Status = 'idle' THEN 1 ELSE 0 END) AS IdleEvents,
    SUM(CASE WHEN Status = 'stopped' THEN 1 ELSE 0 END) AS StoppedEvents,

    -- Calculated Percentages
    CAST(SUM(CASE WHEN Status = 'moving' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS DECIMAL(5, 2)) AS MovingPercentage,
    CAST(SUM(CASE WHEN Status = 'idle' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS DECIMAL(5, 2)) AS IdlePercentage

FROM [dbo].[VehicleTelemetry]
WHERE RecordedTimestamp >= DATEADD(DAY, -30, GETDATE())  -- Last 30 days
GROUP BY CAST(RecordedTimestamp AS DATE), VehicleID
;
GO

PRINT '✓ Created view: vw_DailyStatistics';
PRINT '  - Use for: Daily fleet performance reports';
PRINT '';
GO

-- ============================================================================
-- VIEW 4: vw_AlertsSummary
-- Purpose: Summary of all alerts by vehicle and type
-- Use Case: Alert management dashboard
-- ============================================================================

PRINT '========================================';
PRINT 'Creating vw_AlertsSummary';
PRINT '========================================';

IF OBJECT_ID('[dbo].[vw_AlertsSummary]', 'V') IS NOT NULL
    DROP VIEW [dbo].[vw_AlertsSummary];
GO

CREATE VIEW [dbo].[vw_AlertsSummary]
AS
SELECT
    VehicleID,
    AlertType,
    COUNT(*) AS AlertCount,
    MIN(RecordedTimestamp) AS FirstAlertTime,
    MAX(RecordedTimestamp) AS LastAlertTime,
    DATEDIFF(HOUR, MIN(RecordedTimestamp), MAX(RecordedTimestamp)) AS AlertDurationHours,

    -- Alert Statistics by Type
    CASE AlertType
        WHEN 'speeding' THEN AVG(Speed)
        ELSE NULL
    END AS AvgSpeedDuringAlert,

    CASE AlertType
        WHEN 'lowfuel' THEN AVG(FuelLevel)
        ELSE NULL
    END AS AvgFuelLevelDuringAlert,

    CASE AlertType
        WHEN 'overheating' THEN AVG(EngineTemp)
        ELSE NULL
    END AS AvgEngineTempDuringAlert,

    -- Alert Frequency (alerts per day)
    CAST(COUNT(*) * 1.0 / NULLIF(DATEDIFF(DAY, MIN(RecordedTimestamp), MAX(RecordedTimestamp)), 0) AS DECIMAL(10, 2)) AS AlertsPerDay,

    -- Severity
    CASE
        WHEN COUNT(*) > 100 THEN 'Critical'
        WHEN COUNT(*) > 50 THEN 'High'
        WHEN COUNT(*) > 10 THEN 'Medium'
        ELSE 'Low'
    END AS Severity

FROM [dbo].[VehicleTelemetry]
WHERE AlertType IS NOT NULL
    AND RecordedTimestamp >= DATEADD(DAY, -30, GETDATE())  -- Last 30 days
GROUP BY VehicleID, AlertType
;
GO

PRINT '✓ Created view: vw_AlertsSummary';
PRINT '  - Use for: Alert management dashboard';
PRINT '';
GO

-- ============================================================================
-- VIEW 5: vw_VehiclePerformance
-- Purpose: Performance metrics over time with trends
-- Use Case: Vehicle health monitoring and predictive maintenance
-- ============================================================================

PRINT '========================================';
PRINT 'Creating vw_VehiclePerformance';
PRINT '========================================';

IF OBJECT_ID('[dbo].[vw_VehiclePerformance]', 'V') IS NOT NULL
    DROP VIEW [dbo].[vw_VehiclePerformance];
GO

CREATE VIEW [dbo].[vw_VehiclePerformance]
AS
WITH WeeklyMetrics AS (
    SELECT
        VehicleID,
        DATEPART(YEAR, RecordedTimestamp) AS Year,
        DATEPART(WEEK, RecordedTimestamp) AS WeekNumber,
        DATEADD(WEEK, DATEDIFF(WEEK, 0, RecordedTimestamp), 0) AS WeekStartDate,

        -- Performance Metrics
        AVG(Speed) AS AvgSpeed,
        AVG(FuelLevel) AS AvgFuelLevel,
        AVG(EngineTemp) AS AvgEngineTemp,
        COUNT(*) AS TotalEvents,
        SUM(CASE WHEN AlertType IS NOT NULL THEN 1 ELSE 0 END) AS AlertCount,

        -- Distance Calculation
        SUM(Speed * (2.0 / 3600.0)) AS EstimatedDistanceKm

    FROM [dbo].[VehicleTelemetry]
    WHERE RecordedTimestamp >= DATEADD(MONTH, -3, GETDATE())  -- Last 3 months
    GROUP BY
        VehicleID,
        DATEPART(YEAR, RecordedTimestamp),
        DATEPART(WEEK, RecordedTimestamp),
        DATEADD(WEEK, DATEDIFF(WEEK, 0, RecordedTimestamp), 0)
)
SELECT
    VehicleID,
    Year,
    WeekNumber,
    WeekStartDate,
    AvgSpeed,
    AvgFuelLevel,
    AvgEngineTemp,
    TotalEvents,
    AlertCount,
    EstimatedDistanceKm,

    -- Calculate week-over-week trends
    LAG(AvgSpeed, 1) OVER (PARTITION BY VehicleID ORDER BY WeekStartDate) AS PrevWeekAvgSpeed,
    LAG(AvgFuelLevel, 1) OVER (PARTITION BY VehicleID ORDER BY WeekStartDate) AS PrevWeekAvgFuelLevel,
    LAG(AvgEngineTemp, 1) OVER (PARTITION BY VehicleID ORDER BY WeekStartDate) AS PrevWeekAvgEngineTemp,

    -- Trend indicators
    CASE
        WHEN AvgSpeed > LAG(AvgSpeed, 1) OVER (PARTITION BY VehicleID ORDER BY WeekStartDate) THEN 'Increasing'
        WHEN AvgSpeed < LAG(AvgSpeed, 1) OVER (PARTITION BY VehicleID ORDER BY WeekStartDate) THEN 'Decreasing'
        ELSE 'Stable'
    END AS SpeedTrend,

    CASE
        WHEN AvgEngineTemp > LAG(AvgEngineTemp, 1) OVER (PARTITION BY VehicleID ORDER BY WeekStartDate) THEN 'Increasing'
        WHEN AvgEngineTemp < LAG(AvgEngineTemp, 1) OVER (PARTITION BY VehicleID ORDER BY WeekStartDate) THEN 'Decreasing'
        ELSE 'Stable'
    END AS EngineTempTrend,

    -- Performance Score (0-100)
    CAST(
        (
            -- Speed score (normalize 0-100 km/h to 0-30 points)
            (CASE WHEN AvgSpeed > 100 THEN 30 ELSE AvgSpeed * 0.3 END) +
            -- Fuel score (normalize 0-100% to 0-30 points)
            (AvgFuelLevel * 0.3) +
            -- Temperature score (inverse - lower is better, 0-100°C to 30-0 points)
            (CASE WHEN AvgEngineTemp > 100 THEN 0 ELSE (100 - AvgEngineTemp) * 0.3 END) +
            -- Alert penalty (each alert reduces score)
            (10 - CASE WHEN AlertCount > 10 THEN 10 ELSE AlertCount END)
        ) AS DECIMAL(5, 2)
    ) AS PerformanceScore

FROM WeeklyMetrics
;
GO

PRINT '✓ Created view: vw_VehiclePerformance';
PRINT '  - Use for: Performance trending and predictive maintenance';
PRINT '';
GO

-- ============================================================================
-- VIEW 6: vw_FleetSummary
-- Purpose: High-level fleet summary for executive dashboard
-- Use Case: Executive dashboard showing overall fleet health
-- ============================================================================

PRINT '========================================';
PRINT 'Creating vw_FleetSummary';
PRINT '========================================';

IF OBJECT_ID('[dbo].[vw_FleetSummary]', 'V') IS NOT NULL
    DROP VIEW [dbo].[vw_FleetSummary];
GO

CREATE VIEW [dbo].[vw_FleetSummary]
AS
WITH LatestData AS (
    SELECT
        VehicleID,
        MAX(RecordedTimestamp) AS LatestTimestamp
    FROM [dbo].[VehicleTelemetry]
    GROUP BY VehicleID
)
SELECT
    -- Fleet Size
    COUNT(DISTINCT t.VehicleID) AS TotalVehicles,

    -- Current Status Distribution
    SUM(CASE WHEN t.Status = 'moving' THEN 1 ELSE 0 END) AS VehiclesMoving,
    SUM(CASE WHEN t.Status = 'idle' THEN 1 ELSE 0 END) AS VehiclesIdle,
    SUM(CASE WHEN t.Status = 'stopped' THEN 1 ELSE 0 END) AS VehiclesStopped,
    SUM(CASE WHEN DATEDIFF(MINUTE, t.RecordedTimestamp, GETDATE()) > 30 THEN 1 ELSE 0 END) AS VehiclesOffline,

    -- Alert Counts (Today)
    (SELECT COUNT(*) FROM [dbo].[VehicleTelemetry]
     WHERE AlertType = 'speeding' AND CAST(RecordedTimestamp AS DATE) = CAST(GETDATE() AS DATE)) AS TodaySpeedingAlerts,

    (SELECT COUNT(*) FROM [dbo].[VehicleTelemetry]
     WHERE AlertType = 'lowfuel' AND CAST(RecordedTimestamp AS DATE) = CAST(GETDATE() AS DATE)) AS TodayLowFuelAlerts,

    (SELECT COUNT(*) FROM [dbo].[VehicleTelemetry]
     WHERE AlertType = 'overheating' AND CAST(RecordedTimestamp AS DATE) = CAST(GETDATE() AS DATE)) AS TodayOverheatingAlerts,

    -- Average Metrics
    AVG(t.Speed) AS FleetAvgSpeed,
    AVG(t.FuelLevel) AS FleetAvgFuelLevel,
    AVG(t.EngineTemp) AS FleetAvgEngineTemp,

    -- Distance (Today)
    (SELECT SUM(Speed * (2.0 / 3600.0))
     FROM [dbo].[VehicleTelemetry]
     WHERE CAST(RecordedTimestamp AS DATE) = CAST(GETDATE() AS DATE)) AS TodayTotalDistanceKm,

    -- Utilization Rate
    CAST(
        SUM(CASE WHEN t.Status = 'moving' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(DISTINCT t.VehicleID), 0)
        AS DECIMAL(5, 2)
    ) AS UtilizationRate,

    -- Last Update
    MAX(t.RecordedTimestamp) AS LastDataUpdate

FROM [dbo].[VehicleTelemetry] t
INNER JOIN LatestData ld ON t.VehicleID = ld.VehicleID AND t.RecordedTimestamp = ld.LatestTimestamp
;
GO

PRINT '✓ Created view: vw_FleetSummary';
PRINT '  - Use for: Executive dashboard';
PRINT '';
GO

-- ============================================================================
-- VERIFY VIEW CREATION
-- ============================================================================

PRINT '========================================';
PRINT 'Views Summary';
PRINT '========================================';

SELECT
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS ViewName,
    create_date AS CreatedDate,
    modify_date AS ModifiedDate
FROM sys.views
WHERE name LIKE 'vw_%'
ORDER BY name;
GO

PRINT '';
PRINT '========================================';
PRINT 'View creation completed successfully!';
PRINT 'All SQL scripts have been executed.';
PRINT '========================================';
PRINT '';
PRINT 'Next Steps:';
PRINT '1. Test views by querying them';
PRINT '2. Connect Power BI to Synapse';
PRINT '3. Create dashboards using these views';
PRINT '4. Configure ADF pipelines to load data';
PRINT '';
GO

-- ============================================================================
-- USAGE EXAMPLES
-- ============================================================================

/*
-- Example 1: Check current status of all vehicles
SELECT * FROM [dbo].[vw_VehicleCurrentStatus]
ORDER BY VehicleID;

-- Example 2: Find vehicles with critical idle time
SELECT * FROM [dbo].[vw_IdleVehicles]
WHERE IdleSeverity = 'Critical'
ORDER BY IdleDurationHours DESC;

-- Example 3: Get daily statistics for a specific vehicle
SELECT * FROM [dbo].[vw_DailyStatistics]
WHERE VehicleID = 'VEHICLE001'
ORDER BY ReportDate DESC;

-- Example 4: View alert summary
SELECT
    VehicleID,
    AlertType,
    AlertCount,
    Severity,
    AlertsPerDay
FROM [dbo].[vw_AlertsSummary]
WHERE Severity IN ('Critical', 'High')
ORDER BY AlertCount DESC;

-- Example 5: Analyze performance trends
SELECT
    VehicleID,
    WeekStartDate,
    PerformanceScore,
    SpeedTrend,
    EngineTempTrend
FROM [dbo].[vw_VehiclePerformance]
WHERE VehicleID = 'VEHICLE001'
ORDER BY WeekStartDate DESC;

-- Example 6: Fleet-wide summary
SELECT * FROM [dbo].[vw_FleetSummary];

-- Example 7: Vehicles needing attention
SELECT
    VehicleID,
    VehicleState,
    HealthStatus,
    CurrentSpeed,
    CurrentFuelLevel,
    CurrentEngineTemp,
    MinutesSinceLastReport
FROM [dbo].[vw_VehicleCurrentStatus]
WHERE HealthStatus != 'Normal'
    OR VehicleState = 'Offline'
ORDER BY
    CASE HealthStatus
        WHEN 'Alert' THEN 1
        WHEN 'Low Fuel Warning' THEN 2
        WHEN 'High Temperature Warning' THEN 3
        ELSE 4
    END;
*/
