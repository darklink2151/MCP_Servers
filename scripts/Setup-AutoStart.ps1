#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Sets up automated startup for MCP servers
.DESCRIPTION
    Creates scheduled tasks to start MCP servers on system boot or user login
#>
param(
    [Parameter(Position=0)]
    [ValidateSet("Login", "Boot")]
    [string]$StartTrigger = "Login",
    
    [Parameter(Position=1)]
    [string]$WorkflowName = "development"
)

# Create task to run at user login or system boot
$taskName = "MCP-AutoStart"
$scriptPath = Join-Path $PSScriptRoot "..\START-DAILY.ps1"
$workingDir = Split-Path $PSScriptRoot -Parent

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "Task '$taskName' already exists. Removing..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Create the action to run the script
$action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -WorkingDirectory $workingDir

# Create the trigger based on parameter
if ($StartTrigger -eq "Login") {
    $trigger = New-ScheduledTaskTrigger -AtLogon -User $env:USERNAME
    $triggerDesc = "user login"
} else {
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $triggerDesc = "system boot"
}

# Create settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

# Register the task
try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal | Out-Null
    Write-Host "✅ MCP AutoStart task created successfully!" -ForegroundColor Green
    Write-Host "   - Trigger: At $triggerDesc" -ForegroundColor White
    Write-Host "   - Workflow: $WorkflowName" -ForegroundColor White
    Write-Host "   - Script: $scriptPath" -ForegroundColor White
} catch {
    Write-Host "❌ Failed to create task: $($_.Exception.Message)" -ForegroundColor Red
}

# Update START-DAILY.ps1 to use the selected workflow
try {
    $dailyScriptPath = Join-Path $PSScriptRoot "..\START-DAILY.ps1"
    $content = Get-Content $dailyScriptPath -Raw
    $pattern = '^\$defaultWorkflow = ".*"'
    $replacement = "`$defaultWorkflow = `"$WorkflowName`""
    $updatedContent = $content -replace $pattern, $replacement
    Set-Content -Path $dailyScriptPath -Value $updatedContent -Force
    
    Write-Host "✅ Updated default workflow to '$WorkflowName'" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not update default workflow: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n🚀 AutoStart setup complete!" -ForegroundColor Cyan
Write-Host "   MCP servers will start automatically at $triggerDesc" -ForegroundColor White