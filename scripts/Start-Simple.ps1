#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Simple, reliable MCP server startup
.DESCRIPTION
    Uses direct node execution to avoid PowerShell npx issues
#>

param(
    [Parameter(Position=0)]
    [string]$WorkflowName = "development",
    
    [Parameter(Position=1)]
    [string]$ConfigPath = "configs\master-config.json"
)

function Write-Log {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Start-MCPServer {
    param (
        [string]$ServerName,
        [object]$ServerConfig
    )
    
    Write-Log "  Starting server: $ServerName..." -Color "White"
    
    try {
        # Get the server package name from args
        $packageName = $ServerConfig.args | Where-Object { $_ -like "@modelcontextprotocol/*" -or $_ -like "*puppeteer*" } | Select-Object -First 1
        
        if (-not $packageName) {
            Write-Log "  ✗ No package found for server $ServerName" -Color "Red"
            return $false
        }
        
        # Extract server-specific arguments (everything after the package name)
        $serverArgs = @()
        $foundPackage = $false
        foreach ($arg in $ServerConfig.args) {
            if ($foundPackage) {
                $serverArgs += $arg
            } elseif ($arg -eq $packageName) {
                $foundPackage = $true
            }
        }
        
        # Use node directly with npx module
        $nodeArgs = @("--input-type=module", "-e", "import('child_process').then(cp => cp.spawn('npx', ['$packageName'] + process.argv.slice(1), {stdio: 'inherit'}).unref())")
        $nodeArgs += $serverArgs
        
        # Start the process
        $process = Start-Process -FilePath "node" -ArgumentList $nodeArgs -NoNewWindow -PassThru -ErrorAction Stop
        
        Write-Log "  ✓ Started server '$ServerName' (PID: $($process.Id))" -Color "Green"
        return $true
        
    } catch {
        Write-Log "  ✗ Failed to start $ServerName`: $($_.Exception.Message)" -Color "Red"
        return $false
    }
}

# Load configuration
if (-not (Test-Path $ConfigPath)) {
    Write-Log "❌ Configuration file not found: $ConfigPath" -Color "Red"
    exit 1
}

try {
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    Write-Log "✅ Loaded configuration from $ConfigPath" -Color "Green"
} catch {
    Write-Log "❌ Failed to parse configuration: $($_.Exception.Message)" -Color "Red"
    exit 1
}

# Check if workflow exists
if (-not $config.mcp.workflows.$WorkflowName) {
    Write-Log "❌ Workflow '$WorkflowName' not found in configuration!" -Color "Red"
    exit 1
}

$workflow = $config.mcp.workflows.$WorkflowName
$servers = $workflow.servers

Write-Log "🚀 Starting workflow: $($workflow.name) ($WorkflowName)" -Color "Cyan"
Write-Log "  Servers to start: $($servers -join ', ')" -Color "Gray"

# Start servers
$startedCount = 0
foreach ($serverName in $servers) {
    $serverConfig = $config.mcp.servers.$serverName
    
    if (-not $serverConfig) {
        Write-Log "  ⚠️ Server '$serverName' not found in configuration" -Color "Yellow"
        continue
    }
    
    $result = Start-MCPServer -ServerName $serverName -ServerConfig $serverConfig
    if ($result) {
        $startedCount++
    }
    
    # Small delay between starts
    Start-Sleep -Milliseconds 500
}

# Summary
Write-Log "`n✅ Started $startedCount out of $($servers.Count) servers for workflow '$WorkflowName'" -Color "Green"

if ($startedCount -gt 0) {
    Write-Log "🎉 Workflow '$WorkflowName' started successfully!" -Color "Cyan"
    exit 0
} else {
    Write-Log "❌ Failed to start workflow '$WorkflowName'" -Color "Red"
    exit 1
}
