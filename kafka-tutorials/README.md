# Apache Kafka Tutorial - 6-Hour Hands-On Curriculum

## 🎯 Course Overview

This comprehensive 6-hour curriculum teaches Apache Kafka and stream processing through hands-on exercises. You'll build a **real-time IoT vehicle monitoring pipeline** from scratch, learning each component step-by-step.

### What You'll Build

A complete **Real-Time Vehicle Fleet Monitoring System** that:

- 🚗 Streams telemetry from 10 vehicles (GPS, speed, fuel, temperature)
- ⚡ Processes data in real-time to detect alerts (speeding, low fuel, overheating)
- ☁️ Exports data to Azure Blob Storage for analytics
- 📊 Monitors the entire pipeline using Confluent Control Center

### Learning Approach

**70% Hands-On + 30% Theory**

- Build components yourself (not just copy-paste)
- Understand the "why" behind each decision
- Troubleshoot real issues
- Adapt the pipeline for your own use cases

---

## 📚 Course Modules

### Module 1: Kafka Fundamentals (60 minutes)
**Theory: 20 min | Hands-On: 40 min**

Learn the core concepts of Apache Kafka and event streaming.

**What You'll Learn:**
- What is event streaming and why it matters
- Kafka architecture (brokers, topics, partitions, offsets)
- Difference between Kafka and traditional databases

**What You'll Build:**
- Set up Kafka with Docker
- Create topics manually
- Send and receive messages using console tools

**[→ Start Module 1](module-1-kafka-fundamentals/)**

---

### Module 2: Producers & Consumers (75 minutes)
**Theory: 25 min | Hands-On: 50 min**

Build applications that write to and read from Kafka.

**What You'll Learn:**
- Producer architecture and message delivery guarantees
- Consumer groups and offset management
- Serialization (JSON, Avro)

**What You'll Build:**
- Simple producer from scratch
- Full vehicle telemetry simulator
- Consumer to read and process messages

**[→ Start Module 2](module-2-producers-consumers/)**

---

### Module 3: Stream Processing with ksqlDB (90 minutes)
**Theory: 30 min | Hands-On: 60 min**

Process streaming data in real-time using SQL.

**What You'll Learn:**
- Why stream processing (vs batch processing)
- ksqlDB fundamentals (streams vs tables)
- Filtering, transformations, and aggregations

**What You'll Build:**
- Speeding alert detection (speed > 80 km/h)
- Low fuel warnings (fuel < 15%)
- 1-minute aggregated statistics

**[→ Start Module 3](module-3-stream-processing/)**

---

### Module 4: Kafka Connect & Azure Data Factory (90 minutes)
**Theory: 40 min | Hands-On: 50 min**

Export Kafka data to Azure cloud and build ETL pipelines to load data into a data warehouse.

**What You'll Learn:**
- Kafka Connect architecture (source vs sink connectors)
- Azure Data Factory for ETL orchestration
- ARM templates for automated Azure resource deployment
- Data warehouse loading patterns (staging, validation, merge)

**What You'll Build:**
- Azure Blob Storage sink connector with Parquet export
- Azure Data Factory pipelines for Synapse Analytics
- Complete ETL workflow (Kafka → Blob → ADF → Synapse)

**[→ Start Module 4](module-4-kafka-connect/)**

---

### Module 5: Monitoring & Operations (45 minutes)
**Theory: 15 min | Hands-On: 30 min**

Monitor, troubleshoot, and operate Kafka in production.

**What You'll Learn:**
- Key metrics to monitor
- Common failure scenarios
- Debugging techniques

**What You'll Do:**
- Navigate Confluent Control Center
- Diagnose producer/consumer issues
- Fix connector failures
- Intentionally break and repair the pipeline

**[→ Start Module 5](module-5-monitoring-operations/)**

---

### Module 6: Complete Pipeline with Azure Synapse (85 minutes)
**Theory: 40 min | Hands-On: 45 min**

Deploy the complete Kafka-to-Azure data warehouse pipeline and understand production considerations.

**What You'll Learn:**
- Azure Synapse Analytics and cloud data warehousing
- MPP architecture and distribution strategies
- Scaling Kafka (partitions, replication, brokers)
- Production best practices and cost optimization
- Real-world use cases and industry applications

**What You'll Build:**
- Full 7-service Kafka stack
- Azure Synapse data warehouse with star schema
- Complete end-to-end pipeline (Kafka → Blob → ADF → Synapse)
- Analytical views for BI consumption
- Custom capstone project

**[→ Start Module 6](module-6-complete-pipeline/)**

---

## 🛠️ Prerequisites

### Required Knowledge
✅ Python basics (variables, functions, loops)
✅ Command line familiarity (cd, ls, running commands)
✅ Basic understanding of APIs and JSON

