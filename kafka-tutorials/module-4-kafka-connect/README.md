# Module 4: Kafka Connect & Data Integration

## ⏱️ Duration: 60 minutes
**Theory: 20 min | Hands-On: 40 min**

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

- ✅ Understand Kafka Connect architecture and benefits
- ✅ Explain the difference between source and sink connectors
- ✅ Configure Azure Blob Storage sink connector
- ✅ Deploy connectors using REST API
- ✅ Export streaming data to cloud storage
- ✅ Verify data in Azure with time-based partitioning

---

## 📚 Module Structure

### Part 1: Theory (20 minutes)

Read the following theory files in order:

1. **[What is Kafka Connect?](theory/01-what-is-kafka-connect.md)** (7 min)
   - Connect architecture
   - Why use connectors vs writing code
   - Connect cluster and workers

2. **[Source vs Sink Connectors](theory/02-source-vs-sink.md)** (7 min)
   - Source connectors (data import)
   - Sink connectors (data export)
   - Popular connectors

3. **[Connector Configuration](theory/03-connector-configuration.md)** (6 min)
   - Configuration parameters
   - REST API for deployment
   - Monitoring and troubleshooting

### Part 2: Hands-On Lab (40 minutes)

**[→ Go to Lab](lab/README.md)**

- Set up Azure Storage Account (10 min)
- Configure Azure Blob Storage connector (10 min)
- Deploy connector using REST API (10 min)
- Verify data in Azure Blob Storage (10 min)

---

## ✅ Prerequisites

Before starting this module:

- [ ] Completed Module 1, 2, and 3
- [ ] Have producer and ksqlDB streams running
- [ ] Azure account (free tier works)
- [ ] Understand JSON configuration files

---

## 🚀 What You'll Build

In this module, you'll export processed data to Azure:

```
┌────────────────────┐
│   ksqlDB Streams   │
│                    │
│ • vehicle.speeding │
│ • vehicle.lowfuel  │
│ • vehicle.stats    │
└─────────┬──────────┘
          │
          ▼
   ┌──────────────┐
   │ Kafka Connect│
   │              │
   │ Azure Blob   │
   │ Sink         │
   │ Connector    │
   └──────┬───────┘
          │
          ▼
┌─────────────────────┐
│ Azure Blob Storage  │
│                     │
│ year=2024/          │
│   month=11/         │
│     day=10/         │
│       hour=14/      │
│         *.json      │
└─────────────────────┘
```

---

## 🎓 Success Criteria

You've successfully completed this module when you can:

- [ ] Explain what Kafka Connect is and its benefits
- [ ] Differentiate between source and sink connectors
- [ ] Create an Azure Storage Account and container
- [ ] Configure the Azure Blob Storage sink connector
- [ ] Deploy connector using the REST API
- [ ] Verify JSON files in Azure Blob Storage
- [ ] Understand time-based partitioning

---

## ⏭️ Next Module

Once you've completed this module, proceed to:

**[Module 5: Monitoring & Operations →](../module-5-monitoring-operations/)**

---

## 🆘 Need Help?

- Check the **[Troubleshooting Guide](../reference/troubleshooting.md)**
- Review **[Quick Commands](../reference/quick-commands.md)**
- Check **[Kafka Connect Documentation](https://docs.confluent.io/platform/current/connect/)**

---

**Let's begin!** Start with the theory files, then move to the lab.
