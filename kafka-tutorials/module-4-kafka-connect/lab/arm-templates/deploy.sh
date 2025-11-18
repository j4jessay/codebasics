#!/bin/bash

##############################################################################
# Azure Resource Deployment Script
# Deploys all Azure resources required for Kafka-to-Azure ETL pipeline
##############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Kafka ETL - Azure Resource Deployment${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}ERROR: Azure CLI is not installed${NC}"
    echo "Please install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
echo -e "${YELLOW}Checking Azure CLI login status...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Please login to Azure:${NC}"
    az login
fi

# Display current subscription
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo -e "\n${GREEN}Current Subscription:${NC} $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# Prompt for confirmation or subscription change
read -p "Continue with this subscription? (y/n): " CONTINUE
if [[ $CONTINUE != "y" ]]; then
    echo -e "${YELLOW}Listing available subscriptions:${NC}"
    az account list --output table
    read -p "Enter subscription ID to use: " NEW_SUB_ID
    az account set --subscription $NEW_SUB_ID
    echo -e "${GREEN}Switched to subscription: $(az account show --query name -o tsv)${NC}"
fi

# Configuration
read -p "Enter resource group name [kafka-tutorials-rg]: " RESOURCE_GROUP
RESOURCE_GROUP=${RESOURCE_GROUP:-kafka-tutorials-rg}

read -p "Enter Azure region [eastus]: " LOCATION
LOCATION=${LOCATION:-eastus}

read -p "Enter project name prefix (max 11 chars) [kafka-etl]: " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-kafka-etl}

read -p "Enter environment (dev/test/prod) [dev]: " ENVIRONMENT
ENVIRONMENT=${ENVIRONMENT:-dev}

# Generate secure password for Synapse SQL Admin
echo -e "\n${YELLOW}Synapse SQL Admin Configuration${NC}"
read -p "Enter Synapse SQL admin username [sqladmin]: " SQL_ADMIN
SQL_ADMIN=${SQL_ADMIN:-sqladmin}

echo -e "${YELLOW}Password requirements: min 12 chars, include uppercase, lowercase, number, and special char${NC}"
read -sp "Enter Synapse SQL admin password: " SQL_PASSWORD
echo

