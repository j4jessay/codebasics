# ARM Templates - Azure Resource Deployment

This directory contains Azure Resource Manager (ARM) templates to deploy all required Azure resources for the Kafka-to-Azure ETL pipeline in one click.

---

## What Gets Deployed

### Resources Created
1. **Azure Blob Storage Account** - Raw data storage (Bronze layer)
   - Containers: `vehicle-telemetry`, `staging`, `archive`
   - Tier: Standard_LRS (locally-redundant storage)
   - Soft delete enabled (7 days retention)

2. **Azure Data Lake Storage Gen2** - Synapse primary storage
   - Hierarchical namespace enabled
   - Used by Synapse workspace

3. **Azure Data Factory** - ETL orchestration
   - System-assigned managed identity
   - Public network access (configurable)

4. **Azure Synapse Analytics Workspace**
   - Dedicated SQL pool for data warehousing
   - Default SKU: DW100c (configurable)
   - Managed virtual network

5. **RBAC Permissions** (configured post-deployment)
   - ADF → Storage Blob Data Contributor on Blob Storage
   - Synapse → Storage Blob Data Contributor on Data Lake
   - Current user → Synapse Administrator

---

## Prerequisites

### 1. Azure Subscription
- Active Azure subscription with Owner or Contributor role
- Sufficient quota for:
  - 2 Storage accounts
  - 1 Data Factory
  - 1 Synapse workspace with SQL pool

### 2. Azure CLI
Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

```bash
# Verify installation
az version

# Login
az login

# List subscriptions
az account list --output table

# Set active subscription
az account set --subscription "<subscription-id>"
```

### 3. Permissions Required
- **Subscription level**: Contributor or Owner
- **Resource Group**: Create new or use existing with write access

---

## Deployment Methods

### Method 1: Automated Script (Recommended)

**Linux/macOS/WSL**:
```bash
# Navigate to this directory
cd module-4-kafka-connect/lab/arm-templates

# Make script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

**Windows (PowerShell)**:
```powershell
# Use manual deployment method below
```

The script will:
1. Check Azure CLI installation and login status
2. Prompt for configuration (resource group, location, etc.)
3. Generate a secure SQL admin password prompt
4. Deploy all resources
5. Configure RBAC permissions
6. Optionally pause Synapse SQL pool to save costs
7. Save configuration to `deployment-config.txt`

---

### Method 2: Manual Deployment via Azure CLI

```bash
# Set variables
RESOURCE_GROUP="kafka-tutorials-rg"
LOCATION="eastus"
PROJECT_NAME="kafka-etl"
ENVIRONMENT="dev"
SQL_ADMIN="sqladmin"
SQL_PASSWORD="YourSecureP@ssw0rd123!"  # Min 12 chars, uppercase, lowercase, number, special char

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Deploy template
az deployment group create \
  --name kafka-etl-deployment \
  --resource-group $RESOURCE_GROUP \
  --template-file azuredeploy.json \
  --parameters \
    projectName=$PROJECT_NAME \
    environment=$ENVIRONMENT \
    synapseSqlAdminUsername=$SQL_ADMIN \
    synapseSqlAdminPassword=$SQL_PASSWORD \
    synapseSqlPoolSKU=DW100c \
    enablePublicNetworkAccess=true

# Get outputs
az deployment group show \
  --name kafka-etl-deployment \
  --resource-group $RESOURCE_GROUP \
  --query properties.outputs
```

---

### Method 3: Azure Portal (GUI)

1. **Login to Azure Portal**: https://portal.azure.com
2. Navigate to: **Create a resource** → **Template deployment (deploy using custom templates)**
3. Click **Build your own template in the editor**
4. Copy/paste contents of `azuredeploy.json`
5. Click **Save**
6. Fill in parameters:
   - **Resource Group**: Create new or select existing
   - **Project Name**: `kafka-etl` (max 11 chars)
   - **Environment**: `dev` / `test` / `prod`
   - **Synapse SQL Admin Username**: `sqladmin`
   - **Synapse SQL Admin Password**: (min 12 chars, complex)
   - **Synapse SQL Pool SKU**: `DW100c` (start small)
   - **Enable Public Network Access**: Yes (for learning)
7. Click **Review + create** → **Create**
8. Wait 5-10 minutes for deployment to complete

---

### Method 4: PowerShell

```powershell
# Login
Connect-AzAccount

