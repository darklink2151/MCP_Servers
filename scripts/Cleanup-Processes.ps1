#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Advanced MCP process cleanup utility
.DESCRIPTION
    Thoroughly cleans up all MCP-related processes with detailed reporting
#>

param(
    [Parameter(Position=0)]
    [switch]$Force,
    
    [Parameter(Position=1)]
    [switch]$Silent
)

function Write-CleanupLog {
    param (
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewLine
    )
    
    if (-not $Silent) {
        if ($NoNewLine) {
            Write-Host $Message -ForegroundColor $Color -NoNewline
        } else {
            Write-Host $Message -ForegroundColor $Color
        }
    }
}

function Get-MCPProcesses {
    # Get all node processes
    $allNodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
    
    # Filter for MCP-related processes
    $mcpProcesses = $allNodeProcesses | Where-Object {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
        $cmdLine -like "*@modelcontextprotocol*" -or 
        $cmdLine -like "*puppeteer-mcp*" -or 
        $cmdLine -like "*mcp-server*" -or
        $cmdLine -like "*mcp-cli*"
    }
    
    return $mcpProcesses
}

function Get-OrphanedProcesses {
    # Get all node processes
    $allNodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
    
    # Filter for potentially orphaned processes
    $orphanedProcesses = $allNodeProcesses | Where-Object {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
        ($cmdLine -like "*npx*" -or $cmdLine -like "*server*") -and
        ($cmdLine -notlike "*@modelcontextprotocol*" -and $cmdLine -notlike "*puppeteer-mcp*" -and $cmdLine -notlike "*mcp-server*")
    }
    
    return $orphanedProcesses
}

function Stop-ProcessSafely {
    param (
        [Parameter(Mandatory=$true)]
        [System.Diagnostics.Process]$Process,
        
        [switch]$ForceKill
    )
    
    try {
        if ($ForceKill) {
            Stop-Process -Id $Process.Id -Force -ErrorAction Stop
            Write-CleanupLog "  ✓ Force killed process PID: $($Process.Id)" -Color "Green"
            return $true
        } else {
            # Try graceful termination first
            $Process.CloseMainWindow() | Out-Null
            if (-not $Process.HasExited) {
                $Process.WaitForExit(2000) | Out-Null
            }
            
            # If still running, force kill
            if (-not $Process.HasExited) {
                Stop-Process -Id $Process.Id -Force -ErrorAction Stop
                Write-CleanupLog "  ✓ Process did not exit gracefully, force killed PID: $($Process.Id)" -Color "Yellow"
            } else {
                Write-CleanupLog "  ✓ Process exited gracefully PID: $($Process.Id)" -Color "Green"
            }
            return $true
        }
    } catch {
        Write-CleanupLog "  ✗ Failed to stop process PID: $($Process.Id) - $($_.Exception.Message)" -Color "Red"
        return $false
    }
}

# Main cleanup process
Write-CleanupLog "🧹 Starting advanced MCP process cleanup..." -Color "Cyan"

# Step 1: Identify and stop MCP processes
Write-CleanupLog "`n[1/4] Identifying MCP processes..." -Color "Yellow"
$mcpProcesses = Get-MCPProcesses

if ($mcpProcesses) {
    Write-CleanupLog "  Found $($mcpProcesses.Count) MCP processes" -Color "White"
    
    foreach ($proc in $mcpProcesses) {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction SilentlyContinue).CommandLine
        $shortCmd = if ($cmdLine.Length -gt 80) { "$($cmdLine.Substring(0, 80))..." } else { $cmdLine }
        Write-CleanupLog "  PID: $($proc.Id) - $shortCmd" -Color "Gray"
        
        Stop-ProcessSafely -Process $proc -ForceKill:$Force
    }
} else {
    Write-CleanupLog "  ✓ No MCP processes found" -Color "Green"
}

# Step 2: Check for orphaned processes
Write-CleanupLog "`n[2/4] Checking for orphaned node processes..." -Color "Yellow"
$orphanedProcesses = Get-OrphanedProcesses

if ($orphanedProcesses) {
    Write-CleanupLog "  Found $($orphanedProcesses.Count) potentially orphaned processes" -Color "Yellow"
    
    foreach ($proc in $orphanedProcesses) {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction SilentlyContinue).CommandLine
        $shortCmd = if ($cmdLine.Length -gt 80) { "$($cmdLine.Substring(0, 80))..." } else { $cmdLine }
        Write-CleanupLog "  PID: $($proc.Id) - $shortCmd" -Color "Gray"
        
        if ($Force) {
            Stop-ProcessSafely -Process $proc -ForceKill
        } else {
            Write-CleanupLog "  ⚠️ Skipping orphaned process (use -Force to kill)" -Color "Yellow"
        }
    }
} else {
    Write-CleanupLog "  ✓ No orphaned processes found" -Color "Green"
}

# Step 3: Clean temporary files
Write-CleanupLog "`n[3/4] Cleaning temporary files..." -Color "Yellow"

$tempDirs = @(
    "data\temp",
    "logs\temp",
    "$env:TEMP\mcp-*"
)

foreach ($dir in $tempDirs) {
    if (Test-Path $dir) {
        try {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction Stop
            Write-CleanupLog "  ✓ Removed: $dir" -Color "Green"
        } catch {
            Write-CleanupLog "  ✗ Failed to remove: $dir - $($_.Exception.Message)" -Color "Red"
        }
    }
}

# Step 4: Verify cleanup
Write-CleanupLog "`n[4/4] Verifying cleanup..." -Color "Yellow"

# Wait a moment for processes to fully terminate
Start-Sleep -Seconds 2

# Check if any MCP processes remain
$remainingProcesses = Get-MCPProcesses

if ($remainingProcesses) {
    Write-CleanupLog "  ⚠️ $($remainingProcesses.Count) MCP processes still running!" -Color "Red"
    
    foreach ($proc in $remainingProcesses) {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction SilentlyContinue).CommandLine
        $shortCmd = if ($cmdLine.Length -gt 80) { "$($cmdLine.Substring(0, 80))..." } else { $cmdLine }
        Write-CleanupLog "  PID: $($proc.Id) - $shortCmd" -Color "Gray"
        
        if ($Force) {
            try {
                # Last resort: taskkill
                $result = Start-Process "taskkill" -ArgumentList "/F /PID $($proc.Id)" -NoNewWindow -Wait -PassThru
                if ($result.ExitCode -eq 0) {
                    Write-CleanupLog "  ✓ Force killed with taskkill: PID $($proc.Id)" -Color "Green"
                } else {
                    Write-CleanupLog "  ✗ Failed to kill with taskkill: PID $($proc.Id)" -Color "Red"
                }
            } catch {
                Write-CleanupLog "  ✗ Failed to execute taskkill: $($_.Exception.Message)" -Color "Red"
            }
        }
    }
    
    # Final check
    $finalCheck = Get-MCPProcesses
    if ($finalCheck) {
        Write-CleanupLog "`n⚠️ WARNING: $($finalCheck.Count) MCP processes could not be terminated!" -Color "Red"
        Write-CleanupLog "  Consider restarting your computer if issues persist." -Color "Yellow"
    }
} else {
    Write-CleanupLog "  ✅ All MCP processes successfully terminated!" -Color "Green"
}

# Summary
Write-CleanupLog "`n✅ Cleanup process complete!" -Color "Cyan"

# Return success/failure for scripting
if ((Get-MCPProcesses).Count -eq 0) {
    return $true
} else {
    return $false
}