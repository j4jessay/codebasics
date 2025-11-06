# Exercise 27: Snowflake Time Travel Setup (Windows PowerShell)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🚀 Snowflake Time Travel Exercise Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if .env file exists
if (-Not (Test-Path .env)) {
    Write-Host "⚠️  .env file not found!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please create a .env file with your Snowflake credentials:"
    Write-Host "   1. Copy .env.example to .env"
    Write-Host "   2. Edit .env and add your credentials"
    Write-Host ""
    Write-Host "You can sign up for a free Snowflake trial at:"
    Write-Host "   https://signup.snowflake.com/"
    Write-Host ""
    exit 1
}

# Step 1: Generate data
Write-Host "📊 Generating 10,000 customer records in Snowflake..." -ForegroundColor Yellow
docker compose up generate-data

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "✅ Setup Complete!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Yellow
    Write-Host "⚠️  Setup had issues!" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "If data generation failed, see README.md Troubleshooting section"
    Write-Host "You may need to:"
    Write-Host "  - Check your network connection"
    Write-Host "  - Verify Snowflake credentials in .env"
    Write-Host "  - Verify warehouse is running"
    Write-Host ""
}
Write-Host ""
Write-Host "📝 Next steps:"
Write-Host "   1. Complete the TODOs in main_challenge.py"
Write-Host "   2. Run your solution: docker compose up run"
Write-Host "   3. Compare with solution: docker compose up solution"
Write-Host ""
Write-Host "🛠️  Useful Commands:"
Write-Host "   Clean up:  docker compose down -v"
Write-Host ""