# Set variables
$resourceGroupName = "kafka-tutorials-rg"
$location = "eastus"
$templateFile = "azuredeploy.json"
$parametersFile = "azuredeploy.parameters.json"

# Create resource group
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Deploy template
New-AzResourceGroupDeployment `
  -Name "kafka-etl-deployment" `
  -ResourceGroupName $resourceGroupName `
  -TemplateFile $templateFile `
  -TemplateParameterFile $parametersFile `
  -Verbose
```

---

## Configuration Parameters

### Required Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `projectName` | string | Resource name prefix (max 11 chars, lowercase alphanumeric) | `kafka-etl` |
| `synapseSqlAdminUsername` | string | SQL admin login for Synapse | `sqladmin` |
| `synapseSqlAdminPassword` | securestring | SQL admin password (min 12 chars, complex) | `P@ssw0rd123!` |

### Optional Parameters

| Parameter | Type | Default | Options | Description |
|-----------|------|---------|---------|-------------|
| `location` | string | Resource group location | Any Azure region | Deployment region |
| `environment` | string | `dev` | `dev`, `test`, `prod` | Environment tag |
| `synapseSqlPoolSKU` | string | `DW100c` | `DW100c` - `DW500c` | SQL pool compute size |
| `enablePublicNetworkAccess` | bool | `true` | `true`, `false` | Allow internet access |

---

## Post-Deployment Steps

### 1. Verify Deployment

```bash
# Check resource group
az resource list --resource-group kafka-tutorials-rg --output table

# Expected resources:
# - 2 Storage accounts (one for blob, one for data lake)
# - 1 Data Factory
# - 1 Synapse workspace
# - 1 Synapse SQL pool
```

### 2. Grant RBAC Permissions

**If using automated script, this is done automatically. Otherwise:**

```bash
# Get ADF managed identity principal ID
ADF_PRINCIPAL_ID=$(az datafactory show \
  --resource-group kafka-tutorials-rg \
  --name kafka-etl-adf-dev \
  --query identity.principalId -o tsv)

# Get storage account resource ID
STORAGE_ID=$(az storage account show \
  --name <storage-account-name> \
  --resource-group kafka-tutorials-rg \
  --query id -o tsv)

# Grant ADF access to Blob Storage
az role assignment create \
  --assignee $ADF_PRINCIPAL_ID \
  --role "Storage Blob Data Contributor" \
  --scope $STORAGE_ID
```

### 3. Resume Synapse SQL Pool

**The SQL pool is created in a paused state to save costs. Resume it before use:**

```bash
az synapse sql pool resume \
  --name VehicleDataWarehouse \
  --workspace-name kafka-etl-synapse-dev \
  --resource-group kafka-tutorials-rg
```

**Cost**: ~$7/day for DW100c when running. Remember to pause when done!

---

### 4. Create Synapse Tables

**Connect to Synapse SQL Pool using:**
- **SQL Endpoint**: `<workspace-name>.sql.azuresynapse.net`
- **Database**: `VehicleDataWarehouse`
- **Username**: `sqladmin` (or your configured value)
- **Password**: (the password you set during deployment)

**Execute SQL scripts from:**
```
module-6-complete-pipeline/lab/synapse-scripts/01-create-schema.sql
module-6-complete-pipeline/lab/synapse-scripts/02-stored-procedures.sql
```

---

### 5. Configure ADF Linked Services

**Create Linked Services in Data Factory:**

