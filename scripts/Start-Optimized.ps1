#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Optimized MCP startup script
.DESCRIPTION
    Starts MCP servers with optimized resource usage and dependency management
#>

param(
    [Parameter(Position=0)]
    [string]$WorkflowName = "development",

    [Parameter(Position=1)]
    [string]$ConfigPath = "configs\master-config.json",

    [Parameter(Position=2)]
    [switch]$NoLog
)

# Configuration
$Script:StartupLog = if (-not $NoLog) { "logs\startup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log" } else { $null }
$Script:StartupTimeout = 30  # seconds
$Script:ServerStartDelay = 1  # seconds between server starts

function Write-StartupLog {
    param (
        [string]$Message,
        [string]$Color = "White"
    )

    # Write to console
    Write-Host $Message -ForegroundColor $Color

    # Write to log file if enabled
    if ($Script:StartupLog) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] $Message"
        Add-Content -Path $Script:StartupLog -Value $logMessage -ErrorAction SilentlyContinue
    }
}

function Test-ServerRunning {
    param (
        [string]$ServerName
    )

    $processes = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
        $cmdLine -like "*$ServerName*"
    }

    return ($processes.Count -gt 0)
}

function Start-MCPServer {
    param (
        [string]$ServerName,
        [object]$ServerConfig,
        [int]$Priority = 50
    )

    # Check if server is already running
    if (Test-ServerRunning -ServerName $ServerName) {
        Write-StartupLog "  ℹ Server '$ServerName' is already running" -Color "Yellow"
        return $true
    }

    # Start the server using PowerShell's Start-Process for better compatibility
    try {
        $command = $ServerConfig.command
        $args = $ServerConfig.args

        # Handle npx as a PowerShell script
        if ($command -eq "npx") {
            $npxPath = Get-Command npx -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source
            if (-not $npxPath) {
                throw "npx not found in PATH"
            }

            $processArgs = @{
                FilePath = "powershell.exe"
                ArgumentList = @("-NoProfile", "-Command", "& `"$npxPath`" $($args -join ' ')")
                NoNewWindow = $true
                PassThru = $true
                ErrorAction = "Stop"
            }
        } else {
            $processArgs = @{
                FilePath = $command
                ArgumentList = $args
                NoNewWindow = $true
                PassThru = $true
                ErrorAction = "Stop"
            }
        }

        $process = Start-Process @processArgs

        Write-StartupLog "  ✓ Started server '$ServerName' (PID: $($process.Id))" -Color "Green"

        return $true
    }
    catch {
        Write-StartupLog "  ✗ Failed to start $ServerName`: $($_.Exception.Message)" -Color "Red"
        return $false
    }
}

function Start-MCPWorkflow {
    param (
        [string]$WorkflowName,
        [object]$Config
    )

    # Check if workflow exists
    if (-not $Config.mcp.workflows.$WorkflowName) {
        Write-StartupLog "❌ Workflow '$WorkflowName' not found in configuration!" -Color "Red"
        return $false
    }

    $workflow = $Config.mcp.workflows.$WorkflowName
    $servers = $workflow.servers

    Write-StartupLog "🚀 Starting workflow: $($workflow.name) ($WorkflowName)" -Color "Cyan"
    Write-StartupLog "  Servers to start: $($servers -join ', ')" -Color "Gray"

    # Start servers in order
    $startedCount = 0
    foreach ($serverName in $servers) {
        $serverConfig = $Config.mcp.servers.$serverName

        if (-not $serverConfig) {
            Write-StartupLog "  ⚠️ Server '$serverName' not found in configuration" -Color "Yellow"
            continue
        }

        Write-StartupLog "  Starting server: $serverName..." -Color "White"
        $result = Start-MCPServer -ServerName $serverName -ServerConfig $serverConfig

        if ($result) {
            $startedCount++
        }

        # Add delay between server starts to prevent resource contention
        Start-Sleep -Seconds $Script:ServerStartDelay
    }

    # Summary
    Write-StartupLog "`n✅ Started $startedCount out of $($servers.Count) servers for workflow '$WorkflowName'" -Color "Green"

    return ($startedCount -gt 0)
}

# Create log directory if needed
if ($Script:StartupLog) {
    $logDir = Split-Path $Script:StartupLog -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
}

# Verify config file exists
if (-not (Test-Path $ConfigPath)) {
    Write-StartupLog "❌ Configuration file not found: $ConfigPath" -Color "Red"
    exit 1
}

# Load configuration
try {
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    Write-StartupLog "✅ Loaded configuration from $ConfigPath" -Color "Green"
} catch {
    Write-StartupLog "❌ Failed to parse configuration: $($_.Exception.Message)" -Color "Red"
    exit 1
}

# Start the workflow
$result = Start-MCPWorkflow -WorkflowName $WorkflowName -Config $config

if ($result) {
    Write-StartupLog "`n🎉 Workflow '$WorkflowName' started successfully!" -Color "Cyan"
    exit 0
} else {
    Write-StartupLog "`n❌ Failed to start workflow '$WorkflowName'" -Color "Red"
    exit 1
}
