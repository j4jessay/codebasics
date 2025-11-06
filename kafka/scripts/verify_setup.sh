#!/bin/bash
# ============================================================================
# Verify Kafka Setup and Data Flow
# ============================================================================

set -e

echo "============================================"
echo "Kafka Setup Verification"
echo "============================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_service() {
    local service_name=$1
    local port=$2
    local url=$3

    echo -n "🔍 Checking $service_name (port $port)... "

    if curl -s "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Running${NC}"
        return 0
    else
        echo -e "${RED}✗ Not available${NC}"
        return 1
    fi
}

check_container() {
    local container_name=$1

    echo -n "🔍 Checking container $container_name... "

    if docker ps | grep -q "$container_name"; then
        echo -e "${GREEN}✓ Running${NC}"
        return 0
    else
        echo -e "${RED}✗ Not running${NC}"
        return 1
    fi
}

# Step 1: Check Docker containers
echo "📦 Step 1: Checking Docker Containers"
echo "----------------------------------------"
check_container "zookeeper"
check_container "kafka"
check_container "ksqldb-server"
check_container "kafka-connect"
check_container "schema-registry"
check_container "control-center"
echo ""

# Step 2: Check service endpoints
echo "🌐 Step 2: Checking Service Endpoints"
echo "----------------------------------------"
check_service "Kafka" "9092" "localhost:9092"
check_service "ksqlDB Server" "8088" "http://localhost:8088/info"
check_service "Kafka Connect" "8083" "http://localhost:8083/"
check_service "Schema Registry" "8081" "http://localhost:8081/"
check_service "Control Center" "9021" "http://localhost:9021/"
echo ""

# Step 3: List Kafka topics
echo "📋 Step 3: Checking Kafka Topics"
echo "----------------------------------------"
echo "Available topics:"
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list
echo ""

# Step 4: Check ksqlDB streams
echo "📊 Step 4: Checking ksqlDB Streams"
echo "----------------------------------------"
echo "Querying ksqlDB for streams and tables..."
docker exec -it ksqldb-cli ksql http://ksqldb-server:8088 --execute "SHOW STREAMS;" 2>/dev/null || echo "No streams found or ksqlDB not configured"
echo ""

# Step 5: Check Kafka Connect connectors
echo "🔌 Step 5: Checking Kafka Connect Connectors"
echo "----------------------------------------"
CONNECTORS=$(curl -s http://localhost:8083/connectors)
if [ "$CONNECTORS" = "[]" ]; then
    echo -e "${YELLOW}⚠️  No connectors deployed${NC}"
else
    echo "Deployed connectors:"
    echo "$CONNECTORS" | jq '.'

    # Check each connector status
    for connector in $(echo "$CONNECTORS" | jq -r '.[]'); do
        echo ""
        echo "Status for $connector:"
        curl -s "http://localhost:8083/connectors/$connector/status" | jq '.'
    done
fi
echo ""

# Step 6: Check for messages in vehicle.telemetry topic
echo "📡 Step 6: Checking Data Flow"
echo "----------------------------------------"
echo "Checking for messages in vehicle.telemetry topic (will timeout after 10 seconds)..."

if timeout 10s docker exec kafka kafka-console-consumer \
    --bootstrap-server localhost:29092 \
    --topic vehicle.telemetry \
    --from-beginning \
    --max-messages 5 2>/dev/null; then
    echo -e "${GREEN}✓ Messages found in vehicle.telemetry topic${NC}"
else
    echo -e "${YELLOW}⚠️  No messages found or topic doesn't exist yet${NC}"
    echo "   This is normal if you haven't started the producer yet."
fi
echo ""

# Step 7: Summary
echo "============================================"
echo "📝 Summary"
echo "============================================"
echo ""
echo "Access points:"
echo "  • Kafka Bootstrap: localhost:9092"
echo "  • ksqlDB CLI: docker exec -it ksqldb-cli ksql http://ksqldb-server:8088"
echo "  • Kafka Connect API: http://localhost:8083"
echo "  • Control Center UI: http://localhost:9021"
echo "  • Schema Registry: http://localhost:8081"
echo ""
echo "Common commands:"
echo "  • List topics: docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list"
echo "  • Consume messages: docker exec kafka kafka-console-consumer --bootstrap-server localhost:29092 --topic <topic-name> --from-beginning"
echo "  • Check connector status: curl http://localhost:8083/connectors/<connector-name>/status"
echo ""
echo "============================================"