### Not Required (We'll Teach You)
❌ Kafka experience
❌ Docker expertise (basic usage covered)
❌ Stream processing knowledge

### Software Requirements
- **Docker Desktop** (version 20.10+)
- **Docker Compose** (version 2.0+)
- **Python 3.8+** (for producer code)
- **Text editor** (VS Code recommended)
- **8GB RAM minimum** (16GB recommended)
- **Azure account** (free tier works - needed for Module 4+)

### System Check
```bash
# Verify installations
docker --version          # Should be 20.10+
docker compose version    # Should be 2.0+
python3 --version         # Should be 3.8+
```

---

## 🏗️ Project Architecture

### Complete Pipeline

```
┌─────────────────┐
│ Python Producer │ (10 vehicles, 20 messages/sec)
│  (Module 2)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Apache Kafka   │ (vehicle.telemetry topic)
│  (Module 1)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│     ksqlDB      │ (filter speeding, low fuel, etc.)
│  (Module 3)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Kafka Connect   │ (Azure Blob Storage Sink)
│  (Module 4)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Azure Blob      │ (time-partitioned JSON files)
│ Storage         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Power BI      │ (analytics dashboard)
│  (Visualization)│
└─────────────────┘

┌─────────────────┐
│ Control Center  │ (monitoring all components)
│  (Module 5)     │
└─────────────────┘
```

### Progressive Build Approach

Each module adds components incrementally:

| Module | Components Added | What's Running |
|--------|------------------|----------------|
| 1 | Zookeeper, Kafka | Basic Kafka cluster |
| 2 | Python Producer | Data generation |
| 3 | ksqlDB Server, ksqlDB CLI | Stream processing |
| 4 | Kafka Connect, Schema Registry | Data export |
| 5 | Control Center | Monitoring UI |
| 6 | All components | Production-ready stack |

---

## 📖 How to Use This Course

### For Instructor-Led Training

**Before Class:** Students set up Docker and clone repository

**During Class:**
- Instructor explains theory (slides/whiteboard)
- Students follow lab README step-by-step
- Pause for exercises and Q&A

**After Class:** Students complete additional exercises

### For Self-Paced Learning

1. Read theory files in each module's `theory/` folder
2. Follow lab instructions in each module's `lab/README.md`
3. Complete exercises to reinforce learning
4. Check solutions if stuck (provided inline)

### For Video Course Creation

Each module includes:
- Theory scripts (markdown files with talking points)
- Lab demonstrations (step-by-step commands)
- Screen recordings suggestions (what to show)
- Exercise walkthroughs (solution explanations)

---

## 📋 Learning Path Options

### Fast Track (3 hours)
For experienced developers who want the essentials:

1. **Module 1:** Skip theory, just run lab (15 min)
2. **Module 2:** Skim theory, focus on producer code (30 min)
3. **Module 3:** Focus on ksqlDB queries (45 min)
4. **Module 4:** Configure connector (30 min)
5. **Module 5:** Skip (use Module 6 troubleshooting)
6. **Module 6:** Full end-to-end deployment (60 min)

### Deep Dive (8+ hours)
For beginners or comprehensive training:

- All modules with full theory
- Complete all exercises
- Additional reading from reference materials
- Capstone project customization

### Workshop (1 day)
For in-person training:

- **Morning:** Modules 1-3 (fundamentals + streaming)
- **Afternoon:** Modules 4-6 (integration + production)
- Breaks and Q&A throughout
- Group capstone project

---

## 🎓 Learning Objectives

By the end of this course, you will be able to:

### Knowledge (Understand)
✅ Explain Kafka architecture and core concepts
✅ Describe use cases for event streaming
✅ Understand stream processing vs batch processing
✅ Compare Kafka to message queues and databases

### Skills (Apply)
✅ Build producers and consumers in Python
✅ Write ksqlDB queries for filtering and aggregation
✅ Configure and deploy Kafka Connect connectors
✅ Monitor Kafka using Control Center
✅ Troubleshoot common Kafka issues

### Practice (Create)
✅ Design event-driven architectures
✅ Adapt the vehicle pipeline for other IoT use cases
✅ Build end-to-end streaming data pipelines
✅ Make production readiness decisions

---

## 📊 Real-World Context

### Industry Use Cases

This architecture is used by:

**Ride-Sharing (Uber, Lyft)**
- Real-time driver location tracking
- Surge pricing calculations
- Trip matching

**E-Commerce (Amazon, Shopify)**
- Inventory updates
- Order processing
- Fraud detection

**Financial Services (PayPal, Stripe)**
- Transaction monitoring
- Fraud alerts
- Real-time analytics

