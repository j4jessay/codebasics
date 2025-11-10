#!/bin/bash
# ============================================================================
# Deploy Azure Blob Storage Sink Connector
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"
CONNECTOR_CONFIG="$CONFIG_DIR/azure-blob-sink.json"

echo "============================================"
echo "Azure Blob Storage Connector Deployment"
echo "============================================"

# Check if config file exists
if [ ! -f "$CONNECTOR_CONFIG" ]; then
    echo "❌ Error: Configuration file not found: $CONNECTOR_CONFIG"
    exit 1
fi

# Read Azure credentials
if [ -f "$CONFIG_DIR/azure-credentials.env" ]; then
    echo "📋 Loading Azure credentials..."
    source "$CONFIG_DIR/azure-credentials.env"
else
    echo "⚠️  Warning: azure-credentials.env not found. Using values from config file."
fi

# Update config with environment variables if they exist
if [ ! -z "$AZURE_STORAGE_ACCOUNT_NAME" ] && [ ! -z "$AZURE_STORAGE_ACCOUNT_KEY" ]; then
    echo "🔧 Updating configuration with environment variables..."

    # Create temporary config with actual credentials
    TEMP_CONFIG=$(mktemp)
    jq --arg account "$AZURE_STORAGE_ACCOUNT_NAME" \
       --arg key "$AZURE_STORAGE_ACCOUNT_KEY" \
       --arg container "${AZURE_CONTAINER_NAME:-vehicle-telemetry-data}" \
       '.config["azblob.account.name"] = $account |
        .config["azblob.account.key"] = $key |
        .config["azblob.container.name"] = $container' \
       "$CONNECTOR_CONFIG" > "$TEMP_CONFIG"

    CONNECTOR_CONFIG="$TEMP_CONFIG"
fi

# Wait for Kafka Connect to be ready
echo "⏳ Waiting for Kafka Connect to be ready..."
until docker exec kafka-connect curl -s http://localhost:8083/ > /dev/null 2>&1; do
    echo "   Waiting for Kafka Connect..."
    sleep 5
done
echo "✅ Kafka Connect is ready"

# Check if connector already exists
echo "🔍 Checking if connector already exists..."
if docker exec kafka-connect curl -s http://localhost:8083/connectors | grep -q "azure-blob-sink-connector"; then
    echo "⚠️  Connector already exists. Deleting old connector..."
    docker exec kafka-connect curl -s -X DELETE http://localhost:8083/connectors/azure-blob-sink-connector
    sleep 2
fi

# Deploy connector
echo "🚀 Deploying Azure Blob Storage Sink Connector..."
# Copy config to container and deploy from inside
docker cp "$CONNECTOR_CONFIG" kafka-connect:/tmp/connector-config.json
RESPONSE=$(docker exec kafka-connect curl -s -X POST \
  -H "Content-Type: application/json" \
  --data @/tmp/connector-config.json \
  http://localhost:8083/connectors)

if echo "$RESPONSE" | grep -q '"name"'; then
    echo "✅ Connector deployed successfully!"
    echo ""
    echo "Connector Details:"
    echo "$RESPONSE" | jq '.'
else
    echo "❌ Failed to deploy connector!"
    echo "Response: $RESPONSE"
    exit 1
fi

# Clean up temp file if created
if [ ! -z "$TEMP_CONFIG" ] && [ -f "$TEMP_CONFIG" ]; then
    rm "$TEMP_CONFIG"
fi

# Check connector status
echo ""
echo "📊 Checking connector status..."
sleep 3
docker exec kafka-connect curl -s http://localhost:8083/connectors/azure-blob-sink-connector/status | jq '.'

echo ""
echo "============================================"
echo "✅ Deployment Complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "1. Verify connector is running: docker exec kafka-connect curl -s http://localhost:8083/connectors/azure-blob-sink-connector/status"
echo "2. Check connector logs: docker logs kafka-connect"
echo "3. Monitor your Azure Blob Storage container for incoming data"
echo ""
