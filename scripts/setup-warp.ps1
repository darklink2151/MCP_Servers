# Warp MCP Setup Script
# Configures Warp to use the unified MCP configuration

param(
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$WarpConfigDir = "$env:APPDATA\Warp"
$MCPConfigDir = "C:\Users\beckd\MCP_Servers"
$ConfigFile = "$MCPConfigDir\warp-mcp-config.toml"

Write-Host "Setting up Warp with unified MCP configuration..." -ForegroundColor Cyan

# Ensure Warp config directory exists
if (!(Test-Path $WarpConfigDir)) {
    New-Item -Path $WarpConfigDir -ItemType Directory -Force | Out-Null
    Write-Host "Created Warp config directory: $WarpConfigDir" -ForegroundColor Green
}

# Copy MCP configuration to Warp
if (Test-Path $ConfigFile) {
    $WarpMCPConfig = "$WarpConfigDir\mcp-config.toml"

    if ((Test-Path $WarpMCPConfig) -and (-not $Force)) {
        Write-Host "Warp MCP config already exists. Use -Force to overwrite." -ForegroundColor Yellow
    } else {
        Copy-Item -Path $ConfigFile -Destination $WarpMCPConfig -Force
        Write-Host "Copied MCP configuration to Warp" -ForegroundColor Green
    }
} else {
    Write-Error "MCP configuration file not found: $ConfigFile"
    exit 1
}

# Create Warp settings if they don't exist
$WarpSettingsFile = "$WarpConfigDir\settings.toml"
if (!(Test-Path $WarpSettingsFile)) {
    $DefaultSettings = @"
# Warp Settings
[mcp]
enabled = true
auto_start = true
log_level = "info"
config_path = "$WarpMCPConfig"

[mcp.servers]
# Servers will be loaded from the MCP config file
"@

    $DefaultSettings | Out-File -FilePath $WarpSettingsFile -Encoding UTF8
    Write-Host "Created Warp settings file" -ForegroundColor Green
}

Write-Host "Warp MCP setup completed successfully!" -ForegroundColor Green
Write-Host "Configuration file: $WarpMCPConfig" -ForegroundColor Gray
Write-Host "Restart Warp to apply changes." -ForegroundColor Yellow