**a) Blob Storage Linked Service**
```json
{
  "name": "LS_AzureBlobStorage",
  "type": "AzureBlobStorage",
  "typeProperties": {
    "serviceEndpoint": "https://<storage-account-name>.blob.core.windows.net",
    "authentication": "ManagedIdentity"
  }
}
```

**b) Synapse Linked Service**
```json
{
  "name": "LS_AzureSynapse",
  "type": "AzureSqlDW",
  "typeProperties": {
    "connectionString": "Server=<workspace-name>.sql.azuresynapse.net;Database=VehicleDataWarehouse;",
    "authentication": "ManagedIdentity"
  }
}
```

**Create via Azure Portal**:
1. Navigate to Data Factory → Author → Connections → Linked services
2. Click + New
3. Select "Azure Blob Storage" → Continue
4. Enter name and select managed identity authentication
5. Repeat for Synapse Analytics

---

### 6. Import ADF Pipelines

```bash
# Import simple copy pipeline
az datafactory pipeline create \
  --resource-group kafka-tutorials-rg \
  --factory-name kafka-etl-adf-dev \
  --name SimpleCopyBlobToSynapse \
  --pipeline @../adf-pipelines/01-simple-copy-blob-to-synapse.json

# Import staged load pipeline
az datafactory pipeline create \
  --resource-group kafka-tutorials-rg \
  --factory-name kafka-etl-adf-dev \
  --name StagedLoadWithValidation \
  --pipeline @../adf-pipelines/02-staged-load-with-validation.json
```

**Or use Azure Portal**:
1. Data Factory → Author → Pipelines → + New pipeline
2. Click "{}" (Code view) → Paste JSON → Save

---

## Cost Estimation

### Monthly Cost (Development Environment)

| Resource | Pricing | Monthly Cost (USD) |
|----------|---------|-------------------|
| **Blob Storage** | $0.018/GB | $0.11 (6 GB) |
| **Data Lake Storage** | $0.021/GB | $0.13 (6 GB) |
| **Data Factory** | $1/1000 runs + $0.25/DIU-hour | $1.50 (30 runs/month) |
| **Synapse SQL Pool (DW100c)** | $1.20/hour | $216/month (24/7) or $43/month (6 hrs/day) |
| **Total (24/7)** | | **~$218/month** |
| **Total (paused when not in use)** | | **~$45/month** |

**Cost Optimization Tips**:
1. **Pause SQL Pool**: Reduce from $216/month to $0 when not active
2. **Use serverless pools**: For dev/test, use Synapse serverless ($5/TB queried)
3. **Lifecycle policies**: Auto-delete old blobs after 30 days
4. **Budget alerts**: Set up alerts in Azure Cost Management at $50/month

---

## Access URLs After Deployment

### Azure Portal Resources
- **Storage Account**: `https://portal.azure.com/#view/Microsoft_Azure_Storage/BlobExplorerBlade/storageAccountId/<storage-resource-id>`
- **Data Factory**: `https://adf.azure.com/`
- **Synapse Workspace**: `https://web.azuresynapse.net/`

### Connection Endpoints
- **Blob Storage**: `https://<storage-account-name>.blob.core.windows.net`
- **Synapse SQL**: `<workspace-name>.sql.azuresynapse.net`
- **Synapse Dev**: `<workspace-name>-ondemand.sql.azuresynapse.net`

---

## Troubleshooting

### Issue 1: Deployment Fails with "Quota Exceeded"

**Error**: `QuotaExceeded: Operation could not be completed as it results in exceeding approved Total Regional vCPUs quota`

**Solution**:
1. Check current quota: Azure Portal → Subscriptions → Usage + quotas
2. Request quota increase for DW vCPUs in selected region
3. OR: Choose a smaller SQL Pool SKU (DW100c uses 1 vCore)
4. OR: Deploy in a different region with available quota

---

### Issue 2: Cannot Access Synapse Workspace

**Error**: `Client with IP address 'x.x.x.x' is not allowed to access the server`

