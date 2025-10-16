#!/usr/bin/env pwsh
<#
.SYNOPSIS
    MCP Master Control Dashboard - Complete control center for all MCP operations
.DESCRIPTION
    Comprehensive dashboard for managing, monitoring, and controlling all MCP servers
    Provides real-time status, automated workflows, and system health monitoring
.NOTES
    Version: 2.0.0
    Author: DirtyWork AI
#>

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateSet("dashboard", "start", "stop", "restart", "status", "autostart", "health", "workflows")]
    [string]$Mode = "dashboard"
)

# Configuration
$Script:RootDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not $Script:RootDir -or $Script:RootDir -eq "") {
    $Script:RootDir = "C:\Users\beckd\MCP_Servers"
}

$Script:ConfigsDir = Join-Path $Script:RootDir "configs"
$Script:LogsDir = Join-Path $Script:RootDir "logs"
$Script:MasterConfig = Join-Path $Script:ConfigsDir "master-config.json"
$Script:ScriptsDir = Join-Path $Script:RootDir "scripts"

# Ensure directories exist
@($Script:LogsDir, $Script:ConfigsDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

# Color scheme
$Script:Colors = @{
    Title = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "White"
    Highlight = "Magenta"
    Dim = "DarkGray"
}

function Write-DashboardHeader {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor $Script:Colors.Title
    Write-Host "║                                                                      ║" -ForegroundColor $Script:Colors.Title
    Write-Host "║           🚀 MCP MASTER CONTROL DASHBOARD 2.0                       ║" -ForegroundColor $Script:Colors.Title
    Write-Host "║                                                                      ║" -ForegroundColor $Script:Colors.Title
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor $Script:Colors.Title
    Write-Host ""
    Write-Host "  System: $env:COMPUTERNAME | User: $env:USERNAME | Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $Script:Colors.Dim
    Write-Host ""
}

function Get-MCPServersStatus {
    $status = @{
        Running = @()
        Stopped = @()
        Total = 0
    }

    # Check for running npx processes related to MCP
    $mcpProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
        $cmdLine -like "*@modelcontextprotocol*" -or $cmdLine -like "*puppeteer-mcp*"
    }

    # Read master config to get server list
    if (Test-Path $Script:MasterConfig) {
        $config = Get-Content $Script:MasterConfig -Raw | ConvertFrom-Json
        $status.Total = $config.servers.PSObject.Properties.Count

        foreach ($server in $config.servers.PSObject.Properties) {
            $serverName = $server.Name
            $serverConfig = $server.Value

            $isRunning = $mcpProcesses | Where-Object {
                $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
                $cmdLine -like "*$serverName*"
            }

            if ($isRunning) {
                $status.Running += @{
                    Name = $serverName
                    Enabled = $serverConfig.enabled
                    Autostart = $serverConfig.autostart
                    Priority = $serverConfig.priority
                    PID = $isRunning.Id
                }
            } else {
                $status.Stopped += @{
                    Name = $serverName
                    Enabled = $serverConfig.enabled
                    Autostart = $serverConfig.autostart
                    Priority = $serverConfig.priority
                }
            }
        }
    }

    return $status
}

function Show-ServerStatus {
    param($Status)

    Write-Host "╔═══════════════════════ SERVER STATUS ════════════════════════╗" -ForegroundColor $Script:Colors.Title
    Write-Host ""

    $runningCount = $Status.Running.Count
    $totalCount = $Status.Total
    $healthPercent = if ($totalCount -gt 0) { [math]::Round(($runningCount / $totalCount) * 100, 0) } else { 0 }

    $healthColor = if ($healthPercent -ge 80) { $Script:Colors.Success }
                   elseif ($healthPercent -ge 50) { $Script:Colors.Warning }
                   else { $Script:Colors.Error }

    Write-Host "  Overall Health: " -NoNewline -ForegroundColor $Script:Colors.Info
    Write-Host "$healthPercent% " -NoNewline -ForegroundColor $healthColor
    Write-Host "($runningCount/$totalCount servers running)" -ForegroundColor $Script:Colors.Dim
    Write-Host ""

    if ($Status.Running.Count -gt 0) {
        Write-Host "  ✓ RUNNING SERVERS:" -ForegroundColor $Script:Colors.Success
        foreach ($server in $Status.Running | Sort-Object Priority -Descending) {
            $autostartBadge = if ($server.Autostart) { "[AUTO]" } else { "[MAN]" }
            Write-Host "    • $($server.Name) " -NoNewline -ForegroundColor $Script:Colors.Success
            Write-Host "$autostartBadge " -NoNewline -ForegroundColor $Script:Colors.Highlight
            Write-Host "PID: $($server.PID) " -NoNewline -ForegroundColor $Script:Colors.Dim
            Write-Host "Priority: $($server.Priority)" -ForegroundColor $Script:Colors.Dim
        }
        Write-Host ""
    }

    if ($Status.Stopped.Count -gt 0) {
        Write-Host "  ✗ STOPPED SERVERS:" -ForegroundColor $Script:Colors.Warning
        foreach ($server in $Status.Stopped | Sort-Object Priority -Descending) {
            $autostartBadge = if ($server.Autostart) { "[AUTO]" } else { "[MAN]" }
            $enabledStatus = if ($server.Enabled) { "Enabled" } else { "Disabled" }
            Write-Host "    • $($server.Name) " -NoNewline -ForegroundColor $Script:Colors.Warning
            Write-Host "$autostartBadge " -NoNewline -ForegroundColor $Script:Colors.Highlight
            Write-Host "$enabledStatus " -NoNewline -ForegroundColor $Script:Colors.Dim
            Write-Host "Priority: $($server.Priority)" -ForegroundColor $Script:Colors.Dim
        }
        Write-Host ""
    }

    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor $Script:Colors.Title
    Write-Host ""
}

