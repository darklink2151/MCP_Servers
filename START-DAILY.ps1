#!/usr/bin/env pwsh
<#
.SYNOPSIS
    One-click daily startup script for MCP environment
.DESCRIPTION
    Launches the most commonly used MCP servers and opens the dashboard
#>

# Start your preferred workflow (research, development, ai_development, etc)
$defaultWorkflow = "development"

# Set this to $true to auto-start dashboard
$startDashboard = $true

# Path to master configuration
$masterConfig = Join-Path $PSScriptRoot "configs" "master-config.json"

Write-Host "🚀 Starting daily MCP environment..." -ForegroundColor Cyan

# Start the workflow using basic method
$basicScript = Join-Path $PSScriptRoot "scripts" "Start-Basic.ps1"
if (Test-Path $basicScript) {
    Write-Host "🚀 Using basic startup method..." -ForegroundColor Green
    & $basicScript -WorkflowName $defaultWorkflow -ConfigPath $masterConfig
} else {
    Write-Host "⚠️ Basic script not found, using fallback method..." -ForegroundColor Yellow
    # Fallback to original method
    $startWorkflowScript = Join-Path $PSScriptRoot "scripts" "Start-Workflow.ps1"
    if (Test-Path $startWorkflowScript) {
        & $startWorkflowScript -WorkflowName $defaultWorkflow -ConfigPath $masterConfig
    } else {
        Write-Host "❌ No workflow start method available" -ForegroundColor Red
    }
}
Write-Host "✅ Workflow '$defaultWorkflow' started" -ForegroundColor Green

# Launch dashboard if enabled
if ($startDashboard) {
    Write-Host "📊 Starting MCP Dashboard..." -ForegroundColor Cyan
    Start-Process pwsh -ArgumentList "-NoExit -File `"$(Join-Path $PSScriptRoot "scripts" "Minimal-Dashboard.ps1")`"" -WindowStyle Normal
}

# Output quick help
Write-Host "`n📋 Quick Reference:" -ForegroundColor Yellow
Write-Host "  • Dashboard: .\scripts\Minimal-Dashboard.ps1" -ForegroundColor White
Write-Host "  • Status Check: .\scripts\Get-MCPStatus.ps1" -ForegroundColor White
Write-Host "  • Stop All: .\scripts\Stop-AllMCP.ps1" -ForegroundColor White
Write-Host "  • Change Workflow: .\START-DAILY.ps1 [workflowName]" -ForegroundColor White

# Create desktop shortcut for even quicker access
$createShortcut = $false  # Change to $true to create/update desktop shortcut
if ($createShortcut) {
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "MCP-Start.lnk"
    $wshShell = New-Object -ComObject WScript.Shell
    $shortcut = $wshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "pwsh.exe"
    $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$PSScriptRoot\START-DAILY.ps1`""
    $shortcut.WorkingDirectory = $PSScriptRoot
    $shortcut.IconLocation = "%SystemRoot%\System32\shell32.dll,27"
    $shortcut.Save()
    Write-Host "`n✅ Desktop shortcut created!" -ForegroundColor Green
}

