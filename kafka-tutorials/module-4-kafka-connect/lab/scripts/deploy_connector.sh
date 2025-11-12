#!/bin/bash
# Deploy Azure Blob Storage Sink Connector

set -e

echo "========================================"
echo "Azure Blob Connector Deployment"
echo "========================================"

# Wait for Kafka Connect to be ready
echo "⏳ Waiting for Kafka Connect to be ready..."
until curl -s http://localhost:8083/ > /dev/null 2>&1; do
    echo "   Waiting..."
    sleep 5
done
echo "✅ Kafka Connect is ready"

# Check if connector already exists
echo ""
echo "🔍 Checking if connector exists..."
if curl -s http://localhost:8083/connectors | grep -q "azure-blob-sink-connector"; then
    echo "⚠️  Connector exists. Deleting old connector..."
    curl -X DELETE http://localhost:8083/connectors/azure-blob-sink-connector
    sleep 2
fi

# Deploy connector
echo ""
echo "🚀 Deploying Azure Blob Storage Sink Connector..."
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @../config/azure-blob-sink.json

echo ""
echo ""
echo "📊 Checking connector status..."
sleep 3
curl -s http://localhost:8083/connectors/azure-blob-sink-connector/status | python3 -m json.tool

echo ""
echo "========================================"
echo "✅ Deployment Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Verify connector is running: curl http://localhost:8083/connectors/azure-blob-sink-connector/status"
echo "2. Check logs: docker logs kafka-connect"
echo "3. Monitor Azure Blob Storage for incoming data"