function Show-WorkflowsMenu {
    if (-not (Test-Path $Script:MasterConfig)) {
        Write-Host "  ✗ Master configuration not found!" -ForegroundColor $Script:Colors.Error
        return
    }

    $config = Get-Content $Script:MasterConfig -Raw | ConvertFrom-Json

    Write-Host "╔═══════════════════════ WORKFLOWS ════════════════════════════╗" -ForegroundColor $Script:Colors.Title
    Write-Host ""

    $i = 1
    foreach ($workflow in $config.workflows.PSObject.Properties | Sort-Object Name) {
        $name = $workflow.Name
        $details = $workflow.Value
        $serverCount = $details.servers.Count

        Write-Host "  [$i] " -NoNewline -ForegroundColor $Script:Colors.Highlight
        Write-Host "$($details.name) " -NoNewline -ForegroundColor $Script:Colors.Success
        Write-Host "($name)" -ForegroundColor $Script:Colors.Dim
        Write-Host "      $($details.description)" -ForegroundColor $Script:Colors.Info
        Write-Host "      Servers: $serverCount | " -NoNewline -ForegroundColor $Script:Colors.Dim
        Write-Host "$($details.servers -join ', ')" -ForegroundColor $Script:Colors.Dim
        Write-Host ""
        $i++
    }

    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor $Script:Colors.Title
    Write-Host ""
}

function Show-MainMenu {
    Write-Host "╔═══════════════════════ ACTIONS ══════════════════════════════╗" -ForegroundColor $Script:Colors.Title
    Write-Host ""
    Write-Host "  [1] " -NoNewline -ForegroundColor $Script:Colors.Highlight
    Write-Host "Start Workflow          " -NoNewline -ForegroundColor $Script:Colors.Success
    Write-Host "  [2] " -NoNewline -ForegroundColor $Script:Colors.Highlight
    Write-Host "Start All Autostart" -ForegroundColor $Script:Colors.Success

    Write-Host "  [3] " -NoNewline -ForegroundColor $Script:Colors.Highlight
    Write-Host "Stop All Servers        " -NoNewline -ForegroundColor $Script:Colors.Warning
    Write-Host "  [4] " -NoNewline -ForegroundColor $Script:Colors.Highlight
    Write-Host "Restart All" -ForegroundColor $Script:Colors.Warning

    Write-Host "  [5] " -NoNewline -ForegroundColor $Script:Colors.Highlight
    Write-Host "View Logs               " -NoNewline -ForegroundColor $Script:Colors.Info
    Write-Host "  [6] " -NoNewline -ForegroundColor $Script:Colors.Highlight
    Write-Host "System Health" -ForegroundColor $Script:Colors.Info

    Write-Host "  [7] " -NoNewline -ForegroundColor $Script:Colors.Highlight
    Write-Host "Create Backup           " -NoNewline -ForegroundColor $Script:Colors.Info
    Write-Host "  [8] " -NoNewline -ForegroundColor $Script:Colors.Highlight
    Write-Host "Setup Auto-Start" -ForegroundColor $Script:Colors.Info

    Write-Host "  [R] " -NoNewline -ForegroundColor $Script:Colors.Highlight
    Write-Host "Refresh Status          " -NoNewline -ForegroundColor $Script:Colors.Info
    Write-Host "  [Q] " -NoNewline -ForegroundColor $Script:Colors.Highlight
    Write-Host "Quit" -ForegroundColor $Script:Colors.Error

    Write-Host ""
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor $Script:Colors.Title
    Write-Host ""
}

