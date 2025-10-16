#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Setup automatic MCP server startup on Windows boot/login
.DESCRIPTION
    Creates Windows Task Scheduler tasks to automatically start MCP servers
    Supports multiple trigger modes: login, boot, delayed start
.NOTES
    Version: 2.0.0
    Requires: Administrator privileges for boot triggers
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("Login", "Boot", "Both")]
    [string]$TriggerType = "Login",
    
    [Parameter()]
    [int]$DelaySeconds = 10,
    
    [Parameter()]
    [switch]$Remove
)

$ErrorActionPreference = "Stop"

# Configuration
$TaskBaseName = "MCP-Autostart"
$ScriptRoot = Split-Path $PSScriptRoot -Parent
$AutostartScript = Join-Path $PSScriptRoot "Start-Autostart.ps1"
$LogFile = Join-Path $ScriptRoot "logs" "autostart-setup.log"

# Ensure log directory exists
$logDir = Split-Path $LogFile -Parent
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logMessage
    
    switch ($Level) {
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "WARN" { Write-Host $Message -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        default { Write-Host $Message }
    }
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Remove-AutoStartTasks {
    Write-Log "Removing existing auto-start tasks..." "INFO"
    
    $tasks = @("$TaskBaseName-Login", "$TaskBaseName-Boot", $TaskBaseName)
    
    foreach ($taskName in $tasks) {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($task) {
            try {
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
                Write-Log "  ✓ Removed task: $taskName" "SUCCESS"
            } catch {
                Write-Log "  ✗ Failed to remove task $taskName`: $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

function New-LoginAutoStartTask {
    $taskName = "$TaskBaseName-Login"
    Write-Log "Creating login auto-start task: $taskName" "INFO"
    
    # Action: Run PowerShell script
    $action = New-ScheduledTaskAction `
        -Execute "pwsh.exe" `
        -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$AutostartScript`""
    
    # Trigger: At user logon with delay
    $trigger = New-ScheduledTaskTrigger -AtLogon -User $env:USERNAME
    if ($DelaySeconds -gt 0) {
        $trigger.Delay = "PT$($DelaySeconds)S"
    }
    
    # Settings
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -ExecutionTimeLimit (New-TimeSpan -Hours 0) `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)
    
    # Principal: Current user, highest privileges
    $principal = New-ScheduledTaskPrincipal `
        -UserId $env:USERNAME `
        -LogonType Interactive `
        -RunLevel Highest
    
    try {
        Register-ScheduledTask `
            -TaskName $taskName `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -Principal $principal `
            -Description "Auto-start MCP servers when user logs in (${env:USERNAME})" `
            -Force | Out-Null
        
        Write-Log "  ✓ Login task created successfully" "SUCCESS"
        Write-Log "    Trigger: At logon (delay: ${DelaySeconds}s)" "INFO"
        return $true
    } catch {
        Write-Log "  ✗ Failed to create login task: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function New-BootAutoStartTask {
    $taskName = "$TaskBaseName-Boot"
    Write-Log "Creating boot auto-start task: $taskName" "INFO"
    
    if (-not (Test-Administrator)) {
        Write-Log "  ⚠ Administrator privileges required for boot trigger. Skipping..." "WARN"
        return $false
    }
    
    # Action: Run PowerShell script
    $action = New-ScheduledTaskAction `
        -Execute "pwsh.exe" `
        -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$AutostartScript`""
    
    # Trigger: At system startup with delay
    $trigger = New-ScheduledTaskTrigger -AtStartup
    if ($DelaySeconds -gt 0) {
        $trigger.Delay = "PT$($DelaySeconds)S"
    }
    
    # Settings
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -ExecutionTimeLimit (New-TimeSpan -Hours 0) `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)
    
    # Principal: System account with highest privileges
    $principal = New-ScheduledTaskPrincipal `
        -UserId $env:USERNAME `
        -LogonType S4U `
        -RunLevel Highest
    
    try {
        Register-ScheduledTask `
            -TaskName $taskName `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -Principal $principal `
            -Description "Auto-start MCP servers at system boot" `
            -Force | Out-Null
        
        Write-Log "  ✓ Boot task created successfully" "SUCCESS"
        Write-Log "    Trigger: At startup (delay: ${DelaySeconds}s)" "INFO"
        return $true
    } catch {
        Write-Log "  ✗ Failed to create boot task: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Show-TaskStatus {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "         AUTO-START TASK STATUS" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $tasks = Get-ScheduledTask -TaskName "$TaskBaseName*" -ErrorAction SilentlyContinue
    
    if ($tasks) {
        foreach ($task in $tasks) {
            $statusColor = if ($task.State -eq "Ready") { "Green" } else { "Yellow" }
            Write-Host "  Task: " -NoNewline
            Write-Host "$($task.TaskName)" -ForegroundColor Cyan
            Write-Host "  State: " -NoNewline
            Write-Host "$($task.State)" -ForegroundColor $statusColor
            Write-Host "  Next Run: " -NoNewline
            
            $info = Get-ScheduledTaskInfo -TaskName $task.TaskName -ErrorAction SilentlyContinue
            if ($info.NextRunTime) {
                Write-Host "$($info.NextRunTime)" -ForegroundColor Gray
            } else {
                Write-Host "At next trigger event" -ForegroundColor Gray
            }
            
            if ($info.LastRunTime -ne $null) {
                Write-Host "  Last Run: " -NoNewline
                Write-Host "$($info.LastRunTime)" -ForegroundColor Gray
                Write-Host "  Last Result: " -NoNewline
                $resultColor = if ($info.LastTaskResult -eq 0) { "Green" } else { "Red" }
                Write-Host "0x$($info.LastTaskResult.ToString('X'))" -ForegroundColor $resultColor
            }
            
            Write-Host ""
        }
    } else {
        Write-Host "  No auto-start tasks found" -ForegroundColor Yellow
        Write-Host ""
    }
    
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

# Main execution
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         MCP AUTO-START SETUP                          ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Log "Auto-start setup started" "INFO"
Write-Log "Script: $AutostartScript" "INFO"
Write-Log "Trigger Type: $TriggerType" "INFO"
Write-Log "Delay: ${DelaySeconds}s" "INFO"

# Verify autostart script exists
if (-not (Test-Path $AutostartScript)) {
    Write-Log "Autostart script not found: $AutostartScript" "ERROR"
    exit 1
}

# Remove existing tasks if requested
if ($Remove) {
    Remove-AutoStartTasks
    Write-Host ""
    Write-Log "Auto-start tasks removed" "SUCCESS"
    exit 0
}

# Remove any existing tasks before creating new ones
Remove-AutoStartTasks

Write-Host ""

# Create tasks based on trigger type
$success = $true

switch ($TriggerType) {
    "Login" {
        $success = New-LoginAutoStartTask
    }
    "Boot" {
        $success = New-BootAutoStartTask
    }
    "Both" {
        $loginSuccess = New-LoginAutoStartTask
        $bootSuccess = New-BootAutoStartTask
        $success = $loginSuccess -or $bootSuccess
    }
}

Write-Host ""

if ($success) {
    Write-Log "✓ Auto-start setup completed successfully!" "SUCCESS"
    Write-Host ""
    Write-Host "  MCP servers will now automatically start when:" -ForegroundColor Green
    
    switch ($TriggerType) {
        "Login" { Write-Host "    • You log in to Windows" -ForegroundColor Gray }
        "Boot" { Write-Host "    • Windows starts up" -ForegroundColor Gray }
        "Both" { 
            Write-Host "    • Windows starts up" -ForegroundColor Gray 
            Write-Host "    • You log in to Windows" -ForegroundColor Gray 
        }
    }
    
    if ($DelaySeconds -gt 0) {
        Write-Host "    • With a ${DelaySeconds} second delay for system stability" -ForegroundColor Gray
    }
} else {
    Write-Log "⚠ Auto-start setup completed with warnings" "WARN"
    Write-Host ""
    Write-Host "  Some tasks may not have been created successfully." -ForegroundColor Yellow
    Write-Host "  Check the log file for details: $LogFile" -ForegroundColor Gray
}

Write-Host ""
Show-TaskStatus

Write-Log "Auto-start setup finished" "INFO"
Write-Host ""

