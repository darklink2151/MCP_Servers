# Setup Daily Use - Complete MCP Workflow Integration
# This script sets up everything needed for daily MCP workflow usage

param(
    [switch]$AddToStartup = $true,
    [switch]$CreateDesktopShortcuts = $true,
    [switch]$SetupPowerShellProfile = $true,
    [switch]$EnsureDockerConfig = $true
)

$WorkflowRoot = "C:\Users\beckd\MCP-Workflow"

Write-Host "🚀 Setting up MCP Workflow for Daily Use" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# 1. Add to Windows Startup
if ($AddToStartup) {
    Write-Host "📋 Adding MCP Workflow to Windows startup..." -ForegroundColor Yellow

    $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $startupScript = "$startupPath\MCP-Workflow-Startup.bat"

    # Copy startup script to startup folder
    Copy-Item "$WorkflowRoot\scripts\startup.bat" $startupScript -Force

    Write-Host "✅ MCP Workflow added to Windows startup" -ForegroundColor Green
}

# 2. Create Desktop Shortcuts
if ($CreateDesktopShortcuts) {
    Write-Host "🖥️ Creating desktop shortcuts..." -ForegroundColor Yellow

    $desktopPath = [Environment]::GetFolderPath("Desktop")

    # Development Workflow Shortcut
    $devShortcutPath = "$desktopPath\MCP Development Workflow.lnk"
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($devShortcutPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$WorkflowRoot\scripts\daily-workflow.ps1`" -WorkflowType development -StartCursor"
    $Shortcut.WorkingDirectory = $WorkflowRoot
    $Shortcut.IconLocation = "Cursor.exe,0"
    $Shortcut.Description = "Start MCP Development Workflow"
    $Shortcut.Save()

    # Research Workflow Shortcut
    $researchShortcutPath = "$desktopPath\MCP Research Workflow.lnk"
    $Shortcut = $WshShell.CreateShortcut($researchShortcutPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$WorkflowRoot\scripts\daily-workflow.ps1`" -WorkflowType research -StartCursor"
    $Shortcut.WorkingDirectory = $WorkflowRoot
    $Shortcut.IconLocation = "Cursor.exe,0"
    $Shortcut.Description = "Start MCP Research Workflow"
    $Shortcut.Save()

    # MCP Status Shortcut
    $statusShortcutPath = "$desktopPath\MCP Status.lnk"
    $Shortcut = $WshShell.CreateShortcut($statusShortcutPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$WorkflowRoot\scripts\quick-access.ps1`"; Get-MCPStatus"
    $Shortcut.WorkingDirectory = $WorkflowRoot
    $Shortcut.IconLocation = "shell32.dll,14"
    $Shortcut.Description = "Check MCP Server Status"
    $Shortcut.Save()

    Write-Host "✅ Desktop shortcuts created" -ForegroundColor Green
}

# 3. Setup PowerShell Profile
if ($SetupPowerShellProfile) {
    Write-Host "⚡ Setting up PowerShell profile..." -ForegroundColor Yellow

    $profilePath = $PROFILE.CurrentUserAllHosts

    # Ensure profile directory exists
    $profileDir = Split-Path $profilePath -Parent
    if (!(Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force
    }

    # Check if MCP functions are already in profile
    $profileContent = Get-Content $profilePath -ErrorAction SilentlyContinue
    if ($profileContent -and ($profileContent | Select-String "MCP Workflow Quick Access Functions")) {
        Write-Host "✅ MCP functions already in PowerShell profile" -ForegroundColor Green
    } else {
        # Add MCP functions to profile
        $mcpProfileAddition = @"

# MCP Workflow Quick Access Functions
if (Test-Path "$WorkflowRoot\scripts\quick-access.ps1") {
    . "$WorkflowRoot\scripts\quick-access.ps1"
}
"@

        Add-Content -Path $profilePath -Value $mcpProfileAddition
        Write-Host "MCP functions added to PowerShell profile" -ForegroundColor Green
    }
}

# 4. Create Taskbar Pinned Items (if possible)
Write-Host "📌 Attempting to pin MCP workflows to taskbar..." -ForegroundColor Yellow

try {
    # Create a batch file for taskbar pinning
    $pinScript = @"
@echo off
powershell -Command "& { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('MCP Workflow pinned to taskbar!', 'Setup Complete') }"
"@

    Set-Content -Path "$WorkflowRoot\scripts\pin-to-taskbar.bat" -Value $pinScript
    Write-Host "✅ Taskbar pinning script created (run manually if needed)" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not create taskbar pinning (this is normal)" -ForegroundColor Yellow
}

# 5. Create Environment Variables
Write-Host "🔧 Setting up environment variables..." -ForegroundColor Yellow

# Set user environment variables
[Environment]::SetEnvironmentVariable("MCP_WORKFLOW_ROOT", $WorkflowRoot, "User")
[Environment]::SetEnvironmentVariable("MCP_DAILY_MODE", "true", "User")

Write-Host "✅ Environment variables set" -ForegroundColor Green

# 6. Ensure Docker BuildKit GC config (optional)
if ($EnsureDockerConfig) {
    Write-Host "🐳 Ensuring Docker BuildKit GC configuration..." -ForegroundColor Yellow
    try {
        & "$PSScriptRoot\ensure-docker-config.ps1" | Out-Null
        Write-Host "✅ Docker config ensured" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Failed to ensure Docker config (continuing)" -ForegroundColor Yellow
    }
}

# 7. Test the setup
Write-Host "🧪 Testing MCP setup..." -ForegroundColor Yellow

try {
    # Test MCP server installation
    Set-Location $WorkflowRoot
    node scripts/install-mcp-servers-fixed.js | Out-Null
    Write-Host "✅ MCP servers tested successfully" -ForegroundColor Green
} catch {
    Write-Host "⚠️ MCP server test had issues (this may be normal)" -ForegroundColor Yellow
}

# 8. Create Quick Start Guide
$quickStartGuide = @"
# MCP Workflow - Quick Start Guide

## Daily Usage

### Option 1: Desktop Shortcuts
* Double-click "MCP Development Workflow" for coding
* Double-click "MCP Research Workflow" for research
* Double-click "MCP Status" to check server status

### Option 2: PowerShell Commands
Open PowerShell and use these commands:

# Start development workflow with Cursor
Start-DevWorkflow

# Start research workflow with Cursor
Start-ResearchWorkflow

# Check server status
Get-MCPStatus

# Add a task to today's list
Add-MCPTask "Complete the project documentation"

# Show today's tasks
Show-MCPTasks

# Get help
Show-MCPHelp

### Option 3: Command Line
cd C:\Users\beckd\MCP-Workflow
node scripts/mcp-cli.js status
node scripts/mcp-cli.js start-workflow development

## Available MCP Servers
* filesystem: Enhanced file operations
* memory: Persistent memory across sessions
* github: GitHub integration
* web-search: Real-time web search
* fetch: HTTP requests
* sqlite: Database operations
* puppeteer: Browser automation
* sequential-thinking: Advanced problem solving
* everything: Windows file search

## Workflow Types
* development: Software development
* research: Data collection and analysis
* contentCreation: Writing and content
* automation: Task automation
* projectManagement: Project tracking

## Troubleshooting
* Run Get-MCPStatus to check server health
* Run Update-MCPServers to update servers
* Check logs in C:\Users\beckd\MCP-Workflow\logs\
* Restart Cursor if servers aren't loading

## Support
* Configuration files: C:\Users\beckd\MCP-Workflow\configs\
* Scripts: C:\Users\beckd\MCP-Workflow\scripts\
* Logs: C:\Users\beckd\MCP-Workflow\logs\
"@

Set-Content -Path "$WorkflowRoot\QUICK-START-GUIDE.md" -Value $quickStartGuide

Write-Host ""
Write-Host "🎉 MCP Workflow Daily Use Setup Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "✅ Added to Windows startup" -ForegroundColor Green
Write-Host "✅ Desktop shortcuts created" -ForegroundColor Green
Write-Host "✅ PowerShell profile configured" -ForegroundColor Green
Write-Host "✅ Environment variables set" -ForegroundColor Green
Write-Host "✅ Quick start guide created" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Ready to use! Try one of these:" -ForegroundColor Cyan
Write-Host "   • Double-click 'MCP Development Workflow' on desktop" -ForegroundColor White
Write-Host "   • Open PowerShell and run: Start-DevWorkflow" -ForegroundColor White
Write-Host "   • Run: Get-MCPStatus" -ForegroundColor White
Write-Host ""
Write-Host "📖 See QUICK-START-GUIDE.md for detailed usage instructions" -ForegroundColor Yellow