function Start-AutostartServers {
    Write-Host ""
    Write-Host "🚀 Starting all autostart servers..." -ForegroundColor $Script:Colors.Info
    Write-Host ""

    $cliPath = Join-Path $Script:ScriptsDir "mcp-cli.js"
    if (Test-Path $cliPath) {
        & node $cliPath start-autostart -c $Script:MasterConfig
    } else {
        Write-Host "  ✗ mcp-cli.js not found!" -ForegroundColor $Script:Colors.Error
    }

    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor $Script:Colors.Dim
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Start-WorkflowInteractive {
    Write-Host ""
    $workflows = @("development", "research", "automation", "cybersecurity", "organization", "webDevelopment", "contentCreation", "projectManagement")

    Write-Host "Select workflow:" -ForegroundColor $Script:Colors.Info
    for ($i = 0; $i -lt $workflows.Count; $i++) {
        Write-Host "  [$($i+1)] $($workflows[$i])" -ForegroundColor $Script:Colors.Highlight
    }
    Write-Host ""

    $selection = Read-Host "Enter number"
    if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $workflows.Count) {
        $workflow = $workflows[[int]$selection - 1]
        Write-Host ""
        Write-Host "🚀 Starting workflow: $workflow" -ForegroundColor $Script:Colors.Success
        Write-Host ""

        $cliPath = Join-Path $Script:ScriptsDir "mcp-cli.js"
        if (Test-Path $cliPath) {
            & node $cliPath start-workflow $workflow -c $Script:MasterConfig
        }
    }

    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor $Script:Colors.Dim
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Stop-AllMCPServers {
    Write-Host ""
    Write-Host "🛑 Stopping all MCP servers..." -ForegroundColor $Script:Colors.Warning
    Write-Host ""

    $mcpProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
        $cmdLine -like "*@modelcontextprotocol*" -or $cmdLine -like "*puppeteer-mcp*"
    }

    if ($mcpProcesses) {
        foreach ($proc in $mcpProcesses) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Stopped process PID: $($proc.Id)" -ForegroundColor $Script:Colors.Success
        }
    } else {
        Write-Host "  ℹ No MCP servers running" -ForegroundColor $Script:Colors.Info
    }

    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor $Script:Colors.Dim
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-SystemHealth {
    Write-Host ""
    Write-Host "╔═══════════════════════ SYSTEM HEALTH ════════════════════════╗" -ForegroundColor $Script:Colors.Title
    Write-Host ""

    # CPU Usage
    $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
    if ($cpu) {
        $cpuValue = [math]::Round($cpu.CounterSamples[0].CookedValue, 1)
        $cpuColor = if ($cpuValue -lt 70) { $Script:Colors.Success } elseif ($cpuValue -lt 90) { $Script:Colors.Warning } else { $Script:Colors.Error }
        Write-Host "  CPU Usage: " -NoNewline -ForegroundColor $Script:Colors.Info
        Write-Host "$cpuValue%" -ForegroundColor $cpuColor
    }

    # Memory Usage
    $os = Get-CimInstance Win32_OperatingSystem
    $totalMem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeMem = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedMem = $totalMem - $freeMem
    $memPercent = [math]::Round(($usedMem / $totalMem) * 100, 1)
    $memColor = if ($memPercent -lt 70) { $Script:Colors.Success } elseif ($memPercent -lt 90) { $Script:Colors.Warning } else { $Script:Colors.Error }

    Write-Host "  Memory: " -NoNewline -ForegroundColor $Script:Colors.Info
    Write-Host "$memPercent% " -NoNewline -ForegroundColor $memColor
    Write-Host "($usedMem GB / $totalMem GB)" -ForegroundColor $Script:Colors.Dim

    # Disk Space
    $disk = Get-PSDrive C
    $diskUsedGB = [math]::Round(($disk.Used / 1GB), 2)
    $diskFreeGB = [math]::Round(($disk.Free / 1GB), 2)
    $diskTotalGB = $diskUsedGB + $diskFreeGB
    $diskPercent = [math]::Round(($diskUsedGB / $diskTotalGB) * 100, 1)
    $diskColor = if ($diskPercent -lt 80) { $Script:Colors.Success } elseif ($diskPercent -lt 95) { $Script:Colors.Warning } else { $Script:Colors.Error }

    Write-Host "  Disk (C:): " -NoNewline -ForegroundColor $Script:Colors.Info
    Write-Host "$diskPercent% " -NoNewline -ForegroundColor $diskColor
    Write-Host "($diskFreeGB GB free)" -ForegroundColor $Script:Colors.Dim

    # Node.js Version
    $nodeVersion = & node --version 2>$null
    Write-Host "  Node.js: " -NoNewline -ForegroundColor $Script:Colors.Info
    Write-Host "$nodeVersion" -ForegroundColor $Script:Colors.Success

    # Log directory size
    if (Test-Path $Script:LogsDir) {
        $logSize = (Get-ChildItem $Script:LogsDir -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $logSizeMB = [math]::Round($logSize / 1MB, 2)
        Write-Host "  Logs Size: " -NoNewline -ForegroundColor $Script:Colors.Info
        Write-Host "$logSizeMB MB" -ForegroundColor $Script:Colors.Dim
    }

    Write-Host ""
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor $Script:Colors.Title
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor $Script:Colors.Dim
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function New-AutoStartTask {
    Write-Host ""
    Write-Host "⚙️  Setting up Windows auto-start task..." -ForegroundColor $Script:Colors.Info
    Write-Host ""

    $taskName = "MCP-Autostart"
    $scriptPath = Join-Path $Script:ScriptsDir "Start-Autostart.ps1"

    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "  ℹ Task already exists. Removing old task..." -ForegroundColor $Script:Colors.Warning
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    # Create the task
    $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoProfile -WindowStyle Hidden -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtLogon -User $env:USERNAME
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

    try {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Auto-start MCP servers on login" | Out-Null
        Write-Host "  ✓ Auto-start task created successfully!" -ForegroundColor $Script:Colors.Success
        Write-Host "    Task Name: $taskName" -ForegroundColor $Script:Colors.Dim
        Write-Host "    Trigger: At user logon" -ForegroundColor $Script:Colors.Dim
    } catch {
        Write-Host "  ✗ Failed to create task: $($_.Exception.Message)" -ForegroundColor $Script:Colors.Error
    }

    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor $Script:Colors.Dim
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Start-Dashboard {
    while ($true) {
        Write-DashboardHeader

        $status = Get-MCPServersStatus
        Show-ServerStatus -Status $status
        Show-WorkflowsMenu
        Show-MainMenu

        $choice = Read-Host "Select action"

        switch ($choice.ToUpper()) {
            "1" { Start-WorkflowInteractive }
            "2" { Start-AutostartServers }
            "3" { Stop-AllMCPServers }
            "4" {
                Stop-AllMCPServers
                Start-Sleep -Seconds 2
                Start-AutostartServers
            }
            "5" {
                Write-Host ""
                Write-Host "Recent logs:" -ForegroundColor $Script:Colors.Info
                Get-ChildItem $Script:LogsDir -Filter "*.log" -ErrorAction SilentlyContinue | ForEach-Object {
                    Write-Host "  • $($_.Name) - $(Get-Date $_.LastWriteTime -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $Script:Colors.Dim
                }
                Write-Host ""
                Write-Host "Press any key to continue..." -ForegroundColor $Script:Colors.Dim
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "6" { Show-SystemHealth }
            "7" {
                Write-Host ""
                Write-Host "Creating backup..." -ForegroundColor $Script:Colors.Info
                & (Join-Path $Script:ScriptsDir "mcp-manager.ps1") -Action backup
                Write-Host ""
                Write-Host "Press any key to continue..." -ForegroundColor $Script:Colors.Dim
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "8" { New-AutoStartTask }
            "R" { continue }
            "Q" {
                Write-Host ""
                Write-Host "👋 Goodbye!" -ForegroundColor $Script:Colors.Success
                Write-Host ""
                exit 0
            }
            default {
                Write-Host ""
                Write-Host "  ✗ Invalid selection" -ForegroundColor $Script:Colors.Error
                Start-Sleep -Seconds 1
            }
        }
    }
}

# Main execution
switch ($Mode) {
    "dashboard" { Start-Dashboard }
    "start" { Start-AutostartServers }
    "stop" { Stop-AllMCPServers }
    "status" {
        $status = Get-MCPServersStatus
        Show-ServerStatus -Status $status
    }
    "autostart" { New-AutoStartTask }
    "health" { Show-SystemHealth }
    default { Start-Dashboard }
}
