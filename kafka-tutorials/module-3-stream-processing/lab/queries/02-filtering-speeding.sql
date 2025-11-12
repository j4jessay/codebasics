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

-- View speeding alerts (press Ctrl+C to stop)
-- SELECT * FROM speeding_stream EMIT CHANGES LIMIT 5;
