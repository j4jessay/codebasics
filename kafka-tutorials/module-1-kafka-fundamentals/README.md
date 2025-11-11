# Module 1: Kafka Fundamentals

## ⏱️ Duration: 60 minutes
**Theory: 20 min | Hands-On: 40 min**

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

- ✅ Explain what event streaming is and why it matters
- ✅ Describe Kafka's architecture (brokers, topics, partitions)
- ✅ Understand the difference between Kafka and traditional databases
- ✅ Set up a basic Kafka cluster using Docker
- ✅ Create topics and send/receive messages using CLI tools

---

## 📚 Module Structure

### Part 1: Theory (20 minutes)

Read the following theory files in order:

1. **[What is Kafka?](theory/01-what-is-kafka.md)** (7 min)
   - Event streaming explained
   - Why not just use a database?
   - Real-world use cases

2. **[Architecture Overview](theory/02-architecture-overview.md)** (7 min)
   - Kafka components (brokers, Zookeeper, producers, consumers)
   - Message flow diagram
   - Key terminology

3. **[Topics, Partitions & Offsets](theory/03-topics-partitions-offsets.md)** (6 min)
   - What is a topic?
   - How partitions enable scalability
   - Understanding offsets

### Part 2: Hands-On Lab (40 minutes)

**[→ Go to Lab](lab/README.md)**

- Set up Kafka with Docker (10 min)
- Create topics using CLI (10 min)
- Send messages using console producer (10 min)
- Consume messages using console consumer (10 min)

---

## ✅ Prerequisites

Before starting this module:

- [ ] Docker Desktop installed and running
- [ ] Docker Compose available (version 2.0+)
- [ ] Terminal/command line access
- [ ] Text editor (VS Code recommended)

**Verify:**
```bash
docker --version
docker compose version
```

---

## 🚀 Getting Started

### Step 1: Read Theory
Start by reading the theory files to understand the concepts.

### Step 2: Do the Lab
Follow the hands-on lab to set up Kafka and practice.

### Step 3: Complete Exercises
Work through the exercises in the lab to reinforce learning.

---

## 📖 What You'll Build

In this module, you'll set up a minimal Kafka environment:

```
┌─────────────┐
│  Zookeeper  │ (Coordination service)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    Kafka    │ (Broker)
│   Broker    │
└─────────────┘
```

You'll interact with it using:
- **kafka-console-producer** (send messages)
- **kafka-console-consumer** (receive messages)

---

## 🎓 Success Criteria

You've successfully completed this module when you can:

- [ ] Explain what Kafka is in your own words
- [ ] Draw a simple Kafka architecture diagram
- [ ] Start Kafka using Docker Compose
- [ ] Create a topic with specific partition count
- [ ] Send messages to a topic
- [ ] Consume messages from a topic
- [ ] Understand what offsets represent

---

## ⏭️ Next Module

Once you've completed this module, proceed to:

**[Module 2: Producers & Consumers →](../module-2-producers-consumers/)**

---

## 🆘 Need Help?

- Check the **[Troubleshooting Guide](../reference/troubleshooting.md)**
- Review **[Quick Commands](../reference/quick-commands.md)**
- Ask your instructor (if in a class)

---

**Let's begin!** Start with the theory files, then move to the lab.
