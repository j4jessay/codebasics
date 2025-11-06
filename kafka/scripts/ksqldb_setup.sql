-- ============================================================================
-- Vehicle IoT Real-Time Streaming Analytics - ksqlDB Setup
-- ============================================================================
-- This script sets up streams and tables for processing vehicle telemetry data
-- Run these commands in the ksqlDB CLI
-- ============================================================================

-- Set auto offset reset to earliest to process all messages
SET 'auto.offset.reset' = 'earliest';

-- ============================================================================
-- STEP 1: Create Base Vehicle Stream
-- ============================================================================
-- This stream reads from the Kafka topic and defines the data structure

CREATE STREAM vehicle_stream (
  vehicle_id VARCHAR,
  timestamp_utc VARCHAR,
  location STRUCT<lat DOUBLE, lon DOUBLE>,
  speed_kmph DOUBLE,
  fuel_percent DOUBLE,
  engine_temp_c DOUBLE,
  status VARCHAR
) WITH (
  KAFKA_TOPIC='vehicle.telemetry',
  VALUE_FORMAT='JSON',
  PARTITIONS=1
);

-- Verify the stream is created
DESCRIBE vehicle_stream;

-- ============================================================================
-- STEP 2: Create Speeding Detection Stream
-- ============================================================================
-- Filters vehicles exceeding 80 km/h speed limit

CREATE STREAM speeding_stream
WITH (
  KAFKA_TOPIC='vehicle.speeding',
  VALUE_FORMAT='JSON',
  PARTITIONS=1
) AS
SELECT
  vehicle_id,
  speed_kmph,
  timestamp_utc,
  location,
  'SPEEDING_ALERT' AS alert_type
FROM vehicle_stream
WHERE speed_kmph > 80
EMIT CHANGES;

-- ============================================================================
-- STEP 3: Create Low Fuel Alert Stream
-- ============================================================================
-- Filters vehicles with fuel level below 15%

CREATE STREAM lowfuel_stream
WITH (
  KAFKA_TOPIC='vehicle.lowfuel',
  VALUE_FORMAT='JSON',
  PARTITIONS=1
) AS
SELECT
  vehicle_id,
  fuel_percent,
  timestamp_utc,
  location,
  'LOW_FUEL_ALERT' AS alert_type
FROM vehicle_stream
WHERE fuel_percent < 15
EMIT CHANGES;

-- ============================================================================
-- STEP 4: Create Engine Overheating Alert Stream
-- ============================================================================
-- Filters vehicles with engine temperature above 100°C

CREATE STREAM overheating_stream
WITH (
  KAFKA_TOPIC='vehicle.overheating',
  VALUE_FORMAT='JSON',
  PARTITIONS=1
) AS
SELECT
  vehicle_id,
  engine_temp_c,
  timestamp_utc,
  location,
  'OVERHEATING_ALERT' AS alert_type
FROM vehicle_stream
WHERE engine_temp_c > 100
EMIT CHANGES;

-- ============================================================================
-- STEP 5: Create Aggregated Vehicle Statistics Table
-- ============================================================================
-- Real-time aggregations per vehicle (windowed by 1 minute)

CREATE TABLE vehicle_stats_1min
WITH (
  KAFKA_TOPIC='vehicle.stats.1min',
  VALUE_FORMAT='JSON',
  PARTITIONS=1
) AS
SELECT
  vehicle_id,
  COUNT(*) AS event_count,
  AVG(speed_kmph) AS avg_speed,
  MAX(speed_kmph) AS max_speed,
  MIN(fuel_percent) AS min_fuel,
  AVG(engine_temp_c) AS avg_engine_temp,
  MAX(engine_temp_c) AS max_engine_temp
FROM vehicle_stream
WINDOW TUMBLING (SIZE 1 MINUTE)
GROUP BY vehicle_id
EMIT CHANGES;

-- ============================================================================
-- STEP 6: Create Combined Alerts Stream (Optional)
-- ============================================================================
-- Combines all alerts into a single stream for easier monitoring

CREATE STREAM all_alerts
WITH (
  KAFKA_TOPIC='vehicle.alerts.all',
  VALUE_FORMAT='JSON',
  PARTITIONS=1
) AS
SELECT
  vehicle_id,
  timestamp_utc,
  alert_type,
  CAST(NULL AS DOUBLE) AS speed_kmph,
  fuel_percent,
  CAST(NULL AS DOUBLE) AS engine_temp_c,
  location
FROM lowfuel_stream
EMIT CHANGES;

INSERT INTO all_alerts
SELECT
  vehicle_id,
  timestamp_utc,
  alert_type,
  speed_kmph,
  CAST(NULL AS DOUBLE) AS fuel_percent,
  CAST(NULL AS DOUBLE) AS engine_temp_c,
  location
FROM speeding_stream
EMIT CHANGES;

INSERT INTO all_alerts
SELECT
  vehicle_id,
  timestamp_utc,
  alert_type,
  CAST(NULL AS DOUBLE) AS speed_kmph,
  CAST(NULL AS DOUBLE) AS fuel_percent,
  engine_temp_c,
  location
FROM overheating_stream
EMIT CHANGES;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Use these queries to verify data is flowing correctly

-- List all streams and tables
SHOW STREAMS;
SHOW TABLES;

-- Query raw vehicle data (Ctrl+C to stop)
-- SELECT * FROM vehicle_stream EMIT CHANGES LIMIT 5;

-- Query speeding alerts (Ctrl+C to stop)
-- SELECT * FROM speeding_stream EMIT CHANGES LIMIT 5;

-- Query low fuel alerts (Ctrl+C to stop)
-- SELECT * FROM lowfuel_stream EMIT CHANGES LIMIT 5;

-- Query vehicle statistics (Ctrl+C to stop)
-- SELECT * FROM vehicle_stats_1min EMIT CHANGES LIMIT 5;

-- Query all alerts (Ctrl+C to stop)
-- SELECT * FROM all_alerts EMIT CHANGES LIMIT 5;

-- ============================================================================
-- CLEANUP (if needed to restart)
-- ============================================================================
-- Uncomment and run these if you need to drop and recreate streams

-- DROP STREAM IF EXISTS all_alerts DELETE TOPIC;
-- DROP STREAM IF EXISTS overheating_stream DELETE TOPIC;
-- DROP STREAM IF EXISTS lowfuel_stream DELETE TOPIC;
-- DROP STREAM IF EXISTS speeding_stream DELETE TOPIC;
-- DROP TABLE IF EXISTS vehicle_stats_1min DELETE TOPIC;
-- DROP STREAM IF EXISTS vehicle_stream DELETE TOPIC;

-- ============================================================================
-- END OF SETUP
-- ============================================================================
