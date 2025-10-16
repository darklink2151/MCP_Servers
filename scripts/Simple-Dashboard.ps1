#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Simple MCP Dashboard - Reliable and easy to use
.DESCRIPTION
    A simplified dashboard that focuses on core functionality
#>

# Configuration
$mcpDir = "C:\Users\beckd\MCP_Servers"
$masterConfig = Join-Path $mcpDir "configs" "master-config.json"

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                      ║" -ForegroundColor Cyan
    Write-Host "║                    🚀 MCP SIMPLE DASHBOARD                          ║" -ForegroundColor Cyan
    Write-Host "║                                                                      ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  System: $env:COMPUTERNAME | User: $env:USERNAME | Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
}

function Get-MCPStatus {
    $status = @{
        Running = @()
        Stopped = @()
        Total = 0
    }

    # Get running MCP processes
    $mcpProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
        $cmdLine -like "*@modelcontextprotocol*" -or $cmdLine -like "*puppeteer-mcp*"
    }

    # Read master config
    if (Test-Path $masterConfig) {
        try {
            $config = Get-Content $masterConfig -Raw | ConvertFrom-Json
            $servers = $config.mcp.servers.PSObject.Properties
            $status.Total = $servers.Count

            foreach ($server in $servers) {
                $serverName = $server.Name
                $isRunning = $mcpProcesses | Where-Object {
                    $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
                    $cmdLine -like "*$serverName*"
                }

                if ($isRunning) {
                    $status.Running += @{
                        Name = $serverName
                        PID = $isRunning.Id
                    }
                } else {
                    $status.Stopped += @{
                        Name = $serverName
                    }
                }
            }
        } catch {
            Write-Host "❌ Error reading config: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Master config not found at: $masterConfig" -ForegroundColor Red
    }

    return $status
}

