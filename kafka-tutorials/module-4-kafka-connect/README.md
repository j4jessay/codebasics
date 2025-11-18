# Module 4: Kafka Connect & Azure Data Factory

## ⏱️ Duration: 90 minutes
**Theory: 40 min | Hands-On: 50 min**

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

### Part A: Kafka Connect (30 min)
- ✅ Understand Kafka Connect architecture and benefits
- ✅ Explain the difference between source and sink connectors
- ✅ Configure Azure Blob Storage sink connector
- ✅ Deploy connectors using REST API
- ✅ Export streaming data to cloud storage with Parquet format
- ✅ Verify data in Azure with time-based partitioning

### Part B: Azure Data Factory (60 min)
- ✅ Understand Azure Data Factory architecture and use cases
- ✅ Design ETL pipelines for data warehouse loading
- ✅ Configure ADF linked services and datasets
- ✅ Build copy pipelines to load data from Blob to Synapse
- ✅ Implement data validation and staging patterns
- ✅ Set up event-based and scheduled triggers
- ✅ Monitor pipeline execution and troubleshoot issues

---

## 📚 Module Structure

### Part A: Kafka Connect (30 minutes)

#### Theory (15 minutes)

Read the following theory files in order:

1. **[What is Kafka Connect?](theory/01-what-is-kafka-connect.md)** (5 min)
   - Connect architecture
   - Why use connectors vs writing code
   - Connect cluster and workers

2. **[Source vs Sink Connectors](theory/02-source-vs-sink.md)** (5 min)
   - Source connectors (data import)
   - Sink connectors (data export)
   - Popular connectors

3. **[Connector Configuration](theory/03-connector-configuration.md)** (5 min)
   - Configuration parameters
   - REST API for deployment
   - Monitoring and troubleshooting

#### Hands-On Lab (15 minutes)

