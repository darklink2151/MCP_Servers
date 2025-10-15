# Cursor MCP Setup Script
# Configures Cursor to use the unified MCP configuration

param(
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$CursorConfigDir = "$env:APPDATA\Cursor\User"
$MCPConfigDir = "C:\Users\beckd\MCP_Servers"
$ConfigFile = "$MCPConfigDir\cursor-mcp-config.json"

Write-Host "Setting up Cursor with unified MCP configuration..." -ForegroundColor Cyan

# Ensure Cursor config directory exists
if (!(Test-Path $CursorConfigDir)) {
    New-Item -Path $CursorConfigDir -ItemType Directory -Force | Out-Null
    Write-Host "Created Cursor config directory: $CursorConfigDir" -ForegroundColor Green
}

# Copy MCP configuration to Cursor
if (Test-Path $ConfigFile) {
    $CursorMCPConfig = "$CursorConfigDir\mcp-config.json"

    if ((Test-Path $CursorMCPConfig) -and (-not $Force)) {
        Write-Host "Cursor MCP config already exists. Use -Force to overwrite." -ForegroundColor Yellow
    } else {
        Copy-Item -Path $ConfigFile -Destination $CursorMCPConfig -Force
        Write-Host "Copied MCP configuration to Cursor" -ForegroundColor Green
    }
} else {
    Write-Error "MCP configuration file not found: $ConfigFile"
    exit 1
}

# Create Cursor settings if they don't exist
$CursorSettingsFile = "$CursorConfigDir\settings.json"
if (!(Test-Path $CursorSettingsFile)) {
    $DefaultSettings = @{
        "mcp.servers" = @{}
        "mcp.enabled" = $true
        "mcp.autoStart" = $true
        "mcp.logLevel" = "info"
        "mcp.configPath" = $CursorMCPConfig
    } | ConvertTo-Json -Depth 3

    $DefaultSettings | Out-File -FilePath $CursorSettingsFile -Encoding UTF8
    Write-Host "Created Cursor settings file" -ForegroundColor Green
}

Write-Host "Cursor MCP setup completed successfully!" -ForegroundColor Green
Write-Host "Configuration file: $CursorMCPConfig" -ForegroundColor Gray
Write-Host "Restart Cursor to apply changes." -ForegroundColor Yellow
