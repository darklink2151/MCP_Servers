# Daily Workflow Script for MCP Integration
# This script sets up your daily environment for optimal MCP workflow usage

param(
    [string]$WorkflowType = "development",
    [switch]$StartCursor = $false,
    [switch]$UpdateServers = $false,
    [switch]$Backup = $false,
    [switch]$Status = $false
)

# Set up environment
$WorkflowRoot = "C:\Users\beckd\MCP-Workflow"
$LogFile = "$WorkflowRoot\logs\daily-workflow.log"

# Ensure log directory exists
if (!(Test-Path "$WorkflowRoot\logs")) {
    New-Item -ItemType Directory -Path "$WorkflowRoot\logs" -Force
}

# Function to write to log
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $LogFile -Value $logMessage
}

Write-Log "=== Starting Daily MCP Workflow Setup ==="

# Check if MCP Workflow directory exists
if (!(Test-Path $WorkflowRoot)) {
    Write-Log "ERROR: MCP Workflow directory not found at $WorkflowRoot"
    exit 1
}

# Update servers if requested
if ($UpdateServers) {
    Write-Log "Updating MCP servers..."
    Set-Location $WorkflowRoot
    node scripts/install-mcp-servers-fixed.js
    if ($LASTEXITCODE -eq 0) {
        Write-Log "MCP servers updated successfully"
    } else {
        Write-Log "ERROR: Failed to update MCP servers"
    }
}

# Create backup if requested
if ($Backup) {
    Write-Log "Creating backup..."
    Set-Location $WorkflowRoot
    node scripts/mcp-cli.js backup
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Backup created successfully"
    } else {
        Write-Log "ERROR: Failed to create backup"
    }
}

# Check status if requested
if ($Status) {
    Write-Log "Checking MCP server status..."
    Set-Location $WorkflowRoot
    node scripts/mcp-cli.js status
}

# Set up daily environment variables
Write-Log "Setting up daily environment..."

# Add MCP Workflow to PATH temporarily
$env:PATH += ";$WorkflowRoot\scripts"

# Set MCP-specific environment variables
$env:MCP_WORKFLOW_ROOT = $WorkflowRoot
$env:MCP_DAILY_MODE = "true"
$env:MCP_WORKFLOW_TYPE = $WorkflowType

# Create daily workspace
$DailyWorkspace = "$WorkflowRoot\workspaces\daily-$(Get-Date -Format 'yyyy-MM-dd')"
if (!(Test-Path $DailyWorkspace)) {
    New-Item -ItemType Directory -Path $DailyWorkspace -Force
    Write-Log "Created daily workspace: $DailyWorkspace"
}

# Set up daily database
$DailyDB = "$DailyWorkspace\daily-activities.db"
if (!(Test-Path $DailyDB)) {
    Write-Log "Initializing daily database..."
    # This would be handled by the SQLite MCP server
}

# Start Cursor with MCP if requested
if ($StartCursor) {
    Write-Log "Starting Cursor with MCP integration..."

    # Check if Cursor is already running
    $cursorProcess = Get-Process -Name "Cursor" -ErrorAction SilentlyContinue
    if ($cursorProcess) {
        Write-Log "Cursor is already running"
    } else {
        # Start Cursor
        Start-Process "Cursor" -ArgumentList $DailyWorkspace
        Write-Log "Cursor started with workspace: $DailyWorkspace"
    }
}

# Create daily task list
$TaskListFile = "$DailyWorkspace\tasks-$(Get-Date -Format 'yyyy-MM-dd').md"
if (!(Test-Path $TaskListFile)) {
    $TaskListContent = @"
# Daily Tasks - $(Get-Date -Format 'yyyy-MM-dd')

## Workflow Type: $WorkflowType

### Priority Tasks
- [ ]

### Development Tasks
- [ ]

### Research Tasks
- [ ]

### Content Creation
- [ ]

### Automation Tasks
- [ ]

### Notes
-

## End of Day Summary
- Completed:
- Blocked by:
- Tomorrow's focus:

"@
    Set-Content -Path $TaskListFile -Value $TaskListContent
    Write-Log "Created daily task list: $TaskListFile"
}

# Set up quick access shortcuts
Write-Log "Setting up quick access shortcuts..."

# Create PowerShell profile addition
$ProfileAddition = @"
# MCP Workflow Quick Access Functions
function Start-MCPWorkflow { param([string]`$Type = 'development') & '$WorkflowRoot\scripts\daily-workflow.ps1' -WorkflowType `$Type -StartCursor }
function Get-MCPStatus { & '$WorkflowRoot\scripts\mcp-cli.js' status }
function Update-MCPServers { & '$WorkflowRoot\scripts\mcp-cli.js' init }
function Backup-MCPWorkflow { & '$WorkflowRoot\scripts\mcp-cli.js' backup }

# Quick workflow starters
function Start-DevWorkflow { Start-MCPWorkflow 'development' }
function Start-ResearchWorkflow { Start-MCPWorkflow 'research' }
function Start-ContentWorkflow { Start-MCPWorkflow 'contentCreation' }
function Start-AutomationWorkflow { Start-MCPWorkflow 'automation' }
function Start-ProjectWorkflow { Start-MCPWorkflow 'projectManagement' }

Write-Host "MCP Workflow functions loaded. Use Start-MCPWorkflow, Get-MCPStatus, Update-MCPServers, Backup-MCPWorkflow"
"@

$ProfilePath = $PROFILE.CurrentUserAllHosts
if (!(Test-Path (Split-Path $ProfilePath -Parent))) {
    New-Item -ItemType Directory -Path (Split-Path $ProfilePath -Parent) -Force
}

# Add to profile if not already there
if (!(Get-Content $ProfilePath -ErrorAction SilentlyContinue | Select-String "MCP Workflow Quick Access Functions")) {
    Add-Content -Path $ProfilePath -Value $ProfileAddition
    Write-Log "Added MCP functions to PowerShell profile"
}

Write-Log "=== Daily MCP Workflow Setup Complete ==="
Write-Log "Workflow Type: $WorkflowType"
Write-Log "Daily Workspace: $DailyWorkspace"
Write-Log "Task List: $TaskListFile"

if ($StartCursor) {
    Write-Log "Cursor should be starting with MCP integration..."
    Write-Log "You can now use all MCP servers for enhanced AI capabilities!"
} else {
    Write-Log "To start Cursor with MCP integration, run: Start-MCPWorkflow -StartCursor"
}

Write-Log "Available MCP servers: filesystem, memory, github, web-search, fetch, sqlite, puppeteer, sequential-thinking, everything"
