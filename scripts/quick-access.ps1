#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates desktop shortcuts for quick MCP access
.DESCRIPTION
    Generates desktop shortcuts for the most common MCP operations
#>

$desktopPath = [Environment]::GetFolderPath("Desktop")
$rootDir = Split-Path $PSScriptRoot -Parent
$shortcuts = @(
    @{
        Name = "MCP-Start"
        Target = "pwsh.exe" 
        Arguments = "-ExecutionPolicy Bypass -File `"$rootDir\START-DAILY.ps1`""
        Icon = "%SystemRoot%\System32\shell32.dll,27"
        Description = "Start MCP daily workflow"
    },
    @{
        Name = "MCP-Dashboard" 
        Target = "pwsh.exe"
        Arguments = "-ExecutionPolicy Bypass -File `"$rootDir\scripts\MCP-Dashboard.ps1`""
        Icon = "%SystemRoot%\System32\shell32.dll,55"
        Description = "Open MCP Dashboard"
    },
    @{
        Name = "MCP-Stop-All"
        Target = "pwsh.exe"
        Arguments = "-ExecutionPolicy Bypass -File `"$rootDir\scripts\Stop-AllMCP.ps1`""
        Icon = "%SystemRoot%\System32\shell32.dll,27"
        Description = "Stop all MCP servers"
    }
)

Write-Host "Creating desktop shortcuts for quick access..." -ForegroundColor Cyan
Write-Host ""

$wshShell = New-Object -ComObject WScript.Shell

foreach ($shortcut in $shortcuts) {
    $shortcutPath = Join-Path $desktopPath "$($shortcut.Name).lnk"
    $shortcutObj = $wshShell.CreateShortcut($shortcutPath)
    $shortcutObj.TargetPath = $shortcut.Target
    $shortcutObj.Arguments = $shortcut.Arguments
    $shortcutObj.WorkingDirectory = $rootDir
    $shortcutObj.IconLocation = $shortcut.Icon
    $shortcutObj.Description = $shortcut.Description
    $shortcutObj.Save()
    
    Write-Host "✅ Created: $($shortcut.Name)" -ForegroundColor Green
    Write-Host "   $($shortcut.Description)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "🚀 Shortcuts created successfully!" -ForegroundColor Cyan
Write-Host "You can now access MCP functions directly from your desktop." -ForegroundColor White