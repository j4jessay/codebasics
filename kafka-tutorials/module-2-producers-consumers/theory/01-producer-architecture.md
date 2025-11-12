# Producer Architecture

## 📖 Reading Time: 8 minutes

---

## Overview

A **Kafka producer** is an application that sends events (messages) to Kafka topics. In this section, you'll learn how producers work internally and how to write reliable producers.

---

## Producer Workflow

### High-Level Flow

```
Application Code
      ↓
Producer API (send message)
      ↓
Serializer (convert to bytes)
      ↓
Partitioner (choose partition)
      ↓
Buffer/Batch (group messages)
      ↓
Network Thread (send to broker)
      ↓
Kafka Broker (stores message)
      ↓
Acknowledgment (success/failure)
```

---

## Message Delivery Guarantees

Kafka offers three levels of delivery guarantees:

### 1. At-Most-Once (acks=0)

**Configuration:** `acks=0`

```python
producer = KafkaProducer(acks=0)
```

**Behavior:**
- Producer doesn't wait for acknowledgment
- Fire and forget
- Message might be lost if broker fails

**Use case:** Metrics, logs where occasional loss is acceptable

**Performance:** ⚡ Fastest

**Reliability:** ❌ Least reliable

---

### 2. At-Least-Once (acks=1)

**Configuration:** `acks=1` (default)

```python
producer = KafkaProducer(acks=1)
```

**Behavior:**
- Producer waits for leader broker to acknowledge
- Message won't be lost unless leader fails immediately
- Might result in duplicates if producer retries

**Use case:** Most common for general applications

**Performance:** ⚡⚡ Balanced

**Reliability:** ✅ Good

---

### 3. Exactly-Once (acks=all)

**Configuration:** `acks='all'` or `acks=-1`

```python
producer = KafkaProducer(
    acks='all',
    retries=3,
    max_in_flight_requests_per_connection=1
)
```

**Behavior:**
- Producer waits for all in-sync replicas to acknowledge
- Message won't be lost even if brokers fail
- Requires careful configuration to avoid duplicates

**Use case:** Financial transactions, critical data

**Performance:** ⚡ Slowest

**Reliability:** ✅✅✅ Most reliable

---

## Producer Configuration

### Essential Parameters

```python
from kafka import KafkaProducer

producer = KafkaProducer(
    # Connection
    bootstrap_servers='localhost:9092',
    
    # Serialization
    value_serializer=lambda v: json.dumps(v).encode('utf-8'),
    key_serializer=lambda k: k.encode('utf-8') if k else None,
    
    # Reliability
    acks='all',              # Wait for all replicas
    retries=3,               # Retry 3 times on failure
    max_in_flight_requests_per_connection=1,  # Maintain order
    
    # Performance
    batch_size=16384,        # Batch size in bytes
    linger_ms=10,            # Wait 10ms to batch messages
    compression_type='gzip'  # Compress data
)
```

### Key Parameters Explained

| Parameter | Purpose | Default | Recommendation |
|-----------|---------|---------|----------------|
| `bootstrap_servers` | Kafka broker addresses | - | Required |
| `acks` | Delivery guarantee | 1 | 'all' for critical data |
| `retries` | Retry attempts | 2147483647 | 3-10 |
| `batch_size` | Max batch size (bytes) | 16384 | 16384-32768 |
| `linger_ms` | Wait time to batch | 0 | 5-20 |
| `compression_type` | Compression algorithm | none | gzip, snappy |

---

## Sending Messages

### Basic Send

```python
from kafka import KafkaProducer
import json

producer = KafkaProducer(
    bootstrap_servers='localhost:9092',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

# Send message
producer.send(
    topic='vehicle.telemetry',
    value={'vehicle_id': 'V001', 'speed': 60}
)

# Flush (wait for all messages to be sent)
producer.flush()
```

### Send with Key

```python
# Key ensures all messages for same vehicle go to same partition
producer.send(
    topic='vehicle.telemetry',
    key='V001',  # Partition key
    value={'vehicle_id': 'V001', 'speed': 60}
)
```

### Asynchronous Send with Callback

```python
def on_send_success(record_metadata):
    print(f'✓ Sent to {record_metadata.topic}:{record_metadata.partition}')

def on_send_error(excp):
    print(f'✗ Error: {excp}')

future = producer.send('vehicle.telemetry', value={'speed': 60})
future.add_callback(on_send_success)
future.add_errback(on_send_error)
```

### Synchronous Send (Wait for Confirmation)

```python
try:
    # Wait for message to be sent (blocks)
    record_metadata = producer.send('vehicle.telemetry', value={'speed': 60}).get(timeout=10)
    print(f'✓ Sent to partition {record_metadata.partition} at offset {record_metadata.offset}')
except Exception as e:
    print(f'✗ Failed to send: {e}')
```

---

## Batching and Performance

### Why Batching?

Sending messages one-by-one is inefficient:

```
Message 1 → Network call → Broker
Message 2 → Network call → Broker  (slow!)
Message 3 → Network call → Broker
```

