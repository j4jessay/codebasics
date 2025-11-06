"""
Vehicle IoT Telemetry Data Producer
Simulates real-time vehicle data streaming to Kafka
"""

import json
import random
import time
from datetime import datetime, timezone
from kafka import KafkaProducer
from kafka.errors import KafkaError
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class VehicleIoTSimulator:
    """Simulates IoT telemetry data from multiple vehicles"""

    def __init__(self, bootstrap_servers='localhost:9092', topic='vehicle.telemetry'):
        """
        Initialize the Kafka producer

        Args:
            bootstrap_servers: Kafka broker address
            topic: Kafka topic to publish messages
        """
        self.topic = topic
        self.producer = None
        self.bootstrap_servers = bootstrap_servers

        # Vehicle configuration
        self.vehicle_ids = [f"VEH-{str(i).zfill(4)}" for i in range(1, 11)]  # 10 vehicles

        # Initialize vehicle states
        self.vehicle_states = {
            vehicle_id: {
                'lat': random.uniform(28.4, 28.7),  # Delhi area coordinates
                'lon': random.uniform(77.0, 77.3),
                'speed_kmph': random.uniform(20, 60),
                'fuel_percent': random.uniform(30, 95),
                'engine_temp_c': random.uniform(70, 95),
                'status': 'active'
            }
            for vehicle_id in self.vehicle_ids
        }

        self._connect_producer()

    def _connect_producer(self):
        """Establish connection to Kafka broker"""
        try:
            self.producer = KafkaProducer(
                bootstrap_servers=self.bootstrap_servers,
                value_serializer=lambda v: json.dumps(v).encode('utf-8'),
                key_serializer=lambda k: k.encode('utf-8') if k else None,
                acks='all',
                retries=3,
                max_in_flight_requests_per_connection=1
            )
            logger.info(f"✓ Connected to Kafka broker at {self.bootstrap_servers}")
        except KafkaError as e:
            logger.error(f"✗ Failed to connect to Kafka: {e}")
            raise

    def _update_vehicle_state(self, vehicle_id):
        """
        Update vehicle state with realistic variations

        Args:
            vehicle_id: Vehicle identifier

        Returns:
            dict: Updated vehicle telemetry data
        """
        state = self.vehicle_states[vehicle_id]

        # Update location (simulate movement)
        state['lat'] += random.uniform(-0.001, 0.001)
        state['lon'] += random.uniform(-0.001, 0.001)

        # Update speed with realistic variations
        speed_change = random.uniform(-5, 5)
        state['speed_kmph'] = max(0, min(120, state['speed_kmph'] + speed_change))

        # Occasionally simulate speeding
        if random.random() < 0.15:  # 15% chance
            state['speed_kmph'] = random.uniform(85, 110)

        # Update fuel (decreases over time)
        state['fuel_percent'] = max(0, state['fuel_percent'] - random.uniform(0.1, 0.5))

        # Occasionally simulate low fuel
        if random.random() < 0.05:  # 5% chance
            state['fuel_percent'] = random.uniform(5, 14)

        # Update engine temperature
        temp_change = random.uniform(-2, 3)
        state['engine_temp_c'] = max(60, min(110, state['engine_temp_c'] + temp_change))

        # Update status based on conditions
        if state['fuel_percent'] < 10:
            state['status'] = 'low_fuel'
        elif state['speed_kmph'] > 80:
            state['status'] = 'speeding'
        elif state['engine_temp_c'] > 100:
            state['status'] = 'overheating'
        else:
            state['status'] = 'active'

        return {
            'vehicle_id': vehicle_id,
            'timestamp_utc': datetime.now(timezone.utc).isoformat(),
            'location': {
                'lat': round(state['lat'], 6),
                'lon': round(state['lon'], 6)
            },
            'speed_kmph': round(state['speed_kmph'], 2),
            'fuel_percent': round(state['fuel_percent'], 2),
            'engine_temp_c': round(state['engine_temp_c'], 2),
            'status': state['status']
        }

    def _delivery_report(self, err, msg):
        """
        Callback for message delivery confirmation

        Args:
            err: Error if delivery failed
            msg: Message metadata
        """
        if err:
            logger.error(f'✗ Message delivery failed: {err}')
        else:
            logger.debug(f'✓ Message delivered to {msg.topic()} [{msg.partition()}]')

    def produce_telemetry(self, duration_seconds=None, rate_per_second=2):
        """
        Start producing vehicle telemetry data

        Args:
            duration_seconds: How long to run (None = indefinite)
            rate_per_second: Messages per second per vehicle
        """
        logger.info(f"🚀 Starting vehicle IoT simulator...")
        logger.info(f"   Topic: {self.topic}")
        logger.info(f"   Vehicles: {len(self.vehicle_ids)}")
        logger.info(f"   Rate: {rate_per_second} msg/sec per vehicle")
        logger.info(f"   Duration: {'Indefinite' if duration_seconds is None else f'{duration_seconds}s'}")
        logger.info("=" * 70)

        start_time = time.time()
        message_count = 0

        try:
            while True:
                # Check duration
                if duration_seconds and (time.time() - start_time) >= duration_seconds:
                    logger.info(f"\n⏱️  Duration limit reached. Stopping...")
                    break

                # Produce messages for all vehicles
                for vehicle_id in self.vehicle_ids:
                    telemetry = self._update_vehicle_state(vehicle_id)

                    try:
                        # Send to Kafka
                        future = self.producer.send(
                            self.topic,
                            key=vehicle_id,
                            value=telemetry
                        )

                        # Optional: wait for confirmation (synchronous)
                        # future.get(timeout=10)

                        message_count += 1

                        # Log interesting events
                        if telemetry['status'] != 'active':
                            logger.warning(
                                f"⚠️  {vehicle_id}: {telemetry['status'].upper()} | "
                                f"Speed: {telemetry['speed_kmph']} km/h | "
                                f"Fuel: {telemetry['fuel_percent']}% | "
                                f"Temp: {telemetry['engine_temp_c']}°C"
                            )
                        else:
                            logger.info(
                                f"📡 {vehicle_id}: {telemetry['status']} | "
                                f"Speed: {telemetry['speed_kmph']} km/h | "
                                f"Fuel: {telemetry['fuel_percent']}%"
                            )

                    except KafkaError as e:
                        logger.error(f"✗ Failed to send message: {e}")

                # Wait before next batch
                time.sleep(1 / rate_per_second)

        except KeyboardInterrupt:
            logger.info(f"\n⏸️  Interrupted by user...")

        finally:
            self._shutdown(message_count, time.time() - start_time)

    def _shutdown(self, message_count, elapsed_time):
        """
        Clean shutdown of producer

        Args:
            message_count: Total messages sent
            elapsed_time: Total runtime
        """
        logger.info("=" * 70)
        logger.info("🛑 Shutting down producer...")

        if self.producer:
            self.producer.flush()
            self.producer.close()

        logger.info(f"📊 Statistics:")
        logger.info(f"   Total messages sent: {message_count}")
        logger.info(f"   Runtime: {elapsed_time:.2f} seconds")
        logger.info(f"   Average rate: {message_count/elapsed_time:.2f} msg/sec")
        logger.info("✓ Shutdown complete")


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(description='Vehicle IoT Telemetry Simulator')
    parser.add_argument(
        '--broker',
        default='localhost:9092',
        help='Kafka broker address (default: localhost:9092)'
    )
    parser.add_argument(
        '--topic',
        default='vehicle.telemetry',
        help='Kafka topic name (default: vehicle.telemetry)'
    )
    parser.add_argument(
        '--duration',
        type=int,
        default=None,
        help='Duration in seconds (default: run indefinitely)'
    )
    parser.add_argument(
        '--rate',
        type=float,
        default=2.0,
        help='Messages per second per vehicle (default: 2.0)'
    )

    args = parser.parse_args()

    try:
        simulator = VehicleIoTSimulator(
            bootstrap_servers=args.broker,
            topic=args.topic
        )
        simulator.produce_telemetry(
            duration_seconds=args.duration,
            rate_per_second=args.rate
        )
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        raise


if __name__ == '__main__':
    main()
