-- ============================================================================
-- STEP 1: Create Base Vehicle Stream
-- ============================================================================
-- This stream reads from the Kafka topic and defines the data structure

-- Set auto offset reset to earliest to process all messages
SET 'auto.offset.reset' = 'earliest';

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

-- View live data (press Ctrl+C to stop)
-- SELECT * FROM vehicle_stream EMIT CHANGES LIMIT 5;
