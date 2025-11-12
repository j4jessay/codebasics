-- ============================================================================
-- STEP 4: Create Aggregated Vehicle Statistics Table
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

-- View statistics (press Ctrl+C to stop)
-- SELECT * FROM vehicle_stats_1min EMIT CHANGES LIMIT 5;
