#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Monitors MCP processes and resource usage
.DESCRIPTION
    Provides real-time monitoring of MCP processes with resource usage tracking
#>

param(
    [Parameter(Position=0)]
    [int]$RefreshInterval = 3,
    
    [Parameter(Position=1)]
    [switch]$AutoRestart,
    
    [Parameter(Position=2)]
    [switch]$LogToFile
)

$logFile = if ($LogToFile) { "logs\mcp-monitor-$(Get-Date -Format 'yyyyMMdd-HHmmss').log" } else { $null }

function Write-MonitorLog {
    param (
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewLine
    )
    
    # Write to console
    if ($NoNewLine) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
    
    # Write to log file if enabled
    if ($logFile) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] $Message"
        Add-Content -Path $logFile -Value $logMessage
    }
}

function Get-MCPProcesses {
    # Get all node processes
    $allNodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
    
    # Filter for MCP-related processes
    $mcpProcesses = $allNodeProcesses | Where-Object {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
        $cmdLine -like "*@modelcontextprotocol*" -or 
        $cmdLine -like "*puppeteer-mcp*" -or 
        $cmdLine -like "*mcp-server*"
    }
    
    return $mcpProcesses
}

function Get-ProcessInfo {
    param (
        [Parameter(Mandatory=$true)]
        [System.Diagnostics.Process]$Process
    )
    
    $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($Process.Id)" -ErrorAction SilentlyContinue).CommandLine
    
    # Extract server name from command line
    $serverName = "unknown"
    if ($cmdLine -match "@modelcontextprotocol/server-(\w+)") {
        $serverName = $matches[1]
    } elseif ($cmdLine -match "puppeteer-mcp") {
        $serverName = "puppeteer"
    }
    
    # Calculate CPU and memory usage
    $cpuPercent = [math]::Round($Process.CPU, 1)
    $memoryMB = [math]::Round($Process.WorkingSet / 1MB, 1)
    
    # Create process info object
    $processInfo = [PSCustomObject]@{
        PID = $Process.Id
        ServerName = $serverName
        CPU = $cpuPercent
        MemoryMB = $memoryMB
        StartTime = $Process.StartTime
        Runtime = (Get-Date) - $Process.StartTime
        CommandLine = $cmdLine
    }
    
    return $processInfo
}

