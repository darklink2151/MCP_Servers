#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick cleanup script for immediate process management
.DESCRIPTION
    Stops all MCP processes, cleans up any orphaned processes, and restarts the system
#>

param(
    [Parameter(Position=0)]
    [switch]$NoRestart,

    [Parameter(Position=1)]
    [string]$WorkflowName = "development"
)

Write-Host "🧹 Starting MCP cleanup process..." -ForegroundColor Cyan

# Kill all MCP-related processes
Write-Host "🛑 Stopping all MCP processes..." -ForegroundColor Yellow
$mcpProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
    $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
    $cmdLine -like "*@modelcontextprotocol*" -or $cmdLine -like "*puppeteer-mcp*" -or $cmdLine -like "*mcp-server*"
}

if ($mcpProcesses) {
    foreach ($proc in $mcpProcesses) {
        try {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Stopped process PID: $($proc.Id)" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Failed to stop PID: $($proc.Id)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  ℹ No MCP processes found running" -ForegroundColor White
}

# Check for any orphaned node processes
Write-Host "`n🔍 Checking for orphaned node processes..." -ForegroundColor Yellow
$orphanedProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
    $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
    $cmdLine -like "*npx*" -or $cmdLine -like "*server*"
}

if ($orphanedProcesses) {
    Write-Host "  ⚠️ Found orphaned node processes:" -ForegroundColor Yellow
    foreach ($proc in $orphanedProcesses) {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction SilentlyContinue).CommandLine
        Write-Host "  PID: $($proc.Id) - $cmdLine" -ForegroundColor Gray
        try {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Stopped orphaned process PID: $($proc.Id)" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Failed to stop orphaned PID: $($proc.Id)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  ✓ No orphaned node processes found" -ForegroundColor Green
}

# Clean up temp files
Write-Host "`n🗑️ Cleaning up temporary files..." -ForegroundColor Yellow
$tempDirs = @(
    "data\temp",
    "logs\temp",
    "$env:TEMP\mcp-*"
)

foreach ($dir in $tempDirs) {
    if (Test-Path $dir) {
        try {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Cleaned up: $dir" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Failed to clean up: $dir" -ForegroundColor Red
        }
    }
}

# Wait a moment to ensure everything is stopped
Write-Host "`n⏱️ Waiting for processes to fully terminate..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

# Verify all processes are stopped
$remainingProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
    $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
    $cmdLine -like "*@modelcontextprotocol*" -or $cmdLine -like "*puppeteer-mcp*" -or $cmdLine -like "*mcp-server*"
}

if ($remainingProcesses) {
    Write-Host "`n⚠️ Some MCP processes are still running!" -ForegroundColor Red
    Write-Host "  Attempting forced termination..." -ForegroundColor Yellow
    foreach ($proc in $remainingProcesses) {
        try {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Force stopped PID: $($proc.Id)" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Failed to force stop PID: $($proc.Id)" -ForegroundColor Red
        }
    }
    Start-Sleep -Seconds 1
}

Write-Host "`n✅ Cleanup complete!" -ForegroundColor Green

# Restart if requested
if (-not $NoRestart) {
    Write-Host "`n🚀 Restarting MCP with workflow: $WorkflowName" -ForegroundColor Cyan

    # Start the workflow
    try {
        & ".\START-DAILY.ps1"
        Write-Host "  ✓ MCP restarted successfully!" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to restart MCP: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Try running .\START-DAILY.ps1 manually" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n💡 To restart MCP, run: .\START-DAILY.ps1" -ForegroundColor White
}
