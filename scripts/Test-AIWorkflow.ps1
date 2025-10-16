#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Tests the AI workflow configuration
.DESCRIPTION
    Verifies the AI workflow and configuration without actually running the AI server
#>

Write-Host "Testing AI workflow configuration..." -ForegroundColor Cyan
Write-Host ""

# Check for master config
$masterConfigPath = "configs\master-config.json"
if (Test-Path $masterConfigPath) {
    try {
        $masterConfig = Get-Content $masterConfigPath -Raw | ConvertFrom-Json

        # Check for AI server
        if ($masterConfig.mcp.servers.ai) {
            Write-Host "✅ AI server defined in master config" -ForegroundColor Green
            Write-Host "   Config Path: $($masterConfig.mcp.servers.ai.configPath)" -ForegroundColor Gray
        } else {
            Write-Host "❌ AI server not found in master config" -ForegroundColor Red
            Write-Host "   Please run SETUP-AI-SERVER.ps1" -ForegroundColor Yellow
        }

        # Check for AI workflow
        if ($masterConfig.mcp.workflows.ai_development) {
            Write-Host "✅ AI Development workflow defined" -ForegroundColor Green
            Write-Host "   Name: $($masterConfig.mcp.workflows.ai_development.name)" -ForegroundColor Gray
            Write-Host "   Servers: $($masterConfig.mcp.workflows.ai_development.servers -join ', ')" -ForegroundColor Gray
        } else {
            Write-Host "❌ AI Development workflow not found" -ForegroundColor Red
            Write-Host "   Please run SETUP-AI-SERVER.ps1" -ForegroundColor Yellow
        }

    } catch {
        Write-Host "❌ Failed to parse master config: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Master config not found at: $masterConfigPath" -ForegroundColor Red
}

# Check for AI config
$aiConfigPath = "configs\ai-config.json"
if (Test-Path $aiConfigPath) {
    Write-Host "✅ AI server config found at: $aiConfigPath" -ForegroundColor Green
} else {
    Write-Host "❌ AI server config not found" -ForegroundColor Red
}

# Check for AI config TOML
$aiTomlPath = "configs\ai-config.toml"
if (Test-Path $aiTomlPath) {
    Write-Host "✅ AI config TOML found at: $aiTomlPath" -ForegroundColor Green

    try {
        $content = Get-Content $aiTomlPath -Raw
        Write-Host "   TOML settings:" -ForegroundColor Gray
        if ($content -match '\[ai\.general\]') {
            Write-Host "   - ai.general section found" -ForegroundColor Gray
        }
        if ($content -match '\[ai\.models\]') {
            Write-Host "   - ai.models section found" -ForegroundColor Gray
        }
    } catch {
        Write-Host "   ⚠️ Could not read TOML content" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ AI config TOML not found" -ForegroundColor Red
}

# Check for dashboard update
$dashboardPath = "scripts\MCP-Dashboard.ps1"
if (Test-Path $dashboardPath) {
    try {
        $dashboardContent = Get-Content -Path $dashboardPath -Raw
        if ($dashboardContent -like "*ai_development*") {
            Write-Host "✅ Dashboard contains AI workflow references" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Dashboard does not contain AI workflow references" -ForegroundColor Yellow
            Write-Host "   Run scripts\Update-Dashboard.ps1 to update" -ForegroundColor Gray
        }
    } catch {
        Write-Host "❌ Failed to read dashboard file: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Dashboard file not found at: $dashboardPath" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test complete!" -ForegroundColor Cyan
Write-Host "To start the AI workflow, run: .\START-MCP.ps1 -Workflow ai_development" -ForegroundColor White
Write-Host ""

