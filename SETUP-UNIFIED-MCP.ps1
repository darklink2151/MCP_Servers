# Unified MCP Setup Script
# Complete setup for centralized MCP configuration

param(
    [Parameter(Mandatory=$false)]
    [switch]$Force,

    [Parameter(Mandatory=$false)]
    [switch]$SkipCleanup
)

Write-Host "=== Unified MCP Server Setup ===" -ForegroundColor Cyan
Write-Host "Setting up centralized MCP configuration for Cursor and Warp..." -ForegroundColor Gray

$ErrorActionPreference = "Stop"
$ConfigDir = "C:\Users\beckd\MCP_Servers"

# Ensure we're in the right directory
if (!(Test-Path "cursor-mcp-config.json")) {
    Write-Error "Please run this script from the MCP_Servers directory"
    exit 1
}

try {
    # Step 1: Install MCP servers
    Write-Host "`n1. Installing MCP servers..." -ForegroundColor Yellow
    .\scripts\mcp-manager.ps1 -Action install

    # Step 2: Setup Cursor
    Write-Host "`n2. Setting up Cursor..." -ForegroundColor Yellow
    .\scripts\setup-cursor.ps1 -Force:$Force

    # Step 3: Setup Warp
    Write-Host "`n3. Setting up Warp..." -ForegroundColor Yellow
    .\scripts\setup-warp.ps1 -Force:$Force

    # Step 4: Create initial backup
    Write-Host "`n4. Creating initial backup..." -ForegroundColor Yellow
    .\scripts\mcp-manager.ps1 -Action backup

    # Step 5: Cleanup old configurations (optional)
    if (!$SkipCleanup) {
        Write-Host "`n5. Cleaning up old configurations..." -ForegroundColor Yellow
        .\scripts\mcp-manager.ps1 -Action cleanup -Force:$Force
    }

    # Step 6: Test configuration
    Write-Host "`n6. Testing configuration..." -ForegroundColor Yellow
    .\scripts\mcp-manager.ps1 -Action status

    Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
    Write-Host "Your unified MCP configuration is ready!" -ForegroundColor Green
    Write-Host "`nConfiguration location: $ConfigDir" -ForegroundColor Gray
    Write-Host "Documentation: $ConfigDir\docs\UNIFIED-MCP-SETUP.md" -ForegroundColor Gray
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Restart Cursor and Warp to apply configurations" -ForegroundColor White
    Write-Host "2. Run: .\scripts\mcp-manager.ps1 -Action start -Workflow development" -ForegroundColor White
    Write-Host "3. Check status: .\scripts\mcp-manager.ps1 -Action status" -ForegroundColor White

} catch {
    Write-Error "Setup failed: $($_.Exception.Message)"
    Write-Host "Check the logs in $ConfigDir\logs\ for more details" -ForegroundColor Yellow
    exit 1
}