**Solution**:
```bash
# Add your IP to Synapse firewall
MY_IP=$(curl -s ifconfig.me)

az synapse workspace firewall-rule create \
  --name AllowMyIP \
  --workspace-name kafka-etl-synapse-dev \
  --resource-group kafka-tutorials-rg \
  --start-ip-address $MY_IP \
  --end-ip-address $MY_IP
```

---

### Issue 3: ADF Cannot Access Storage

**Error**: `Copy activity fails with 403 Forbidden`

**Solution**:
1. Verify managed identity exists:
   ```bash
   az datafactory show --name kafka-etl-adf-dev --resource-group kafka-tutorials-rg --query identity
   ```

2. Re-grant RBAC permission:
   ```bash
   ADF_PRINCIPAL_ID="<from-step-1>"
   az role assignment create \
     --assignee $ADF_PRINCIPAL_ID \
     --role "Storage Blob Data Contributor" \
     --scope "/subscriptions/<sub-id>/resourceGroups/kafka-tutorials-rg/providers/Microsoft.Storage/storageAccounts/<storage-name>"
   ```

3. Wait 5-10 minutes for RBAC propagation

---

### Issue 4: SQL Pool Won't Resume

**Error**: `The operation timed out`

**Solution**:
- Resuming can take 1-2 minutes
- Check status:
  ```bash
  az synapse sql pool show \
    --name VehicleDataWarehouse \
    --workspace-name kafka-etl-synapse-dev \
    --resource-group kafka-tutorials-rg \
    --query status
  ```

---

## Cleanup (Delete All Resources)

**WARNING**: This will permanently delete all data!

```bash
# Delete entire resource group
az group delete \
  --name kafka-tutorials-rg \
  --yes \
  --no-wait
```

**Cost**: $0 after deletion. No hidden charges.

**Alternative: Pause Resources Instead**
```bash
# Pause SQL Pool only (keeps data, stops compute charges)
az synapse sql pool pause \
  --name VehicleDataWarehouse \
  --workspace-name kafka-etl-synapse-dev \
  --resource-group kafka-tutorials-rg
```

---

## Security Best Practices

### For Production Deployments

1. **Disable Public Network Access**
   - Set `enablePublicNetworkAccess` parameter to `false`
   - Use Private Endpoints for all services
   - Deploy inside Azure Virtual Network

2. **Use Azure Key Vault**
   - Store SQL admin passwords in Key Vault
   - Reference secrets in ADF linked services
   - Enable soft delete and purge protection

3. **Enable Diagnostic Logging**
   ```bash
   # Enable ADF diagnostics
   az monitor diagnostic-settings create \
     --name adf-diagnostics \
     --resource "/subscriptions/<sub-id>/resourceGroups/kafka-tutorials-rg/providers/Microsoft.DataFactory/factories/kafka-etl-adf-dev" \
     --logs '[{"category": "PipelineRuns", "enabled": true}]' \
     --workspace "<log-analytics-workspace-id>"
   ```

4. **Implement RBAC Principle of Least Privilege**
   - Don't grant Owner permissions
   - Use built-in roles (Storage Blob Data Reader vs Contributor)
   - Create custom roles for specific needs

5. **Enable Azure Defender**
   - Azure Defender for Storage
   - Azure Defender for SQL
   - Microsoft Defender for Cloud alerts

---

## Additional Resources

- [ARM Template Reference](https://learn.microsoft.com/en-us/azure/templates/)
- [Azure Data Factory ARM Templates](https://learn.microsoft.com/en-us/azure/data-factory/quickstart-create-data-factory-resource-manager-template)
- [Synapse ARM Templates](https://learn.microsoft.com/en-us/azure/synapse-analytics/quickstart-deployment-template-workspaces)
- [Azure CLI Reference](https://learn.microsoft.com/en-us/cli/azure/)

---

**Last Updated**: November 17, 2025
**Version**: 1.0
**Module 4 - Lab**: ARM Template Deployment