**With batching:**

```
Message 1 ]
Message 2 ] → Single network call → Broker  (fast!)
Message 3 ]
```

### Batching Configuration

```python
producer = KafkaProducer(
    batch_size=16384,   # Batch up to 16KB of messages
    linger_ms=10        # Wait 10ms to accumulate more messages
)
```

**How it works:**
1. Producer accumulates messages for up to 10ms
2. Or until batch reaches 16KB
3. Whichever comes first, send the batch

**Trade-off:**
- ⬆️ `linger_ms` = better throughput, higher latency
- ⬇️ `linger_ms` = lower latency, lower throughput

---

## Compression

### Why Compress?

Compression reduces:
- Network bandwidth usage
- Disk space on brokers
- Network transfer time

### Compression Types

```python
producer = KafkaProducer(compression_type='gzip')
```

| Algorithm | Compression Ratio | CPU Usage | Speed |
|-----------|-------------------|-----------|-------|
| `none` | 1x (no compression) | Low | Fastest |
| `gzip` | ~3x | Medium | Medium |
| `snappy` | ~2x | Low | Fast |
| `lz4` | ~2x | Low | Fast |
| `zstd` | ~3x | Medium | Medium |

**Recommendation:** Start with `gzip` or `snappy`

---

## Error Handling

### Common Errors

**1. Broker Not Available**
```
kafka.errors.NoBrokersAvailable: No brokers available
```
**Solution:** Check Kafka is running and `bootstrap_servers` is correct

**2. Timeout**
```
kafka.errors.KafkaTimeoutError: Failed to update metadata after 60.0 secs
```
**Solution:** Increase timeout or check network connectivity

**3. Message Too Large**
```
kafka.errors.MessageSizeTooLargeError
```
**Solution:** Reduce message size or increase `max.request.size`

### Retry Strategy

```python
from kafka.errors import KafkaError
import time

def send_with_retry(producer, topic, message, max_retries=3):
    for attempt in range(max_retries):
        try:
            future = producer.send(topic, value=message)
            record_metadata = future.get(timeout=10)
            print(f'✓ Sent successfully')
            return True
        except KafkaError as e:
            print(f'✗ Attempt {attempt + 1} failed: {e}')
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)  # Exponential backoff
            else:
                print(f'✗ Failed after {max_retries} attempts')
                return False
```

---

## Best Practices

### 1. Always Close Producers

```python
producer = KafkaProducer(...)
try:
    producer.send(...)
finally:
    producer.close()  # Ensure resources are released
```

### 2. Use Context Managers

```python
from contextlib import closing

with closing(KafkaProducer(...)) as producer:
    producer.send(...)
# Automatically closed
```

### 3. Handle Serialization Errors

```python
def safe_serializer(data):
    try:
        return json.dumps(data).encode('utf-8')
    except Exception as e:
        print(f'Serialization error: {e}')
        return None
```

### 4. Monitor Producer Metrics

```python
# Get producer metrics
metrics = producer.metrics()
for name, metric in metrics.items():
    print(f'{name}: {metric}')
```

---

## Real-World Example: Vehicle Telemetry Producer

```python
from kafka import KafkaProducer
import json
import time

class VehicleProducer:
    def __init__(self):
        self.producer = KafkaProducer(
            bootstrap_servers='localhost:9092',
            value_serializer=lambda v: json.dumps(v).encode('utf-8'),
            key_serializer=lambda k: k.encode('utf-8'),
            acks='all',
            retries=3,
            max_in_flight_requests_per_connection=1
        )
    
    def send_telemetry(self, vehicle_id, speed, fuel, location):
        message = {
            'vehicle_id': vehicle_id,
            'timestamp': time.time(),
            'speed_kmph': speed,
            'fuel_percent': fuel,
            'location': location
        }
        
        try:
            future = self.producer.send(
                topic='vehicle.telemetry',
                key=vehicle_id,
                value=message
            )
            # Wait for confirmation
            record_metadata = future.get(timeout=10)
            print(f'✓ Sent: {vehicle_id} at {speed} km/h')
            return True
        except Exception as e:
            print(f'✗ Error sending telemetry: {e}')
            return False
    
    def close(self):
        self.producer.close()
```

---

## Key Takeaways

1. **Producers send messages to Kafka** with configurable reliability

2. **Delivery guarantees:** at-most-once (fast), at-least-once (balanced), exactly-once (reliable)

3. **Batching improves throughput** by grouping messages

4. **Compression reduces bandwidth** and disk usage

5. **Error handling is critical** - always implement retries and error callbacks

6. **Use partition keys** to ensure ordering for related messages

---

## What's Next?

Now that you understand producers, let's learn about consumers!

**→ Next: [Consumer Groups](02-consumer-groups.md)**

---

## 🤔 Self-Check Questions

1. What's the difference between `acks=1` and `acks=all`?
2. Why is batching beneficial?
3. When should you use compression?
4. How do partition keys affect message routing?

---
