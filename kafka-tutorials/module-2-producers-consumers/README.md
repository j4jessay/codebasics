# Module 2: Producers & Consumers

## ⏱️ Duration: 75 minutes
**Theory: 25 min | Hands-On: 50 min**

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

- ✅ Understand producer architecture and message delivery guarantees
- ✅ Build a Kafka producer from scratch in Python
- ✅ Implement the vehicle IoT telemetry simulator
- ✅ Understand consumer groups and offset management
- ✅ Build consumers to process streaming data
- ✅ Handle serialization (JSON) properly

---

## 📚 Module Structure

### Part 1: Theory (25 minutes)

Read the following theory files in order:

1. **[Producer Architecture](theory/01-producer-architecture.md)** (8 min)
   - How producers work
   - Message delivery guarantees
   - Batching and compression

2. **[Consumer Groups](theory/02-consumer-groups.md)** (10 min)
   - How consumers work
   - Consumer groups and load balancing
   - Offset management and commit strategies

3. **[Serialization](theory/03-serialization.md)** (7 min)
   - JSON serialization
   - Best practices for data formats
   - Schema evolution

### Part 2: Hands-On Lab (50 minutes)

**[→ Go to Lab](lab/README.md)**

- Build a simple producer from scratch (15 min)
- Build the vehicle IoT simulator (15 min)
- Create a consumer to process messages (10 min)
- Work with consumer groups (10 min)

---

## ✅ Prerequisites

Before starting this module:

- [ ] Completed Module 1 (Kafka Fundamentals)
- [ ] Kafka cluster running from Module 1
- [ ] Python 3.8+ installed
- [ ] Basic Python knowledge (functions, loops, dictionaries)

---

## 🚀 What You'll Build

In this module, you'll build:

```
┌─────────────────────┐
│  Python Producer    │
│  (producer.py)      │
│                     │
│ • Simple producer   │
│ • Vehicle simulator │
│   (10 vehicles)     │
└──────────┬──────────┘
           │
           ▼
    ┌──────────────┐
    │    Kafka     │
    │ (vehicle.    │
    │  telemetry)  │
    └──────┬───────┘
           │
           ▼
┌──────────────────────┐
│  Python Consumer     │
│  (consumer.py)       │
│                      │
│ • Read messages      │
│ • Process telemetry  │
│ • Print alerts       │
└──────────────────────┘
```

---

## 🎓 Success Criteria

You've successfully completed this module when you can:

- [ ] Write a producer that sends JSON messages to Kafka
- [ ] Implement error handling and retries in producers
- [ ] Build the vehicle simulator that generates realistic data
- [ ] Create consumers that process messages
- [ ] Explain consumer groups and their benefits
- [ ] Manage consumer offsets properly

---

## ⏭️ Next Module

Once you've completed this module, proceed to:

**[Module 3: Stream Processing with ksqlDB →](../module-3-stream-processing/)**

---

## 🆘 Need Help?

- Check the **[Troubleshooting Guide](../reference/troubleshooting.md)**
- Review **[Quick Commands](../reference/quick-commands.md)**
- Ask your instructor (if in a class)

---

**Let's begin!** Start with the theory files, then move to the lab.
