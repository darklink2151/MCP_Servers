#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete MCP restart with cleanup
.DESCRIPTION
    Performs a full cleanup and restart of the MCP environment
#>

param(
    [Parameter(Position=0)]
    [string]$WorkflowName = "development",
    
    [Parameter(Position=1)]
    [switch]$ForceCleanup,
    
    [Parameter(Position=2)]
    [switch]$MinimalUI
)

# Banner
if (-not $MinimalUI) {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                      ║" -ForegroundColor Cyan
    Write-Host "║                     🔄 MCP COMPLETE RESTART                          ║" -ForegroundColor Cyan
    Write-Host "║                                                                      ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Step 1: Run thorough cleanup
Write-Host "🧹 Step 1/3: Cleaning up all MCP processes..." -ForegroundColor Yellow

$cleanupScript = Join-Path $PSScriptRoot "scripts\Cleanup-Processes.ps1"
if (Test-Path $cleanupScript) {
    $cleanupArgs = @()
    if ($ForceCleanup) { $cleanupArgs += "-Force" }
    if ($MinimalUI) { $cleanupArgs += "-Silent" }
    
    & $cleanupScript @cleanupArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️ Cleanup reported issues. Continuing anyway..." -ForegroundColor Yellow
    } else {
        Write-Host "✅ Cleanup completed successfully" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️ Cleanup script not found, using basic cleanup..." -ForegroundColor Yellow
    
    # Basic cleanup
    Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
        $cmdLine -like "*@modelcontextprotocol*" -or $cmdLine -like "*puppeteer-mcp*"
    } | ForEach-Object {
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }
}

# Step 2: Wait for system to settle
Write-Host "`n⏱️ Step 2/3: Waiting for system to stabilize..." -ForegroundColor Yellow
for ($i = 3; $i -gt 0; $i--) {
    Write-Host "  Continuing in $i seconds..." -ForegroundColor Gray
    Start-Sleep -Seconds 1
}

# Step 3: Start MCP with specified workflow
Write-Host "`n🚀 Step 3/3: Starting MCP with workflow '$WorkflowName'..." -ForegroundColor Yellow

$startScript = Join-Path $PSScriptRoot "START-DAILY.ps1"
if (Test-Path $startScript) {
    # Update the default workflow in START-DAILY.ps1
    try {
        $content = Get-Content $startScript -Raw
        $pattern = '^\$defaultWorkflow = ".*"'
        $replacement = "`$defaultWorkflow = `"$WorkflowName`""
        $updatedContent = $content -replace $pattern, $replacement
        Set-Content -Path $startScript -Value $updatedContent -Force
        
        Write-Host "  ✓ Updated default workflow to '$WorkflowName'" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️ Could not update default workflow: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Start MCP
    try {
        & $startScript
        Write-Host "`n✅ MCP restarted successfully with workflow '$WorkflowName'!" -ForegroundColor Green
    } catch {
        Write-Host "`n❌ Failed to start MCP: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Try running .\START-DAILY.ps1 manually" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "`n❌ START-DAILY.ps1 not found!" -ForegroundColor Red
    Write-Host "  Please run .\START-DAILY.ps1 manually" -ForegroundColor Yellow
    exit 1
}

# Final message
if (-not $MinimalUI) {
    Write-Host "`n🎉 MCP environment has been fully restarted and is ready to use!" -ForegroundColor Cyan
}

exit 0
