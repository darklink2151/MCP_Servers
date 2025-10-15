# Simple Daily Use Setup - MCP Workflow Integration
param(
    [switch]$AddToStartup = $true,
    [switch]$CreateDesktopShortcuts = $true
)

$WorkflowRoot = "C:\Users\beckd\MCP-Workflow"

Write-Host "Setting up MCP Workflow for Daily Use" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# 1. Add to Windows Startup
if ($AddToStartup) {
    Write-Host "Adding MCP Workflow to Windows startup..." -ForegroundColor Yellow

    $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $startupScript = "$startupPath\MCP-Workflow-Startup.bat"

    Copy-Item "$WorkflowRoot\scripts\startup.bat" $startupScript -Force
    Write-Host "MCP Workflow added to Windows startup" -ForegroundColor Green
}

# 2. Create Desktop Shortcuts
if ($CreateDesktopShortcuts) {
    Write-Host "Creating desktop shortcuts..." -ForegroundColor Yellow

    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $WshShell = New-Object -comObject WScript.Shell

    # Development Workflow Shortcut
    $devShortcutPath = "$desktopPath\MCP Development Workflow.lnk"
    $Shortcut = $WshShell.CreateShortcut($devShortcutPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$WorkflowRoot\scripts\daily-workflow.ps1`" -WorkflowType development -StartCursor"
    $Shortcut.WorkingDirectory = $WorkflowRoot
    $Shortcut.Description = "Start MCP Development Workflow"
    $Shortcut.Save()

    # Research Workflow Shortcut
    $researchShortcutPath = "$desktopPath\MCP Research Workflow.lnk"
    $Shortcut = $WshShell.CreateShortcut($researchShortcutPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$WorkflowRoot\scripts\daily-workflow.ps1`" -WorkflowType research -StartCursor"
    $Shortcut.WorkingDirectory = $WorkflowRoot
    $Shortcut.Description = "Start MCP Research Workflow"
    $Shortcut.Save()

    Write-Host "Desktop shortcuts created" -ForegroundColor Green
}

# 3. Setup PowerShell Profile
Write-Host "Setting up PowerShell profile..." -ForegroundColor Yellow

$profilePath = $PROFILE.CurrentUserAllHosts
$profileDir = Split-Path $profilePath -Parent
if (!(Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force
}

$profileContent = Get-Content $profilePath -ErrorAction SilentlyContinue
if ($profileContent -and ($profileContent | Select-String "MCP Workflow")) {
    Write-Host "MCP functions already in PowerShell profile" -ForegroundColor Green
} else {
    $mcpProfileAddition = @"

# MCP Workflow Quick Access Functions
if (Test-Path "$WorkflowRoot\scripts\quick-access.ps1") {
    . "$WorkflowRoot\scripts\quick-access.ps1"
}
"@

    Add-Content -Path $profilePath -Value $mcpProfileAddition
    Write-Host "MCP functions added to PowerShell profile" -ForegroundColor Green
}

# 4. Create Environment Variables
Write-Host "Setting up environment variables..." -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("MCP_WORKFLOW_ROOT", $WorkflowRoot, "User")
[Environment]::SetEnvironmentVariable("MCP_DAILY_MODE", "true", "User")
Write-Host "Environment variables set" -ForegroundColor Green

# 5. Create Quick Start Guide
$quickStartGuide = @"
# MCP Workflow - Quick Start Guide

## Daily Usage

### Desktop Shortcuts
- MCP Development Workflow: Start coding workflow with Cursor
- MCP Research Workflow: Start research workflow with Cursor

### PowerShell Commands
Open PowerShell and use these commands:

Start-DevWorkflow          # Start development workflow
Start-ResearchWorkflow     # Start research workflow
Get-MCPStatus             # Check server status
Show-MCPHelp              # Show all commands

### Available MCP Servers
- filesystem: Enhanced file operations
- memory: Persistent memory across sessions
- github: GitHub integration
- web-search: Real-time web search
- fetch: HTTP requests
- sqlite: Database operations
- puppeteer: Browser automation
- sequential-thinking: Advanced problem solving
- everything: Windows file search

### Troubleshooting
- Run Get-MCPStatus to check server health
- Restart Cursor if servers are not loading
- Check logs in C:\Users\beckd\MCP-Workflow\logs\
"@

Set-Content -Path "$WorkflowRoot\QUICK-START-GUIDE.md" -Value $quickStartGuide

Write-Host ""
Write-Host "MCP Workflow Daily Use Setup Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Ready to use! Try one of these:" -ForegroundColor Cyan
Write-Host "  - Double-click MCP Development Workflow on desktop" -ForegroundColor White
Write-Host "  - Open PowerShell and run: Start-DevWorkflow" -ForegroundColor White
Write-Host "  - Run: Get-MCPStatus" -ForegroundColor White
Write-Host ""
Write-Host "See QUICK-START-GUIDE.md for detailed instructions" -ForegroundColor Yellow
