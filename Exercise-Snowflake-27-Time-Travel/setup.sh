#!/bin/bash

echo "=========================================="
echo "🚀 Snowflake Time Travel Exercise Setup"
echo "=========================================="
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found!"
    echo ""
    echo "Please create a .env file with your Snowflake credentials:"
    echo "   1. Copy .env.example to .env"
    echo "   2. Edit .env and add your credentials"
    echo ""
    echo "You can sign up for a free Snowflake trial at:"
    echo "   https://signup.snowflake.com/"
    echo ""
    exit 1
fi

# Step 1: Generate data
echo "📊 Generating 10,000 customer records in Snowflake..."
docker compose up generate-data

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Setup Complete!"
    echo "=========================================="
else
    echo ""
    echo "=========================================="
    echo "⚠️  Setup had issues!"
    echo "=========================================="
    echo ""
    echo "If data generation failed, see README.md Troubleshooting section"
    echo "You may need to:"
    echo "  - Check your network connection"
    echo "  - Verify Snowflake credentials in .env"
    echo "  - Verify warehouse is running"
    echo ""
fi
echo ""
echo "📝 Next steps:"
echo "   1. Complete the TODOs in main_challenge.py"
echo "   2. Run your solution: docker compose up run"
echo "   3. Compare with solution: docker compose up solution"
echo ""
echo "🛠️  Useful Commands:"
echo "   Clean up:  docker compose down -v"
echo ""