# Validate password strength (basic check)
if [ ${#SQL_PASSWORD} -lt 12 ]; then
    echo -e "${RED}ERROR: Password must be at least 12 characters${NC}"
    exit 1
fi

read -p "Enter Synapse SQL Pool SKU [DW100c]: " SQL_POOL_SKU
SQL_POOL_SKU=${SQL_POOL_SKU:-DW100c}

# Create resource group if it doesn't exist
echo -e "\n${YELLOW}Creating resource group: $RESOURCE_GROUP in $LOCATION...${NC}"
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --output table

# Deploy ARM template
echo -e "\n${GREEN}Starting Azure resource deployment...${NC}"
echo -e "${YELLOW}This may take 5-10 minutes. Please wait...${NC}\n"

DEPLOYMENT_NAME="kafka-etl-deployment-$(date +%Y%m%d-%H%M%S)"

az deployment group create \
  --name $DEPLOYMENT_NAME \
  --resource-group $RESOURCE_GROUP \
  --template-file azuredeploy.json \
  --parameters \
    projectName=$PROJECT_NAME \
    environment=$ENVIRONMENT \
    location=$LOCATION \
    synapseSqlAdminUsername=$SQL_ADMIN \
    synapseSqlAdminPassword=$SQL_PASSWORD \
    synapseSqlPoolSKU=$SQL_POOL_SKU \
    enablePublicNetworkAccess=true \
  --output table

# Check deployment status
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✓ Deployment completed successfully!${NC}\n"
else
    echo -e "\n${RED}✗ Deployment failed. Check error messages above.${NC}"
    exit 1
fi

# Retrieve deployment outputs
echo -e "${YELLOW}Retrieving deployment outputs...${NC}\n"

STORAGE_ACCOUNT=$(az deployment group show \
  --name $DEPLOYMENT_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.outputs.storageAccountName.value -o tsv)

DATA_FACTORY=$(az deployment group show \
  --name $DEPLOYMENT_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.outputs.dataFactoryName.value -o tsv)

SYNAPSE_WORKSPACE=$(az deployment group show \
  --name $DEPLOYMENT_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.outputs.synapseWorkspaceName.value -o tsv)

SYNAPSE_SQL_POOL=$(az deployment group show \
  --name $DEPLOYMENT_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.outputs.synapseSqlPoolName.value -o tsv)

SYNAPSE_SQL_ENDPOINT=$(az deployment group show \
  --name $DEPLOYMENT_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.outputs.synapseSqlEndpoint.value -o tsv)

ADF_PRINCIPAL_ID=$(az deployment group show \
  --name $DEPLOYMENT_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.outputs.dataFactoryPrincipalId.value -o tsv)

# Display summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Resource Group:         ${YELLOW}$RESOURCE_GROUP${NC}"
echo -e "Location:               ${YELLOW}$LOCATION${NC}"
echo -e "Storage Account:        ${YELLOW}$STORAGE_ACCOUNT${NC}"
echo -e "Data Factory:           ${YELLOW}$DATA_FACTORY${NC}"
echo -e "Synapse Workspace:      ${YELLOW}$SYNAPSE_WORKSPACE${NC}"
echo -e "Synapse SQL Pool:       ${YELLOW}$SYNAPSE_SQL_POOL${NC}"
echo -e "Synapse SQL Endpoint:   ${YELLOW}$SYNAPSE_SQL_ENDPOINT${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Configure RBAC permissions
echo -e "${YELLOW}Configuring RBAC permissions...${NC}\n"

echo -e "1. Granting ADF 'Storage Blob Data Contributor' role on Storage Account..."
az role assignment create \
  --assignee $ADF_PRINCIPAL_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT" \
  --output table || echo -e "${YELLOW}   (Role may already exist)${NC}"

echo -e "\n2. Granting current user access to Synapse workspace..."
CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)
az synapse role assignment create \
  --workspace-name $SYNAPSE_WORKSPACE \
  --role "Synapse Administrator" \
  --assignee $CURRENT_USER_ID \
  --output table 2>/dev/null || echo -e "${YELLOW}   (Role may already exist)${NC}"

# Pause Synapse SQL Pool to save costs
echo -e "\n${YELLOW}Would you like to pause the Synapse SQL Pool to save costs?${NC}"
echo -e "${YELLOW}(You can resume it later when needed)${NC}"
read -p "Pause SQL Pool now? (y/n): " PAUSE_POOL

if [[ $PAUSE_POOL == "y" ]]; then
    echo -e "${YELLOW}Pausing Synapse SQL Pool: $SYNAPSE_SQL_POOL...${NC}"
    az synapse sql pool pause \
      --name $SYNAPSE_SQL_POOL \
      --workspace-name $SYNAPSE_WORKSPACE \
      --resource-group $RESOURCE_GROUP \
      --output table
    echo -e "${GREEN}✓ SQL Pool paused successfully${NC}"
fi

# Save configuration to file
CONFIG_FILE="deployment-config.txt"
echo -e "\n${YELLOW}Saving configuration to $CONFIG_FILE...${NC}"

cat > $CONFIG_FILE <<EOF
# Kafka ETL - Azure Deployment Configuration
# Generated: $(date)

RESOURCE_GROUP=$RESOURCE_GROUP
LOCATION=$LOCATION
STORAGE_ACCOUNT=$STORAGE_ACCOUNT
DATA_FACTORY=$DATA_FACTORY
SYNAPSE_WORKSPACE=$SYNAPSE_WORKSPACE
SYNAPSE_SQL_POOL=$SYNAPSE_SQL_POOL
SYNAPSE_SQL_ENDPOINT=$SYNAPSE_SQL_ENDPOINT
SYNAPSE_SQL_ADMIN=$SQL_ADMIN

# Connection Strings (for use in applications)
BLOB_CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=$STORAGE_ACCOUNT;AccountKey=<USE_MANAGED_IDENTITY>;EndpointSuffix=core.windows.net"
SYNAPSE_CONNECTION_STRING="Server=$SYNAPSE_SQL_ENDPOINT;Database=$SYNAPSE_SQL_POOL;User ID=$SQL_ADMIN;Password=<YOUR_PASSWORD>;Encrypt=true;TrustServerCertificate=false;"

# Azure Portal Links
PORTAL_STORAGE=https://portal.azure.com/#@/resource/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT
PORTAL_ADF=https://portal.azure.com/#@/resource/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.DataFactory/factories/$DATA_FACTORY
PORTAL_SYNAPSE=https://portal.azure.com/#@/resource/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Synapse/workspaces/$SYNAPSE_WORKSPACE
EOF

echo -e "${GREEN}✓ Configuration saved to $CONFIG_FILE${NC}"

# Display next steps
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Next Steps${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "1. Resume Synapse SQL Pool (if paused):"
echo -e "   ${YELLOW}az synapse sql pool resume --name $SYNAPSE_SQL_POOL --workspace-name $SYNAPSE_WORKSPACE --resource-group $RESOURCE_GROUP${NC}\n"

echo -e "2. Connect to Synapse and create tables:"
echo -e "   ${YELLOW}See module-6/lab/synapse-scripts/${NC}\n"

echo -e "3. Configure ADF Linked Services:"
echo -e "   ${YELLOW}See module-4/lab/adf-pipelines/README.md${NC}\n"

echo -e "4. Import ADF Pipelines:"
echo -e "   ${YELLOW}az datafactory pipeline create --resource-group $RESOURCE_GROUP --factory-name $DATA_FACTORY --name SimpleCopy --pipeline @../adf-pipelines/01-simple-copy-blob-to-synapse.json${NC}\n"

echo -e "5. Update Kafka Connect configuration:"
echo -e "   ${YELLOW}azure.storage.account.name=$STORAGE_ACCOUNT${NC}"
echo -e "   ${YELLOW}azure.storage.container.name=vehicle-telemetry${NC}\n"

echo -e "6. Access Azure Portal:"
echo -e "   Data Factory: ${YELLOW}https://adf.azure.com/${NC}"
echo -e "   Synapse: ${YELLOW}https://web.azuresynapse.net/${NC}\n"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Cost Management Tips${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "• Pause Synapse SQL Pool when not in use (saves ~\$7/day for DW100c)"
echo -e "• Enable lifecycle policies on Blob Storage to auto-delete old files"
echo -e "• Monitor ADF pipeline runs to optimize DIU usage"
echo -e "• Set budget alerts in Azure Cost Management\n"

echo -e "${GREEN}✓ Deployment complete! Check $CONFIG_FILE for details.${NC}\n"