**IoT (Tesla, Smart Cities)**
- Vehicle telemetry (exactly what you'll build!)
- Sensor data aggregation
- Predictive maintenance

### Skills and Career Paths

**Job Roles Using Kafka:**
- Data Engineer
- Platform Engineer
- Streaming Data Engineer
- Backend Engineer
- DevOps Engineer

**Average Salaries (US, 2025):**
- Entry-level Data Engineer: $90K-$120K
- Mid-level Streaming Engineer: $120K-$160K
- Senior Platform Engineer: $160K-$220K

**Certifications:**
- Confluent Certified Developer for Apache Kafka
- Confluent Certified Administrator for Apache Kafka

---

## 🚀 Getting Started

### Quick Start (5 minutes)

```bash
# 1. Clone the repository (if not already done)
cd /path/to/kafka-tutorials

# 2. Start with Module 1
cd module-1-kafka-fundamentals

# 3. Read the theory
cat theory/01-what-is-kafka.md

# 4. Start the lab
cd lab
cat README.md
```

### Recommended Schedule

**Option 1: Full Day Workshop (6 hours)**

- 9:00 AM - 10:00 AM: Module 1
- 10:00 AM - 11:15 AM: Module 2
- 11:15 AM - 12:45 PM: Module 3
- 12:45 PM - 1:00 PM: Break
- 1:00 PM - 2:00 PM: Module 4
- 2:00 PM - 2:45 PM: Module 5
- 2:45 PM - 3:45 PM: Module 6

**Option 2: Two Half-Days (3 hours each)**

- Day 1: Modules 1-3 (Fundamentals + Streaming)
- Day 2: Modules 4-6 (Integration + Production)

**Option 3: Six 1-Hour Sessions**

- One module per session over 6 days

---

## 🔧 Troubleshooting

### Common Setup Issues

**Docker not starting?**
```bash
# Check if Docker daemon is running
docker ps

# Restart Docker Desktop (use GUI or system commands)
```

**Port conflicts (9092, 2181, etc.)?**
```bash
# Check what's using ports
lsof -i :9092
lsof -i :2181

# Kill conflicting processes or change ports in docker-compose.yml
```

**Out of memory?**
```
Docker Desktop: Increase memory allocation to 8GB+
Settings → Resources → Memory
```

**Azure connector fails?**
- Check if running on ARM64 (Mac M1/M2/M3)
- Use GitHub Codespaces (see Module 4 notes)

### Getting Help

- **During course:** Ask your instructor
- **Self-paced:** Check `reference/troubleshooting.md`
- **Community:** Confluent Community Slack
- **Issues:** Apache Kafka Users Mailing List

---

## 📚 Additional Resources

### Official Documentation
- [Apache Kafka Docs](https://kafka.apache.org/documentation/)
- [Confluent Platform Docs](https://docs.confluent.io/)
- [ksqlDB Documentation](https://docs.ksqldb.io/)

### Books
- "Kafka: The Definitive Guide" by Neha Narkhede
- "Streaming Systems" by Tyler Akidau
- "Designing Event-Driven Systems" by Ben Stopford

### Online Courses
- Confluent Developer Courses (free)
- Udemy Kafka courses
- LinkedIn Learning: Apache Kafka Essential Training

### Practice Environments
- Confluent Cloud (free trial)
- AWS MSK (Managed Kafka)
- Azure Event Hubs (Kafka-compatible)

---

## 📁 Repository Structure

```
kafka-tutorials/
├── README.md (this file)
│
├── module-1-kafka-fundamentals/
│   ├── theory/                  # Conceptual explanations
│   └── lab/                     # Hands-on exercises
│
├── module-2-producers-consumers/
│   ├── theory/
│   └── lab/
│
├── module-3-stream-processing/
│   ├── theory/
│   └── lab/
│
├── module-4-kafka-connect/
│   ├── theory/
│   └── lab/
│
├── module-5-monitoring-operations/
│   ├── theory/
│   └── lab/
│
├── module-6-complete-pipeline/
│   ├── theory/
│   ├── lab/
│   └── capstone/
│
└── reference/
    ├── quick-commands.md        # Cheat sheet
    ├── troubleshooting.md       # Common issues
    ├── glossary.md              # Kafka terminology
    └── next-steps.md            # After the course
```

---

## 🎉 Ready to Begin?

Start your Kafka journey:

**👉 [Go to Module 1: Kafka Fundamentals →](module-1-kafka-fundamentals/)**

---

## 📝 Course Feedback

After completing the course, please share your feedback:

- What worked well?
- What was confusing?
- What should be added?
- How long did each module actually take?

This helps improve the curriculum for future students!

---

## ⚖️ License

This curriculum is based on the Apache Kafka project (Apache License 2.0) and uses Confluent Platform components.

Course materials: Free to use for educational purposes.

---

**Happy Streaming! 🚀**

Questions? Start with Module 1 and everything will become clear as you build!
