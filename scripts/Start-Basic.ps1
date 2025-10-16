#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Basic MCP server startup that actually works
.DESCRIPTION
    Uses the simplest possible method to start MCP servers
#>

param(
    [Parameter(Position=0)]
    [string]$WorkflowName = "development",
    
    [Parameter(Position=1)]
    [string]$ConfigPath = "configs\master-config.json"
)

function Write-Log {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Load configuration
if (-not (Test-Path $ConfigPath)) {
    Write-Log "❌ Configuration file not found: $ConfigPath" -Color "Red"
    exit 1
}

try {
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    Write-Log "✅ Loaded configuration from $ConfigPath" -Color "Green"
} catch {
    Write-Log "❌ Failed to parse configuration: $($_.Exception.Message)" -Color "Red"
    exit 1
}

# Check if workflow exists
if (-not $config.mcp.workflows.$WorkflowName) {
    Write-Log "❌ Workflow '$WorkflowName' not found in configuration!" -Color "Red"
    exit 1
}

$workflow = $config.mcp.workflows.$WorkflowName
$servers = $workflow.servers

Write-Log "🚀 Starting workflow: $($workflow.name) ($WorkflowName)" -Color "Cyan"
Write-Log "  Servers to start: $($servers -join ', ')" -Color "Gray"

# Start servers using simple cmd approach
$startedCount = 0
foreach ($serverName in $servers) {
    $serverConfig = $config.mcp.servers.$serverName
    
    if (-not $serverConfig) {
        Write-Log "  ⚠️ Server '$serverName' not found in configuration" -Color "Yellow"
        continue
    }
    
    Write-Log "  Starting server: $serverName..." -Color "White"
    
    try {
        # Create a simple batch file to run the server
        $batchContent = "@echo off`n"
        $batchContent += "cd /d `"$PWD`"`n"
        
        # Build the command
        $command = $serverConfig.command
        $args = $serverConfig.args -join " "
        $batchContent += "`"$command`" $args`n"
        
        # Write batch file
        $batchFile = "temp_start_$serverName.bat"
        $batchContent | Out-File -FilePath $batchFile -Encoding ASCII
        
        # Start the batch file
        $process = Start-Process -FilePath $batchFile -WindowStyle Hidden -PassThru -ErrorAction Stop
        
        # Clean up batch file
        Start-Sleep -Milliseconds 100
        Remove-Item $batchFile -ErrorAction SilentlyContinue
        
        Write-Log "  ✓ Started server '$serverName' (PID: $($process.Id))" -Color "Green"
        $startedCount++
        
    } catch {
        Write-Log "  ✗ Failed to start $serverName`: $($_.Exception.Message)" -Color "Red"
    }
    
    # Small delay between starts
    Start-Sleep -Milliseconds 500
}

# Summary
Write-Log "`n✅ Started $startedCount out of $($servers.Count) servers for workflow '$WorkflowName'" -Color "Green"

if ($startedCount -gt 0) {
    Write-Log "🎉 Workflow '$WorkflowName' started successfully!" -Color "Cyan"
    exit 0
} else {
    Write-Log "❌ Failed to start workflow '$WorkflowName'" -Color "Red"
    exit 1
}
