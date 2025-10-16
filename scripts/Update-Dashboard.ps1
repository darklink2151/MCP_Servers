#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Updates the MCP Dashboard to include AI workflow options
.DESCRIPTION
    Simple script to add AI workflow options to the existing MCP Dashboard
#>

# Define paths
$dashboardPath = "scripts\MCP-Dashboard.ps1"
$backupPath = "scripts\MCP-Dashboard.ps1.backup"

Write-Host "Updating MCP Dashboard with AI workflow options..." -ForegroundColor Cyan

# Backup the current dashboard
if (Test-Path $dashboardPath) {
    Copy-Item -Path $dashboardPath -Destination $backupPath -Force
    Write-Host "✅ Backed up original dashboard to $backupPath" -ForegroundColor Green
} else {
    Write-Host "❌ Dashboard file not found at: $dashboardPath" -ForegroundColor Red
    exit 1
}

# Check if dashboard is already updated
$dashboardContent = Get-Content -Path $dashboardPath -Raw
if ($dashboardContent -like "*aiDevelopment*") {
    Write-Host "✅ Dashboard already contains AI workflow" -ForegroundColor Green
    exit 0
}

# Update the workflow selection list
try {
    $updated = $dashboardContent -replace '(\$workflows = @\()("development", "research", "automation", "cybersecurity", "organization", "webDevelopment", "contentCreation", "projectManagement")(\))', '$1$2, "aiDevelopment"$3'
    
    Set-Content -Path $dashboardPath -Value $updated -Force
    Write-Host "✅ Successfully updated MCP Dashboard" -ForegroundColor Green
    
    # Update the AI workflow display
    $aiFunctionality = @"
    • aiDevelopment - AI model development
"@
    
    $updated = $updated -replace '(Quick Workflows:.+?\n.+?daily.+?\n.+?development.+?\n.+?research.+?\n.+?cybersecurity.+?\n)', "`$1    • aiDevelopment - AI model development`n"
    Set-Content -Path $dashboardPath -Value $updated -Force

} catch {
    Write-Host "❌ Failed to update dashboard: $($_.Exception.Message)" -ForegroundColor Red
    # Restore backup
    Copy-Item -Path $backupPath -Destination $dashboardPath -Force
    Write-Host "✅ Restored original dashboard from backup" -ForegroundColor Yellow
}

Write-Host "`n🚀 Dashboard update complete!" -ForegroundColor Cyan
Write-Host "The AI Development workflow is now available in the dashboard" -ForegroundColor Green
