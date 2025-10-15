# Quick Access Functions for MCP Workflow
# Source this file to get instant access to MCP workflow functions

# Core MCP Functions
function Start-MCPWorkflow {
    param(
        [string]$Type = 'development',
        [switch]$StartCursor = $false
    )
    & "$PSScriptRoot\daily-workflow.ps1" -WorkflowType $Type -StartCursor:$StartCursor
}

function Get-MCPStatus {
    Set-Location "$PSScriptRoot\.."
    node scripts/mcp-cli.js status
}

function Update-MCPServers {
    Set-Location "$PSScriptRoot\.."
    node scripts/install-mcp-servers-fixed.js
}

function Backup-MCPWorkflow {
    Set-Location "$PSScriptRoot\.."
    node scripts/mcp-cli.js backup
}

# Quick workflow starters
function Start-DevWorkflow { Start-MCPWorkflow 'development' -StartCursor }
function Start-ResearchWorkflow { Start-MCPWorkflow 'research' -StartCursor }
function Start-ContentWorkflow { Start-MCPWorkflow 'contentCreation' -StartCursor }
function Start-AutomationWorkflow { Start-MCPWorkflow 'automation' -StartCursor }
function Start-ProjectWorkflow { Start-MCPWorkflow 'projectManagement' -StartCursor }

# Utility functions
function Open-MCPWorkspace {
    param([string]$WorkspaceType = "daily")
    $workspacePath = "$PSScriptRoot\..\workspaces\$workspaceType-$(Get-Date -Format 'yyyy-MM-dd')"
    if (Test-Path $workspacePath) {
        Start-Process "Cursor" -ArgumentList $workspacePath
        Write-Host "Opened workspace: $workspacePath"
    } else {
        Write-Host "Workspace not found: $workspacePath"
    }
}

function Show-MCPTasks {
    $taskFile = "$PSScriptRoot\..\workspaces\daily-$(Get-Date -Format 'yyyy-MM-dd')\tasks-$(Get-Date -Format 'yyyy-MM-dd').md"
    if (Test-Path $taskFile) {
        Get-Content $taskFile
    } else {
        Write-Host "No task file found for today. Run Start-MCPWorkflow first."
    }
}

function Add-MCPTask {
    param([string]$Task)
    $taskFile = "$PSScriptRoot\..\workspaces\daily-$(Get-Date -Format 'yyyy-MM-dd')\tasks-$(Get-Date -Format 'yyyy-MM-dd').md"
    if (Test-Path $taskFile) {
        $timestamp = Get-Date -Format "HH:mm"
        Add-Content -Path $taskFile -Value "- [$timestamp] $Task"
        Write-Host "Added task: $Task"
    } else {
        Write-Host "No task file found for today. Run Start-MCPWorkflow first."
    }
}

function Show-MCPHelp {
    Write-Host @"
MCP Workflow Quick Access Functions:

Core Functions:
  Start-MCPWorkflow [Type] [-StartCursor]  - Start daily workflow
  Get-MCPStatus                           - Check server status
  Update-MCPServers                       - Update MCP servers
  Backup-MCPWorkflow                      - Create backup

Quick Workflows:
  Start-DevWorkflow                       - Development workflow + Cursor
  Start-ResearchWorkflow                  - Research workflow + Cursor
  Start-ContentWorkflow                   - Content creation + Cursor
  Start-AutomationWorkflow                - Automation workflow + Cursor
  Start-ProjectWorkflow                   - Project management + Cursor

Utilities:
  Open-MCPWorkspace [Type]                - Open workspace in Cursor
  Show-MCPTasks                          - Show today's tasks
  Add-MCPTask "Task description"         - Add a task to today's list
  Show-MCPHelp                           - Show this help

Available MCP Servers:
  filesystem, memory, github, web-search, fetch, sqlite,
  puppeteer, sequential-thinking, everything

Workflow Types:
  development, research, contentCreation, automation, projectManagement
"@
}

# Auto-run help on first load
Write-Host "MCP Workflow Quick Access Functions loaded!"
Write-Host "Run Show-MCPHelp for available commands"
Write-Host "Run Start-DevWorkflow to begin development workflow"
