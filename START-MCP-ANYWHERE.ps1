#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Universal MCP startup script that works from any directory
.DESCRIPTION
    Finds the MCP_Servers directory and starts the appropriate workflow
#>

# Find the MCP_Servers directory
$mcpDir = $null
$possiblePaths = @(
    "C:\Users\beckd\MCP_Servers",
    ".\MCP_Servers",
    "..\MCP_Servers",
    "$env:USERPROFILE\MCP_Servers"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $mcpDir = $path
        break
    }
}

if (-not $mcpDir) {
    Write-Host "❌ MCP_Servers directory not found!" -ForegroundColor Red
    Write-Host "Please run this script from the MCP_Servers directory or ensure it's in a standard location." -ForegroundColor Yellow
    exit 1
}

Write-Host "🚀 Found MCP directory: $mcpDir" -ForegroundColor Green

# Change to MCP directory and run the daily startup
Set-Location $mcpDir
& ".\START-DAILY.ps1"