function Show-Status {
    param($Status)
    
    Write-Host "╔═══════════════════════ SERVER STATUS ════════════════════════╗" -ForegroundColor Cyan
    Write-Host ""
    
    $runningCount = $Status.Running.Count
    $totalCount = $Status.Total
    $healthPercent = if ($totalCount -gt 0) { [math]::Round(($runningCount / $totalCount) * 100, 0) } else { 0 }
    
    $healthColor = if ($healthPercent -ge 80) { "Green" } elseif ($healthPercent -ge 50) { "Yellow" } else { "Red" }
    
    Write-Host "  Overall Health: " -NoNewline -ForegroundColor White
    Write-Host "$healthPercent% " -NoNewline -ForegroundColor $healthColor
    Write-Host "($runningCount/$totalCount servers running)" -ForegroundColor Gray
    Write-Host ""
    
    if ($Status.Running.Count -gt 0) {
        Write-Host "  ✓ RUNNING SERVERS:" -ForegroundColor Green
        foreach ($server in $Status.Running) {
            Write-Host "    • $($server.Name) " -NoNewline -ForegroundColor Green
            Write-Host "PID: $($server.PID)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    if ($Status.Stopped.Count -gt 0) {
        Write-Host "  ✗ STOPPED SERVERS:" -ForegroundColor Yellow
        foreach ($server in $Status.Stopped) {
            Write-Host "    • $($server.Name)" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Menu {
    Write-Host "╔═══════════════════════ ACTIONS ══════════════════════════════╗" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] " -NoNewline -ForegroundColor Yellow
    Write-Host "Start Daily Workflow     " -NoNewline -ForegroundColor Green
    Write-Host "  [2] " -NoNewline -ForegroundColor Yellow
    Write-Host "Stop All Servers" -ForegroundColor Red
    
    Write-Host "  [3] " -NoNewline -ForegroundColor Yellow
    Write-Host "Start Specific Workflow  " -NoNewline -ForegroundColor Green
    Write-Host "  [4] " -NoNewline -ForegroundColor Yellow
    Write-Host "System Health" -ForegroundColor White
    
    Write-Host "  [R] " -NoNewline -ForegroundColor Yellow
    Write-Host "Refresh Status           " -NoNewline -ForegroundColor White
    Write-Host "  [Q] " -NoNewline -ForegroundColor Yellow
    Write-Host "Quit" -ForegroundColor Red
    
    Write-Host ""
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Start-DailyWorkflow {
    Write-Host ""
    Write-Host "🚀 Starting daily workflow..." -ForegroundColor Cyan
    Set-Location $mcpDir
    & ".\START-DAILY.ps1"
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Stop-AllServers {
    Write-Host ""
    Write-Host "🛑 Stopping all MCP servers..." -ForegroundColor Yellow
    
    $mcpProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
        $cmdLine -like "*@modelcontextprotocol*" -or $cmdLine -like "*puppeteer-mcp*"
    }
    
    if ($mcpProcesses) {
        foreach ($proc in $mcpProcesses) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Stopped process PID: $($proc.Id)" -ForegroundColor Green
        }
    } else {
        Write-Host "  ℹ No MCP servers running" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Start-SpecificWorkflow {
    Write-Host ""
    $workflows = @("development", "research", "automation", "ai_development")
    
    Write-Host "Select workflow:" -ForegroundColor White
    for ($i = 0; $i -lt $workflows.Count; $i++) {
        Write-Host "  [$($i+1)] $($workflows[$i])" -ForegroundColor Yellow
    }
    Write-Host ""
    
    $selection = Read-Host "Enter number"
    if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $workflows.Count) {
        $workflow = $workflows[[int]$selection - 1]
        Write-Host ""
        Write-Host "🚀 Starting workflow: $workflow" -ForegroundColor Green
        
        Set-Location $mcpDir
        $cliPath = Join-Path $mcpDir "scripts" "mcp-cli.js"
        if (Test-Path $cliPath) {
            & node $cliPath start-workflow $workflow -c $masterConfig
        } else {
            Write-Host "❌ mcp-cli.js not found" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-SystemHealth {
    Write-Host ""
    Write-Host "╔═══════════════════════ SYSTEM HEALTH ════════════════════════╗" -ForegroundColor Cyan
    Write-Host ""
    
    # CPU Usage
    $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
    if ($cpu) {
        $cpuValue = [math]::Round($cpu.CounterSamples[0].CookedValue, 1)
        $cpuColor = if ($cpuValue -lt 70) { "Green" } elseif ($cpuValue -lt 90) { "Yellow" } else { "Red" }
        Write-Host "  CPU Usage: " -NoNewline -ForegroundColor White
        Write-Host "$cpuValue%" -ForegroundColor $cpuColor
    }
    
    # Memory Usage
    $os = Get-CimInstance Win32_OperatingSystem
    $totalMem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeMem = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedMem = $totalMem - $freeMem
    $memPercent = [math]::Round(($usedMem / $totalMem) * 100, 1)
    $memColor = if ($memPercent -lt 70) { "Green" } elseif ($memPercent -lt 90) { "Yellow" } else { "Red" }
    
    Write-Host "  Memory: " -NoNewline -ForegroundColor White
    Write-Host "$memPercent% " -NoNewline -ForegroundColor $memColor
    Write-Host "($usedMem GB / $totalMem GB)" -ForegroundColor Gray
    
    # Node.js Version
    $nodeVersion = & node --version 2>$null
    if ($nodeVersion) {
        Write-Host "  Node.js: " -NoNewline -ForegroundColor White
        Write-Host "$nodeVersion" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Main loop
while ($true) {
    Show-Header
    $status = Get-MCPStatus
    Show-Status -Status $status
    Show-Menu
    
    $choice = Read-Host "Select action"
    
    switch ($choice.ToUpper()) {
        "1" { Start-DailyWorkflow }
        "2" { Stop-AllServers }
        "3" { Start-SpecificWorkflow }
        "4" { Show-SystemHealth }
        "R" { continue }
        "Q" {
            Write-Host ""
            Write-Host "👋 Goodbye!" -ForegroundColor Green
            Write-Host ""
            exit 0
        }
        default {
            Write-Host ""
            Write-Host "  ✗ Invalid selection" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
