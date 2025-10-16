#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick AI Server integration for MCP
.DESCRIPTION
    Simply adds the AI server to the existing configuration and creates an AI workflow
#>

# Define paths
$configDir = "configs"
$masterConfigPath = Join-Path $configDir "master-config.json"
$aiConfigPath = Join-Path $configDir "ai-config.json"

Write-Host "Adding AI server to your MCP configuration..." -ForegroundColor Cyan

# 1. Create AI server config
$aiConfig = @{
  name = "ai-server"
  version = "1.0.0"
  description = "MCP server for AI model interactions (Claude, Ollama)"
  command = "npx"
  args = @(
    "-y",
    "@modelcontextprotocol/server-ai",
    "--config",
    "configs/ai-config.toml"
  )
  env = @{}
  options = @{
    port = 7800
    host = "localhost"
  }
}

# Save AI config
$aiConfigJson = $aiConfig | ConvertTo-Json -Depth 10
Set-Content -Path $aiConfigPath -Value $aiConfigJson -Encoding UTF8
Write-Host "✅ Created AI server config at: $aiConfigPath" -ForegroundColor Green

# 2. Update master config
try {
    # Load the master config
    $masterConfig = Get-Content $masterConfigPath -Raw | ConvertFrom-Json

    # Add AI server
    $aiServerProperty = @{
        configPath = "${WORKFLOW_ROOT}/configs/ai-config.json"
        enabled = $true
        autostart = $false
        priority = 95
        description = "AI model interactions (Claude, Ollama)"
    }

    # Check if mcp.servers property exists as PSCustomObject
    if ($null -eq $masterConfig.mcp.servers) {
        $masterConfig.mcp | Add-Member -MemberType NoteProperty -Name "servers" -Value ([PSCustomObject]@{})
    }

    # Add ai server to servers
    $masterConfig.mcp.servers | Add-Member -MemberType NoteProperty -Name "ai" -Value $aiServerProperty -Force

    # Add AI workflow
    $aiWorkflow = @{
        name = "AI Development"
        description = "Workflow for developing and interacting with AI models"
        servers = @("filesystem", "memory", "github", "webSearch", "sqlite", "sequentialThinking", "ai")
        autostart = $false
    }

    if ($null -eq $masterConfig.mcp.workflows) {
        $masterConfig.mcp | Add-Member -MemberType NoteProperty -Name "workflows" -Value ([PSCustomObject]@{})
    }

    # Add ai_development workflow
    $masterConfig.mcp.workflows | Add-Member -MemberType NoteProperty -Name "ai_development" -Value $aiWorkflow -Force

    # Save the updated master config
    $masterConfigJson = $masterConfig | ConvertTo-Json -Depth 10
    Set-Content -Path $masterConfigPath -Value $masterConfigJson -Encoding UTF8
    Write-Host "✅ Updated master config with AI server and workflow" -ForegroundColor Green

} catch {
    Write-Host "❌ Failed to update master config: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Copy AI config TOML
$sourceToml = "configs\ai-config.toml"
if (Test-Path $sourceToml) {
    Write-Host "✅ AI config TOML already exists" -ForegroundColor Green
} else {
    # Create minimal config
    $aiToml = @"
# AI Configuration Settings
[ai.general]
temperature = 0.7
max_tokens = 2000

[ai.models]
default_model = "claude-3-sonnet"

[ai.behavior]
personality = "professional"
"@
    Set-Content -Path $sourceToml -Value $aiToml -Encoding UTF8
    Write-Host "✅ Created basic AI config TOML at: $sourceToml" -ForegroundColor Green
}

Write-Host "`n🚀 AI Server integration complete!" -ForegroundColor Cyan
Write-Host "To use the AI server, run:" -ForegroundColor Yellow
Write-Host ".\START-MCP.ps1 -Workflow ai_development" -ForegroundColor White
Write-Host "`nMake sure you have the AI package installed:" -ForegroundColor Yellow
Write-Host "npm install -g @modelcontextprotocol/server-ai" -ForegroundColor White

