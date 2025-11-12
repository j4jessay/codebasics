# Serialization & Data Formats

## 📖 Reading Time: 7 minutes

---

## Overview

**Serialization** is the process of converting data structures into bytes for transmission. **Deserialization** converts bytes back to data structures.

```
Python Dict → JSON → Bytes → Kafka → Bytes → JSON → Python Dict
(Producer)                                          (Consumer)
```

---

## Why Serialization Matters

Kafka only stores and transports **bytes**. You must convert your data to bytes.

**Bad:** Send raw Python objects (won't work!)
**Good:** Convert to JSON, then to bytes

---

## JSON Serialization

### Producer with JSON

```python
from kafka import KafkaProducer
import json

producer = KafkaProducer(
    bootstrap_servers='localhost:9092',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

# Send Python dictionary
message = {
    'vehicle_id': 'V001',
    'speed': 60,
    'timestamp': '2024-11-10T10:00:00Z'
}

producer.send('vehicle.telemetry', value=message)
```

**What happens:**
1. `message` (dict) → `json.dumps()` → JSON string
2. JSON string → `.encode('utf-8')` → bytes
3. Bytes sent to Kafka

### Consumer with JSON

```python
from kafka import KafkaConsumer
import json

consumer = KafkaConsumer(
    'vehicle.telemetry',
    bootstrap_servers='localhost:9092',
    value_deserializer=lambda m: json.loads(m.decode('utf-8'))
)

for message in consumer:
    # message.value is already a Python dictionary
    print(message.value['vehicle_id'])
    print(message.value['speed'])
```

**What happens:**
1. Bytes from Kafka → `.decode('utf-8')` → JSON string
2. JSON string → `json.loads()` → Python dict

---

## Data Format Best Practices

### 1. Include Timestamps

```python
import datetime

message = {
    'vehicle_id': 'V001',
    'speed': 60,
    'timestamp': datetime.datetime.utcnow().isoformat() + 'Z'
}
```

**Why:** Enables time-based analysis

### 2. Use Consistent Field Names

```python
# Good: Consistent naming
{'vehicle_id': 'V001', 'speed_kmph': 60}

# Bad: Inconsistent
{'vehicleId': 'V001', 'Speed': 60}  # Mixed conventions
```

### 3. Include Schema Version

```python
message = {
    'schema_version': 'v1',
    'vehicle_id': 'V001',
    'speed': 60
}
```

**Why:** Enables schema evolution

---

## Schema Evolution

### The Problem

What happens when you need to add new fields?

**Old producer:**
```json
{"vehicle_id": "V001", "speed": 60}
```

**New producer (added fuel field):**
```json
{"vehicle_id": "V001", "speed": 60, "fuel": 75}
```

**Question:** Will old consumers break?

### Solution: Backward Compatibility

```python
# Consumer handles missing fields
for message in consumer:
    vehicle_id = message.value['vehicle_id']
    speed = message.value['speed']
    fuel = message.value.get('fuel', 100)  # Default if missing
```

### Rules for Compatibility

1. **Add new fields** ✅ (old consumers ignore them)
2. **Provide defaults** for new fields
3. **Don't remove required fields** ❌ (breaks old consumers)
4. **Don't change field types** ❌ (breaks parsing)

---

## Error Handling

### Handle Serialization Errors

```python
def safe_serialize(data):
    try:
        return json.dumps(data).encode('utf-8')
    except TypeError as e:
        print(f'Serialization error: {e}')
        # Log error, return None, or handle appropriately
        return None

producer = KafkaProducer(
    value_serializer=safe_serialize
)
```

### Handle Deserialization Errors

```python
def safe_deserialize(data):
    try:
        return json.loads(data.decode('utf-8'))
    except json.JSONDecodeError as e:
        print(f'Deserialization error: {e}')
        return None

consumer = KafkaConsumer(
    value_deserializer=safe_deserialize
)

for message in consumer:
    if message.value is None:
        continue  # Skip bad messages
    process(message.value)
```

---

## Beyond JSON

### Other Serialization Formats

| Format | Pros | Cons | Use Case |
|--------|------|------|----------|
| **JSON** | Human-readable, simple | Large size, no schema | General purpose |
| **Avro** | Compact, schema evolution | Complex setup | Production systems |
| **Protobuf** | Compact, fast | Requires .proto files | High-performance |
| **String** | Simple | Limited to text | Logs, simple messages |

### Avro Example (Advanced)

```python
from kafka import KafkaProducer
from io import BytesIO
import avro.io
import avro.schema

# Define schema
schema = avro.schema.parse('''
{
    "type": "record",
    "name": "VehicleTelemetry",
    "fields": [
        {"name": "vehicle_id", "type": "string"},
        {"name": "speed", "type": "int"}
    ]
}
''')

def avro_serializer(data):
    writer = avro.io.DatumWriter(schema)
    bytes_writer = BytesIO()
    encoder = avro.io.BinaryEncoder(bytes_writer)
    writer.write(data, encoder)
    return bytes_writer.getvalue()

producer = KafkaProducer(value_serializer=avro_serializer)
```

**Note:** Avro is more complex but better for production. We'll stick with JSON for this tutorial.

---

## Message Structure Example

### Good Message Structure

```json
{
  "schema_version": "v1",
  "event_type": "telemetry",
  "timestamp": "2024-11-10T10:30:00.123Z",
  "source": {
    "vehicle_id": "V001",
    "device_type": "IoT-Sensor-v2"
  },
  "data": {
    "location": {
      "lat": 28.6139,
      "lon": 77.2090
    },
    "speed_kmph": 65.5,
    "fuel_percent": 75.2,
    "engine_temp_c": 92.3
  },
  "metadata": {
    "firmware_version": "2.1.0"
  }
}
```

**Benefits:**
- Clear structure
- Versioned schema
- Separated concerns (source, data, metadata)
- Includes timestamp

---

## Key Takeaways

1. **Kafka stores bytes** - you must serialize/deserialize

2. **JSON is simplest** for getting started

3. **Schema evolution** requires planning

4. **Include timestamps** in all messages

5. **Handle errors** in serialization/deserialization

6. **Avro/Protobuf** for production (better performance, schema management)

---

## Ready for Hands-On!

You've completed the theory. Now let's build producers and consumers!

**→ Next: [Go to Lab](../lab/README.md)**

---

## 🤔 Self-Check Questions

1. Why does Kafka need serialization?
2. What's the benefit of including a schema version?
3. How do you handle missing fields in messages?
4. When would you use Avro instead of JSON?

---
