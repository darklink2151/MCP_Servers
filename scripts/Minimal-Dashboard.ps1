#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Ultra-minimal MCP dashboard - no fancy UI, just works
.DESCRIPTION
    The simplest possible dashboard with no complex formatting
#>

# Configuration
$mcpDir = "C:\Users\beckd\MCP_Servers"
$masterConfig = Join-Path $mcpDir "configs" "master-config.json"

function Show-Status {
    Write-Host "=== MCP SERVER STATUS ===" -ForegroundColor Cyan
    Write-Host ""

    # Count running processes
    $mcpProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
        $cmdLine -like "*@modelcontextprotocol*" -or $cmdLine -like "*puppeteer-mcp*"
    }

    $runningCount = $mcpProcesses.Count

    Write-Host "Running MCP processes: $runningCount" -ForegroundColor Green

    if ($runningCount -gt 0) {
        Write-Host "PIDs:" -ForegroundColor White
        foreach ($proc in $mcpProcesses) {
            Write-Host "  $($proc.Id)" -ForegroundColor Gray
        }
    }

    Write-Host ""
}

function Show-Menu {
    Write-Host "=== ACTIONS ===" -ForegroundColor Yellow
    Write-Host "1. Start Daily Workflow"
    Write-Host "2. Stop All Servers"
    Write-Host "3. Show System Info"
    Write-Host "4. Exit"
    Write-Host ""
}

# Main loop
while ($true) {
    Show-Status
    Show-Menu

    try {
        $choice = Read-Host "Choose option (1-4)"
    } catch {
        Write-Host "Input error, please try again" -ForegroundColor Red
        continue
    }

    switch ($choice) {
        "1" {
            Write-Host "Starting daily workflow..." -ForegroundColor Green
            Set-Location $mcpDir
            if (Test-Path "START-DAILY.ps1") {
                & ".\START-DAILY.ps1"
            } else {
                Write-Host "START-DAILY.ps1 not found" -ForegroundColor Red
            }
            Write-Host "Press Enter to continue..."
            Read-Host
        }
        "2" {
            Write-Host "Stopping all MCP servers..." -ForegroundColor Yellow
            $mcpProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
                $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
                $cmdLine -like "*@modelcontextprotocol*" -or $cmdLine -like "*puppeteer-mcp*"
            }

            if ($mcpProcesses) {
                foreach ($proc in $mcpProcesses) {
                    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                    Write-Host "Stopped PID: $($proc.Id)" -ForegroundColor Green
                }
            } else {
                Write-Host "No MCP servers running" -ForegroundColor White
            }
            Write-Host "Press Enter to continue..."
            Read-Host
        }
        "3" {
            Write-Host "=== SYSTEM INFO ===" -ForegroundColor Cyan
            Write-Host "Computer: $env:COMPUTERNAME"
            Write-Host "User: $env:USERNAME"
            Write-Host "Time: $(Get-Date)"
            Write-Host ""

            # CPU Usage
            try {
                $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
                if ($cpu) {
                    $cpuValue = [math]::Round($cpu.CounterSamples[0].CookedValue, 1)
                    Write-Host "CPU Usage: $cpuValue%"
                }
            } catch {
                Write-Host "CPU info unavailable"
            }

            # Memory Usage
            try {
                $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
                if ($os) {
                    $totalMem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
                    $freeMem = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
                    $usedMem = $totalMem - $freeMem
                    $memPercent = [math]::Round(($usedMem / $totalMem) * 100, 1)
                    Write-Host "Memory: $memPercent% used ($usedMem GB / $totalMem GB)"
                }
            } catch {
                Write-Host "Memory info unavailable"
            }

            Write-Host ""
            Write-Host "Press Enter to continue..."
            Read-Host
        }
        "4" {
            Write-Host "Goodbye!" -ForegroundColor Green
            exit 0
        }
        default {
            Write-Host "Invalid option. Please choose 1-4." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }

    # Simple screen clear for next iteration
    Write-Host ("`n" * 2)
}