**[→ Go to Kafka Connect Lab](lab/README.md#kafka-connect-exercises)**

- Set up Azure Storage Account (optional - can use ARM template)
- Configure Azure Blob Storage connector (10 min)
- Deploy connector and verify Parquet files (5 min)

---

### Part B: Azure Data Factory (60 minutes)

#### Theory (25 minutes)

4. **[Azure Data Factory Overview](theory/04-azure-data-factory.md)** (25 min)
   - ADF architecture and components
   - Linked services, datasets, pipelines, activities
   - Triggers (schedule, tumbling window, event-based)
   - Integration with Kafka pipeline
   - Data transformation options
   - Monitoring and debugging
   - Best practices and cost optimization

#### Hands-On Lab (35 minutes)

**[→ Go to ADF Lab](lab/adf-pipelines/README.md)**

1. **Deploy Azure Resources** (10 min)
   - Run ARM template deployment script
   - Create resource group with Storage, ADF, and Synapse

2. **Configure ADF** (10 min)
   - Create linked services (Blob + Synapse)
   - Create datasets (Parquet source + SQL sink)
   - Import pipeline templates

3. **Test Pipelines** (10 min)
   - Debug simple copy pipeline
   - Test staged load with validation
   - Monitor pipeline execution

4. **Configure Triggers** (5 min)
   - Set up event-based trigger for blob creation
   - Create scheduled trigger for daily batch loads

---

## ✅ Prerequisites

Before starting this module:

- [ ] Completed Module 1, 2, and 3
- [ ] Have producer and ksqlDB streams running from previous modules
- [ ] **Azure account** (free trial or subscription)
- [ ] **Azure CLI** installed ([Installation guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- [ ] Understand JSON configuration files
- [ ] Basic SQL knowledge (for Synapse in Module 6)
- [ ] Estimated Azure cost: **$45-100/month** (can pause resources to save costs)

---

## 🚀 What You'll Build

In this module, you'll build a complete ETL pipeline from Kafka to Azure Synapse Analytics:

```
┌──────────────────────────────────────────────────────────────────┐
│                    DATA PIPELINE ARCHITECTURE                    │
└──────────────────────────────────────────────────────────────────┘

Part A: Kafka Connect (Data Export)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
     │Kafka Connect │
     │              │
     │ Azure Blob   │
     │    Sink      │
     └──────┬───────┘
            │ Export Parquet (every 5 min)
            ▼
  ┌───────────────────────┐
  │ Azure Blob Storage    │
  │  (Bronze Layer)       │
  │                       │
  │ /vehicle-telemetry/   │
  │   2025/11/17/10/      │
  │     *.parquet         │
  └───────┬───────────────┘
          │
          │
Part B: Azure Data Factory (ETL Orchestration)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

          │ Trigger (event/schedule)
          ▼
  ┌────────────────────┐
  │ Azure Data Factory │
  │  ETL Pipeline      │
  │                    │
  │ • Copy Activity    │
  │ • Validation       │
  │ • Transform        │
  └────────┬───────────┘
           │ Load data
           ▼
  ┌────────────────────┐
  │ Azure Synapse      │
  │  Analytics         │
  │  (Gold Layer)      │
  │                    │
  │ Star Schema:       │
  │ • Fact tables      │
  │ • Dimensions       │
  └────────────────────┘
           │
           ▼
  ┌────────────────────┐
  │    Power BI        │
  │   Dashboards       │
  └────────────────────┘
```

**By the end, you'll have**:
- ✅ Automated data export from Kafka to Azure Blob (Parquet format)
- ✅ Scheduled ETL pipelines to load data into Synapse
- ✅ Event-triggered pipelines (run when new files arrive)
- ✅ Data validation and quality checks
- ✅ Foundation for analytics and reporting (Module 6)

---

## 🎓 Success Criteria

You've successfully completed this module when you can:

### Part A: Kafka Connect
- [ ] Explain what Kafka Connect is and its benefits
- [ ] Differentiate between source and sink connectors
- [ ] Configure the Azure Blob Storage sink connector
- [ ] Deploy connector using the REST API
- [ ] Verify Parquet files in Azure Blob Storage
- [ ] Understand time-based partitioning (year/month/day/hour)

### Part B: Azure Data Factory
- [ ] Explain ADF architecture (linked services, datasets, pipelines, activities)
- [ ] Deploy Azure resources using ARM templates
- [ ] Create linked services for Blob Storage and Synapse
- [ ] Import and configure ADF pipeline templates
- [ ] Run a successful debug execution of a copy pipeline
- [ ] Understand data validation patterns (staging tables)
- [ ] Configure event-based or scheduled triggers
- [ ] Monitor pipeline runs in ADF UI
- [ ] Troubleshoot common ADF errors (permissions, schema mismatches)

---

## ⏭️ Next Module

Once you've completed this module, proceed to:

**[Module 5: Monitoring & Operations →](../module-5-monitoring-operations/)**

(Or skip ahead to **[Module 6: Complete Pipeline with Synapse →](../module-6-complete-pipeline/)** to continue building the Azure data warehouse)

---

## 🆘 Need Help?

### Kafka Connect
- **[Kafka Connect Documentation](https://docs.confluent.io/platform/current/connect/)**
- **[Azure Blob Sink Connector](https://docs.confluent.io/kafka-connectors/azure-blob-storage-sink/current/overview.html)**

### Azure Data Factory
- **[ADF Documentation](https://learn.microsoft.com/en-us/azure/data-factory/)**
- **[ADF Pipeline Troubleshooting](lab/adf-pipelines/README.md#troubleshooting)**
- **[ARM Template Deployment Guide](lab/arm-templates/README.md)**

### Common Issues
- **Kafka Connect not starting**: Check Docker logs and REST API connectivity
- **ADF permission errors**: Verify managed identity RBAC roles
- **Synapse connection fails**: Check firewall rules and SQL admin password
- **High Azure costs**: Pause Synapse SQL pool when not in use

---

## 💡 Tips for Success

1. **Complete Part A first** - Get Kafka Connect working before tackling ADF
2. **Use ARM template** - Automated deployment saves time and reduces errors
3. **Pause resources** - Pause Synapse SQL pool between lab sessions to save ~$200/month
4. **Start small** - Begin with simple copy pipeline, then add validation
5. **Monitor costs** - Set up budget alerts in Azure Cost Management
6. **Keep notes** - Save resource names and connection strings in `deployment-config.txt`

---

**Let's begin!** Start with Part A theory files, then move to the labs.