function Show-MCPMonitor {
    param (
        [Parameter(Mandatory=$true)]
        [array]$ProcessInfoList,
        
        [int]$TotalCount,
        [int]$ExpectedCount = 0
    )
    
    # Clear screen
    Clear-Host
    
    # Show header
    Write-MonitorLog "╔══════════════════════════════════════════════════════════════════════╗" -Color "Cyan"
    Write-MonitorLog "║                     MCP PROCESS MONITOR                             ║" -Color "Cyan"
    Write-MonitorLog "╚══════════════════════════════════════════════════════════════════════╝" -Color "Cyan"
    Write-MonitorLog ""
    
    # Show summary
    $runningCount = $ProcessInfoList.Count
    $healthPercent = if ($ExpectedCount -gt 0) {
        [math]::Round(($runningCount / $ExpectedCount) * 100, 0)
    } else {
        100
    }
    
    $healthColor = if ($healthPercent -ge 80) { "Green" } elseif ($healthPercent -ge 50) { "Yellow" } else { "Red" }
    
    Write-MonitorLog "System: $env:COMPUTERNAME | Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Refresh: ${RefreshInterval}s" -Color "Gray"
    Write-MonitorLog "Running: $runningCount / $ExpectedCount MCP processes" -Color $healthColor
    Write-MonitorLog ""
    
    # Show process table header
    Write-MonitorLog "╔═══════╦════════════════════╦══════╦═════════╦════════════════════╗" -Color "Cyan"
    Write-MonitorLog "║ PID   ║ SERVER             ║ CPU% ║ MEM(MB) ║ RUNTIME            ║" -Color "Cyan"
    Write-MonitorLog "╠═══════╬════════════════════╬══════╬═════════╬════════════════════╣" -Color "Cyan"
    
    # Show process details
    foreach ($proc in $ProcessInfoList) {
        $runtimeFormatted = "{0:d\d\ h\h\ m\m\ s\s}" -f $proc.Runtime
        
        # Color based on resource usage
        $cpuColor = if ($proc.CPU -gt 50) { "Red" } elseif ($proc.CPU -gt 20) { "Yellow" } else { "Green" }
        $memColor = if ($proc.MemoryMB -gt 500) { "Red" } elseif ($proc.MemoryMB -gt 200) { "Yellow" } else { "Green" }
        
        # Format the line
        Write-MonitorLog "║ " -Color "Cyan" -NoNewLine
        Write-MonitorLog ("{0,-5}" -f $proc.PID) -NoNewLine
        Write-MonitorLog " ║ " -Color "Cyan" -NoNewLine
        Write-MonitorLog ("{0,-18}" -f $proc.ServerName) -NoNewLine
        Write-MonitorLog " ║ " -Color "Cyan" -NoNewLine
        Write-MonitorLog ("{0,4}" -f $proc.CPU) -Color $cpuColor -NoNewLine
        Write-MonitorLog " ║ " -Color "Cyan" -NoNewLine
        Write-MonitorLog ("{0,7}" -f $proc.MemoryMB) -Color $memColor -NoNewLine
        Write-MonitorLog " ║ " -Color "Cyan" -NoNewLine
        Write-MonitorLog ("{0,-18}" -f $runtimeFormatted) -NoNewLine
        Write-MonitorLog " ║" -Color "Cyan"
    }
    
    # Show table footer
    Write-MonitorLog "╚═══════╩════════════════════╩══════╩═════════╩════════════════════╝" -Color "Cyan"
    Write-MonitorLog ""
    
    # Show system resources
    $cpuTotal = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
    if ($cpuTotal) {
        $cpuValue = [math]::Round($cpuTotal.CounterSamples[0].CookedValue, 1)
        $cpuColor = if ($cpuValue -gt 80) { "Red" } elseif ($cpuValue -gt 60) { "Yellow" } else { "Green" }
        Write-MonitorLog "System CPU: $cpuValue%" -Color $cpuColor
    }
    
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($os) {
        $totalMem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeMem = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedMem = $totalMem - $freeMem
        $memPercent = [math]::Round(($usedMem / $totalMem) * 100, 1)
        $memColor = if ($memPercent -gt 80) { "Red" } elseif ($memPercent -gt 60) { "Yellow" } else { "Green" }
        Write-MonitorLog "System Memory: $memPercent% ($usedMem GB / $totalMem GB)" -Color $memColor
    }
    
    Write-MonitorLog ""
    if ($AutoRestart) {
        Write-MonitorLog "Auto-restart: Enabled (will restart if processes crash)" -Color "Yellow"
    }
    if ($LogToFile) {
        Write-MonitorLog "Logging to: $logFile" -Color "Gray"
    }
    Write-MonitorLog "Press Ctrl+C to exit" -Color "Gray"
}

# Create log directory if needed
if ($LogToFile) {
    $logDir = Split-Path $logFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    Write-MonitorLog "Starting MCP process monitor with logging to $logFile" -Color "Cyan"
}

# Determine expected process count from config
$expectedCount = 0
$masterConfigPath = Join-Path $PSScriptRoot "..\configs\master-config.json"
if (Test-Path $masterConfigPath) {
    try {
        $config = Get-Content $masterConfigPath -Raw | ConvertFrom-Json
        $expectedCount = ($config.mcp.servers.PSObject.Properties).Count
    } catch {
        $expectedCount = 9  # Default assumption
    }
}

# Main monitoring loop
try {
    while ($true) {
        # Get current MCP processes
        $mcpProcesses = Get-MCPProcesses
        
        # Get detailed process info
        $processInfoList = @()
        foreach ($proc in $mcpProcesses) {
            $processInfoList += Get-ProcessInfo -Process $proc
        }
        
        # Sort by server name
        $processInfoList = $processInfoList | Sort-Object ServerName
        
        # Display monitor
        Show-MCPMonitor -ProcessInfoList $processInfoList -TotalCount $mcpProcesses.Count -ExpectedCount $expectedCount
        
        # Check if auto-restart is needed
        if ($AutoRestart -and $mcpProcesses.Count -lt $expectedCount -and $mcpProcesses.Count -gt 0) {
            Write-MonitorLog "⚠️ Detected missing processes. Auto-restarting MCP..." -Color "Yellow"
            
            # Run restart script
            $restartScript = Join-Path $PSScriptRoot "..\RESTART-MCP.ps1"
            if (Test-Path $restartScript) {
                & $restartScript -MinimalUI
                Write-MonitorLog "✅ Auto-restart completed" -Color "Green"
            } else {
                Write-MonitorLog "❌ Restart script not found!" -Color "Red"
            }
        }
        
        # Wait for next refresh
        Start-Sleep -Seconds $RefreshInterval
    }
} catch {
    Write-MonitorLog "Monitor stopped: $($_.Exception.Message)" -Color "Red"
} finally {
    Write-MonitorLog "MCP process monitor stopped" -Color "Yellow"
}