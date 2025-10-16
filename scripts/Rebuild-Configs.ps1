#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Rebuilds and deploys the entire MCP server configuration.
.DESCRIPTION
    This script programmatically generates all necessary MCP server JSON configuration
    files, ensuring they are standardized, secure, and ready for use. It sources
    API keys from environment variables and creates a perfectly structured setup.
.NOTES
    Version: 1.0.0
    Author: DirtyWork AI
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ConfigDir = "C:\Users\beckd\MCP_Servers\configs",

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# --- Helper Functions ---
function Write-SectionHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Write-ConfigFile {
    param(
        [string]$FileName,
        [object]$ConfigObject
    )
    $filePath = Join-Path $ConfigDir $FileName
    $jsonContent = $ConfigObject | ConvertTo-Json -Depth 10

    try {
        Write-Host "  ⏳ Generating config for '$FileName'..." -ForegroundColor Gray
        Set-Content -Path $filePath -Value $jsonContent -Encoding UTF8 -Force
        Write-Host "  ✅ Successfully wrote config to '$filePath'" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Failed to write config file '$FileName': $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}


# --- Main Logic ---
Write-SectionHeader "MCP Config Rebuilder v1.0"

# Verify config directory exists
if (-not (Test-Path $ConfigDir -PathType Container)) {
    Write-Host "Config directory not found. Creating it..." -ForegroundColor Yellow
    New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null
}

# Create a backup
$backupDir = Join-Path (Split-Path $ConfigDir -Parent) "backups" "config-rebuild-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
if (Test-Path $ConfigDir) {
    Write-Host "Creating backup of existing configuration..." -ForegroundColor Gray
    Copy-Item -Path $ConfigDir -Destination $backupDir -Recurse -Force
    Write-Host "  -> Backup saved to '$backupDir'" -ForegroundColor Gray
}

Write-SectionHeader "Generating Server Configurations"

# --- Server Configuration Definitions ---

# 1. AI Server
$aiConfig = @{
  name = "ai-server"
  version = "1.0.0"
  description = "MCP server for AI model interactions (Claude, Ollama)"
  command = "npx"
  args = @(
    "-y",
    "@modelcontextprotocol/server-ai", # Placeholder package name
    "--config",
    "`${WORKFLOW_ROOT}/configs/ai-config.toml"
  )
  env = @{
    ANTHROPIC_API_KEY = "`${env:ANTHROPIC_API_KEY}"
  }
  options = @{
    port = 7800
    host = "localhost"
    logLevel = "info"
  }
  healthCheck = @{
    endpoint = "/health"
    interval = 60
    timeout = 10
  }
}
Write-ConfigFile "ai-config.json" $aiConfig

# 2. GitHub Server
$githubConfig = @{
  name = "github-server"
  version = "2.0.0"
  description = "MCP server for GitHub integration"
  command = "npx"
  args = @("-y", "@modelcontextprotocol/server-github")
  env = @{
    GITHUB_TOKEN = "`${env:GITHUB_TOKEN}"
  }
  options = @{
    port = 7801
    host = "localhost"
    logLevel = "info"
  }
  healthCheck = @{
    endpoint = "/health"
    interval = 120
    timeout = 15
  }
}
Write-ConfigFile "github-config.json" $githubConfig

# 3. Web Search Server
$webSearchConfig = @{
  name = "web-search-server"
  version = "2.0.0"
  description = "MCP server for web search via Brave Search API"
  command = "npx"
  args = @("-y", "@modelcontextprotocol/server-brave-search")
  env = @{
    BRAVE_API_KEY = "`${env:BRAVE_API_KEY}"
  }
  options = @{
    port = 7802
    host = "localhost"
    logLevel = "info"
  }
  healthCheck = @{
    endpoint = "/health"
    interval = 120
    timeout = 15
  }
}
Write-ConfigFile "web-search-config.json" $webSearchConfig

# 4. Filesystem Server
$filesystemConfig = @{
  name = "filesystem-server"
  version = "2.0.0"
  description = "MCP server for filesystem operations"
  command = "npx"
  args = @("-y", "@modelcontextprotocol/server-filesystem", "C:\", $env:USERPROFILE)
  env = @{}
  options = @{
    port = 7803
    host = "localhost"
    logLevel = "info"
  }
}
Write-ConfigFile "filesystem-config.json" $filesystemConfig

# 5. Memory Server
$memoryConfig = @{
  name = "memory-server"
  version = "2.0.0"
  description = "MCP server for knowledge graph and memory"
  command = "npx"
  args = @("-y", "@modelcontextprotocol/server-memory")
  env = @{}
  options = @{
    port = 7804
    host = "localhost"
    logLevel = "info"
  }
}
Write-ConfigFile "memory-config.json" $memoryConfig

# 6. Sequential Thinking Server
$seqThinkingConfig = @{
  name = "sequential-thinking-server"
  version = "2.0.0"
  description = "MCP server for advanced reasoning"
  command = "npx"
  args = @("-y", "@modelcontextprotocol/server-sequential-thinking")
  env = @{}
  options = @{
    port = 7805
    host = "localhost"
    logLevel = "info"
  }
}
Write-ConfigFile "sequential-thinking-config.json" $seqThinkingConfig

# 7. Puppeteer Server
$puppeteerConfig = @{
  name = "puppeteer-server"
  version = "2.0.0"
  description = "MCP server for browser automation"
  command = "npx"
  args = @("-y", "@todoforai/puppeteer-mcp-server")
  env = @{}
  options = @{
    port = 7806
    host = "localhost"
    logLevel = "info"
  }
}
Write-ConfigFile "puppeteer-config.json" $puppeteerConfig

# 8. SQLite Server
$sqliteConfig = @{
  name = "sqlite-server"
  version = "2.0.0"
  description = "MCP server for SQLite database operations"
  command = "npx"
  args = @("-y", "@modelcontextprotocol/server-sqlite")
  env = @{}
  options = @{
    port = 7807
    host = "localhost"
    logLevel = "info"
  }
}
Write-ConfigFile "sqlite-config.json" $sqliteConfig

# 9. Fetch Server
$fetchConfig = @{
  name = "fetch-server"
  version = "2.0.0"
  description = "MCP server for HTTP requests"
  command = "npx"
  args = @("-y", "@modelcontextprotocol/server-fetch")
  env = @{}
  options = @{
    port = 7808
    host = "localhost"
    logLevel = "info"
  }
}
Write-ConfigFile "fetch-config.json" $fetchConfig


Write-SectionHeader "Configuration Rebuild Complete"
Write-Host "✅ All configuration files have been successfully generated in '$ConfigDir'." -ForegroundColor Green
Write-Host "Next, please create a '.env' file in the project root with your API keys." -ForegroundColor Yellow
Write-Host "You can use '.env.example' as a template." -ForegroundColor Yellow
Write-Host ""
