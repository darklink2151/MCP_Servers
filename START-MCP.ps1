#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick-start script for MCP servers - ONE COMMAND TO RULE THEM ALL
.DESCRIPTION
    Automatically starts MCP servers with the daily essentials workflow
    Perfect for quick startup after boot or manual launch
.NOTES
    Version: 2.0.0
    This is your GO-TO script for daily use
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("daily", "development", "research", "automation", "cybersecurity", "redTeam", "osint", "webDevelopment", "organization")]
    [string]$Workflow = "daily",

    [Parameter()]
    [switch]$Dashboard,

    [Parameter()]
    [switch]$Status,

    [Parameter()]
    [switch]$Stop
)

$ErrorActionPreference = "SilentlyContinue"

# Quick setup
$ScriptRoot = $PSScriptRoot
$DashboardScript = Join-Path $ScriptRoot "scripts" "MCP-Dashboard.ps1"
$AutostartScript = Join-Path $ScriptRoot "scripts" "Start-Autostart.ps1"
$StatusScript = Join-Path $ScriptRoot "scripts" "Get-MCPStatus.ps1"
$StopScript = Join-Path $ScriptRoot "scripts" "Stop-AllMCP.ps1"

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                                            ║" -ForegroundColor Cyan
    Write-Host "  ║     🚀 MCP SERVERS - QUICK START                          ║" -ForegroundColor Cyan
    Write-Host "  ║                                                            ║" -ForegroundColor Cyan
    Write-Host "  ╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

Show-Banner

# Handle special modes
if ($Dashboard) {
    Write-Host "  🎛️  Launching Control Dashboard..." -ForegroundColor Green
    Write-Host ""
    if (Test-Path $DashboardScript) {
        & $DashboardScript
    } else {
        Write-Host "  ✗ Dashboard script not found: $DashboardScript" -ForegroundColor Red
    }
    exit 0
}

if ($Status) {
    Write-Host "  📊 Checking MCP Status..." -ForegroundColor Cyan
    Write-Host ""
    if (Test-Path $StatusScript) {
        & $StatusScript
    } else {
        Write-Host "  ✗ Status script not found" -ForegroundColor Red

        # Fallback status check
        Write-Host "  Checking for running MCP processes..." -ForegroundColor Yellow
        $mcpProcesses = Get-Process -Name "node" | Where-Object {
            $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine
            $cmdLine -like "*@modelcontextprotocol*" -or $cmdLine -like "*puppeteer-mcp*"
        }

        if ($mcpProcesses) {
            Write-Host "  ✓ Found $($mcpProcesses.Count) running MCP server(s)" -ForegroundColor Green
            $mcpProcesses | ForEach-Object {
                Write-Host "    • PID: $($_.Id) | Memory: $([math]::Round($_.WorkingSet64 / 1MB, 2)) MB" -ForegroundColor Gray
            }
        } else {
            Write-Host "  ℹ No MCP servers currently running" -ForegroundColor Yellow
        }
    }
    Write-Host ""
    exit 0
}

if ($Stop) {
    Write-Host "  🛑 Stopping all MCP servers..." -ForegroundColor Yellow
    Write-Host ""
    if (Test-Path $StopScript) {
        & $StopScript
    } else {
        # Fallback stop
        $mcpProcesses = Get-Process -Name "node" | Where-Object {
            $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine
            $cmdLine -like "*@modelcontextprotocol*" -or $cmdLine -like "*puppeteer-mcp*"
        }

        if ($mcpProcesses) {
            $mcpProcesses | Stop-Process -Force
            Write-Host "  ✓ Stopped $($mcpProcesses.Count) MCP server(s)" -ForegroundColor Green
        } else {
            Write-Host "  ℹ No MCP servers to stop" -ForegroundColor Yellow
        }
    }
    Write-Host ""
    exit 0
}

# Start workflow
Write-Host "  🚀 Starting MCP Workflow: " -NoNewline -ForegroundColor White
Write-Host "$Workflow" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Please wait while servers initialize..." -ForegroundColor Gray
Write-Host ""

# Use CLI to start workflow if available
$cliPath = Join-Path $ScriptRoot "scripts" "mcp-cli.js"
$masterConfig = Join-Path $ScriptRoot "configs" "master-config.json"

if ((Test-Path $cliPath) -and (Test-Path $masterConfig)) {
    try {
        & node $cliPath start-workflow $Workflow -c $masterConfig

        Write-Host ""
        Write-Host "  ✓ Workflow started successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Available Commands:" -ForegroundColor Cyan
        Write-Host "    .\START-MCP.ps1 -Status           # Check server status" -ForegroundColor Gray
        Write-Host "    .\START-MCP.ps1 -Dashboard        # Open control dashboard" -ForegroundColor Gray
        Write-Host "    .\START-MCP.ps1 -Stop             # Stop all servers" -ForegroundColor Gray
        Write-Host "    .\START-MCP.ps1 -Workflow <name>  # Start specific workflow" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Quick Workflows:" -ForegroundColor Cyan
        Write-Host "    • daily (default) - Core servers for daily use" -ForegroundColor Gray
        Write-Host "    • development - Full dev environment" -ForegroundColor Gray
        Write-Host "    • research - Research and analysis" -ForegroundColor Gray
        Write-Host "    • cybersecurity - Security operations" -ForegroundColor Gray
        Write-Host "    • redTeam - Red team engagement" -ForegroundColor Gray
        Write-Host "    • osint - Intelligence gathering" -ForegroundColor Gray
        Write-Host ""
    } catch {
        Write-Host "  ⚠️  Could not start workflow via CLI" -ForegroundColor Yellow
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Falling back to autostart script..." -ForegroundColor Yellow

        if (Test-Path $AutostartScript) {
            & $AutostartScript
        }
    }
} else {
    Write-Host "  ⚠️  MCP CLI not found, using autostart script..." -ForegroundColor Yellow
    Write-Host ""

    if (Test-Path $AutostartScript) {
        & $AutostartScript
        Write-Host ""
        Write-Host "  ✓ Autostart servers initialized" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Could not start MCP servers - configuration not found" -ForegroundColor Red
        Write-Host "  Please run: .\scripts\Setup-AutoStart.ps1" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "  💡 Tip: Run with -Dashboard for interactive control" -ForegroundColor Cyan
Write-Host ""
