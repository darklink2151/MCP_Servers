# MCP Server Management Script
# Unified management for all MCP servers across Cursor and Warp

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("start", "stop", "restart", "status", "install", "update", "cleanup", "backup", "restore")]
    [string]$Action = "status",

    [Parameter(Mandatory=$false)]
    [string]$Server = "all",

    [Parameter(Mandatory=$false)]
    [string]$Workflow = "development",

    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Configuration
$ConfigDir = "C:\Users\beckd\MCP_Servers"
$LogDir = "$ConfigDir\logs"
$DataDir = "$ConfigDir\data"
$BackupDir = "$ConfigDir\backups"
$ConfigFile = "$ConfigDir\unified-mcp-config.json"

# Ensure directories exist
@($LogDir, $DataDir, $BackupDir) | ForEach-Object {
    if (!(Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
        Write-Host "Created directory: $_" -ForegroundColor Green
    }
}

# Load configuration
function Get-MCPConfig {
    if (Test-Path $ConfigFile) {
        return Get-Content $ConfigFile | ConvertFrom-Json
    } else {
        Write-Error "Configuration file not found: $ConfigFile"
        exit 1
    }
}

# Logging function
function Write-MCPLog {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    $LogFile = "$LogDir\mcp-manager.log"

    Write-Host $LogMessage
    Add-Content -Path $LogFile -Value $LogMessage
}

# Server management functions
function Start-MCPServer {
    param([string]$ServerName, [object]$Config)

    Write-MCPLog "Starting MCP server: $ServerName"

    $ServerConfig = $Config.servers.$ServerName
    if (!$ServerConfig) {
        Write-MCPLog "Server configuration not found: $ServerName" "ERROR"
        return $false
    }

    if (!$ServerConfig.enabled) {
        Write-MCPLog "Server is disabled: $ServerName" "WARN"
        return $false
    }

    # Start server process
    $ProcessArgs = @{
        FilePath = $ServerConfig.command
        ArgumentList = $ServerConfig.args
        NoNewWindow = $true
        PassThru = $true
    }

    if ($ServerConfig.env) {
        $ProcessArgs.Environment = $ServerConfig.env
    }

    try {
        $Process = Start-Process @ProcessArgs
        Write-MCPLog "Started $ServerName with PID: $($Process.Id)" "SUCCESS"
        return $true
    } catch {
        Write-MCPLog "Failed to start $ServerName`: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Stop-MCPServer {
    param([string]$ServerName)

    Write-MCPLog "Stopping MCP server: $ServerName"

    $Processes = Get-Process | Where-Object {
        $_.ProcessName -like "*npx*" -and
        $_.CommandLine -like "*$ServerName*"
    }

    if ($Processes) {
        $Processes | ForEach-Object {
            Stop-Process -Id $_.Id -Force
            Write-MCPLog "Stopped process: $($_.Id)" "SUCCESS"
        }
    } else {
        Write-MCPLog "No running processes found for: $ServerName" "WARN"
    }
}

function Get-MCPServerStatus {
    param([string]$ServerName = "all")

    Write-MCPLog "Checking MCP server status"

    $Processes = Get-Process | Where-Object {
        $_.ProcessName -like "*npx*" -and
        $_.CommandLine -like "*modelcontextprotocol*"
    }

    if ($Processes) {
        $Processes | ForEach-Object {
            Write-Host "Running: $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Green
        }
    } else {
        Write-Host "No MCP servers currently running" -ForegroundColor Yellow
    }
}

# Workflow management
function Start-MCPWorkflow {
    param([string]$WorkflowName, [object]$Config)

    $WorkflowConfig = $Config.workflows.$WorkflowName
    if (!$WorkflowConfig) {
        Write-MCPLog "Workflow not found: $WorkflowName" "ERROR"
        return $false
    }

    Write-MCPLog "Starting workflow: $WorkflowName"
    Write-Host "Workflow: $($WorkflowConfig.name)" -ForegroundColor Cyan
    Write-Host "Description: $($WorkflowConfig.description)" -ForegroundColor Gray

    $SuccessCount = 0
    $TotalServers = $WorkflowConfig.servers.Count

    foreach ($ServerName in $WorkflowConfig.servers) {
        if (Start-MCPServer -ServerName $ServerName -Config $Config) {
            $SuccessCount++
        }
        Start-Sleep -Seconds 1
    }

    Write-Host "Started $SuccessCount of $TotalServers servers" -ForegroundColor $(if($SuccessCount -eq $TotalServers) {"Green"} else {"Yellow"})
}

# Cleanup function
function Remove-OldMCPConfigs {
    Write-MCPLog "Cleaning up old MCP configurations"

    $OldPaths = @(
        "C:\MCP_Servers",
        "C:\Users\beckd\Documents\Projects\MCP-Workflow",
        "C:\Users\beckd\.docker\modules\mcp"
    )

    foreach ($Path in $OldPaths) {
        if (Test-Path $Path -and $Path -ne $ConfigDir) {
            Write-Host "Found old MCP directory: $Path" -ForegroundColor Yellow
            if ($Force) {
                Remove-Item -Path $Path -Recurse -Force
                Write-MCPLog "Removed old directory: $Path" "SUCCESS"
            } else {
                Write-Host "Use -Force to remove: $Path" -ForegroundColor Yellow
            }
        }
    }
}

# Backup function
function Backup-MCPConfig {
    Write-MCPLog "Creating MCP configuration backup"

    $BackupName = "mcp-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $BackupPath = "$BackupDir\$BackupName"

    New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null

    # Backup configs
    Copy-Item -Path "$ConfigDir\configs\*" -Destination "$BackupPath\configs\" -Recurse -Force
    Copy-Item -Path "$ConfigDir\*.json" -Destination $BackupPath -Force
    Copy-Item -Path "$ConfigDir\*.toml" -Destination $BackupPath -Force

    # Backup data
    if (Test-Path "$ConfigDir\databases") {
        Copy-Item -Path "$ConfigDir\databases\*" -Destination "$BackupPath\databases\" -Recurse -Force
    }

    Write-MCPLog "Backup created: $BackupPath" "SUCCESS"
    Write-Host "Backup location: $BackupPath" -ForegroundColor Green
}

# Main execution
try {
    Write-MCPLog "MCP Manager started - Action: $Action, Server: $Server, Workflow: $Workflow"

    $Config = Get-MCPConfig

    switch ($Action) {
        "start" {
            if ($Server -eq "all") {
                Start-MCPWorkflow -WorkflowName $Workflow -Config $Config
            } else {
                Start-MCPServer -ServerName $Server -Config $Config
            }
        }
        "stop" {
            if ($Server -eq "all") {
                Get-Process | Where-Object { $_.ProcessName -like "*npx*" -and $_.CommandLine -like "*modelcontextprotocol*" } | Stop-Process -Force
                Write-MCPLog "Stopped all MCP servers" "SUCCESS"
            } else {
                Stop-MCPServer -ServerName $Server
            }
        }
        "restart" {
            if ($Server -eq "all") {
                Get-Process | Where-Object { $_.ProcessName -like "*npx*" -and $_.CommandLine -like "*modelcontextprotocol*" } | Stop-Process -Force
                Start-Sleep -Seconds 2
                Start-MCPWorkflow -WorkflowName $Workflow -Config $Config
            } else {
                Stop-MCPServer -ServerName $Server
                Start-Sleep -Seconds 2
                Start-MCPServer -ServerName $Server -Config $Config
            }
        }
        "status" {
            Get-MCPServerStatus -ServerName $Server
        }
        "install" {
            Write-MCPLog "Installing MCP servers..."
            npm install -g @modelcontextprotocol/server-filesystem
            npm install -g @modelcontextprotocol/server-memory
            npm install -g @modelcontextprotocol/server-sequential-thinking
            npm install -g @modelcontextprotocol/server-everything
            npm install -g @todoforai/puppeteer-mcp-server
            Write-MCPLog "MCP servers installation completed" "SUCCESS"
        }
        "update" {
            Write-MCPLog "Updating MCP servers..."
            npm update -g @modelcontextprotocol/server-filesystem
            npm update -g @modelcontextprotocol/server-memory
            npm update -g @modelcontextprotocol/server-sequential-thinking
            npm update -g @modelcontextprotocol/server-everything
            npm update -g @todoforai/puppeteer-mcp-server
            Write-MCPLog "MCP servers update completed" "SUCCESS"
        }
        "cleanup" {
            Remove-OldMCPConfigs
        }
        "backup" {
            Backup-MCPConfig
        }
    }

    Write-MCPLog "MCP Manager completed successfully" "SUCCESS"

} catch {
    Write-MCPLog "Error: $($_.Exception.Message)" "ERROR"
    exit 1
}
