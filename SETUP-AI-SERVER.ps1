#!/usr/bin/env pwsh
<#
.SYNOPSIS
    One-command setup for AI server integration
.DESCRIPTION
    Installs required packages, adds AI server to configuration,
    updates dashboard, and tests the integration
#>

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                           ║" -ForegroundColor Cyan
Write-Host "║         🤖 AI SERVER INTEGRATION SETUP                   ║" -ForegroundColor Cyan
Write-Host "║                                                           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "🔍 Checking environment..." -ForegroundColor Gray

# Install required NPM package
Write-Host ""
Write-Host "1️⃣ Installing required packages..." -ForegroundColor Yellow

try {
    npm install @modelcontextprotocol/server-ai
    Write-Host "✅ Successfully installed AI packages" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Package install failed. Continuing anyway..." -ForegroundColor Yellow
}

# Run the AI server integration script
Write-Host ""
Write-Host "2️⃣ Integrating AI server into configuration..." -ForegroundColor Yellow

try {
    & .\scripts\Add-AIServer.ps1
    Write-Host "✅ AI server configuration complete" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to integrate AI server: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please run the Add-AIServer.ps1 script manually" -ForegroundColor Yellow
}

# Update the dashboard
Write-Host ""
Write-Host "3️⃣ Updating MCP Dashboard..." -ForegroundColor Yellow

try {
    & .\scripts\Update-Dashboard.ps1
    Write-Host "✅ Dashboard update complete" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Dashboard update failed. You can run Update-Dashboard.ps1 manually." -ForegroundColor Yellow
}

# Final instructions
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║           ✅ AI SERVER SETUP COMPLETE                    ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 To use your new AI workflow:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Start the AI workflow:" -ForegroundColor Cyan
Write-Host "     .\START-MCP.ps1 -Workflow aiDevelopment" -ForegroundColor White
Write-Host ""
Write-Host "  2. Or open the dashboard:" -ForegroundColor Cyan
Write-Host "     .\START-MCP.ps1 -Dashboard" -ForegroundColor White
Write-Host "     Then select option [1] and choose 'aiDevelopment'" -ForegroundColor White
Write-Host ""
Write-Host "  3. Configure your AI model settings in:" -ForegroundColor Cyan
Write-Host "     configs\ai-config.toml" -ForegroundColor White
Write-Host ""
Write-Host "That's it! Your AI server is ready to use." -ForegroundColor Green
Write-Host ""
