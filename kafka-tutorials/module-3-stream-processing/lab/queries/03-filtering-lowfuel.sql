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

-- View low fuel alerts (press Ctrl+C to stop)
-- SELECT * FROM lowfuel_stream EMIT CHANGES LIMIT 5;
