# Unified MCP Server Configuration

## Overview

This is a centralized MCP (Model Context Protocol) server configuration system designed to work seamlessly with both Cursor and Warp. All configurations are unified in a single location for easy management and consistency.

## Directory Structure

```
C:\Users\beckd\MCP_Servers\
├── configs\                 # Individual server configurations
├── data\                    # Runtime data and caches
├── databases\               # SQLite databases
├── docs\                    # Documentation
├── logs\                    # Log files
├── scripts\                 # Management scripts
├── backups\                 # Configuration backups
├── cursor-mcp-config.json   # Cursor-specific configuration
├── warp-mcp-config.toml     # Warp-specific configuration
└── unified-mcp-config.json  # Master configuration file
```

## Available MCP Servers

### Core Servers

- **filesystem**: File system operations and management
- **memory**: Persistent memory and knowledge graph management
- **sequential-thinking**: Advanced reasoning and problem-solving

### Development Servers

- **github**: GitHub API integration for repository management
- **sqlite**: SQLite database operations and management
- **fetch**: HTTP requests and web content fetching

### Research & Automation Servers

- **web-search**: Web search capabilities using Brave Search API
- **puppeteer**: Browser automation and web scraping
- **everything-search**: Fast file search using Everything Search Engine

## Quick Start

### 1. Install MCP Servers

```powershell
.\scripts\mcp-manager.ps1 -Action install
```

### 2. Setup Cursor

```powershell
.\scripts\setup-cursor.ps1
```

### 3. Setup Warp

```powershell
.\scripts\setup-warp.ps1
```

### 4. Start Development Workflow

```powershell
.\scripts\mcp-manager.ps1 -Action start -Workflow development
```

## Workflows

### Development Workflow

- **Servers**: filesystem, memory, github, web-search, fetch, sqlite, sequential-thinking
- **Use Case**: Software development with version control and testing
- **Features**: Code analysis, package management, documentation generation

### Research Workflow

- **Servers**: filesystem, memory, web-search, fetch, sqlite, puppeteer, sequential-thinking
- **Use Case**: Research and data analysis
- **Features**: Data collection, literature review, statistical analysis

### Automation Workflow

- **Servers**: filesystem, memory, fetch, puppeteer, sqlite, everything-search
- **Use Case**: Task automation and system management
- **Features**: Scheduled tasks, web interactions, data processing

### Cybersecurity Workflow

- **Servers**: filesystem, memory, web-search, fetch, sqlite, puppeteer, sequential-thinking, everything-search
- **Use Case**: Penetration testing and security analysis
- **Features**: Vulnerability assessment, evidence collection, threat intelligence

### Organization Workflow

- **Servers**: filesystem, memory, sqlite, everything-search, sequential-thinking
- **Use Case**: System organization and maintenance
- **Features**: File organization, system cleanup, backup automation

## Management Commands

### Start Servers

```powershell
# Start all servers in development workflow
.\scripts\mcp-manager.ps1 -Action start -Workflow development

# Start specific server
.\scripts\mcp-manager.ps1 -Action start -Server github
```

### Stop Servers

```powershell
# Stop all servers
.\scripts\mcp-manager.ps1 -Action stop

# Stop specific server
.\scripts\mcp-manager.ps1 -Action stop -Server github
```

### Check Status

```powershell
# Check status of all servers
.\scripts\mcp-manager.ps1 -Action status

# Check specific server
.\scripts\mcp-manager.ps1 -Action status -Server github
```

### Backup Configuration

```powershell
.\scripts\mcp-manager.ps1 -Action backup
```

### Clean Up Old Configurations

```powershell
.\scripts\mcp-manager.ps1 -Action cleanup -Force
```

## Configuration Files

### cursor-mcp-config.json

JSON configuration file specifically formatted for Cursor's MCP integration.

### warp-mcp-config.toml

TOML configuration file specifically formatted for Warp's MCP integration.

### unified-mcp-config.json

Master configuration file containing all server definitions, workflows, and settings.

## Security Features

- **API Key Protection**: Sensitive tokens are stored securely
- **Access Logging**: All access attempts are logged
- **Permission Enforcement**: Strict permission controls
- **Input Sanitization**: All inputs are sanitized
- **Separate User Context**: Isolated execution contexts

## Logging

- **Central Logging**: All logs are centralized in the `logs` directory
- **Log Rotation**: Automatic log rotation with size limits
- **JSON Format**: Structured logging for easy parsing
- **Separate Log Files**: Each server has its own log file

## Backup & Recovery

- **Daily Backups**: Automatic daily backups of configurations and data
- **Compression**: Backup files are compressed to save space
- **Retention**: 7 days of backup retention
- **Manual Backup**: On-demand backup creation

## Monitoring

- **Performance Metrics**: CPU, memory, and resource utilization tracking
- **Usage Statistics**: Server usage and request tracking
- **Error Monitoring**: Error tracking and alerting
- **Health Checks**: Automatic health monitoring

## Troubleshooting

### Common Issues

1. **Server Won't Start**
   - Check if Node.js and npm are installed
   - Verify API keys are set correctly
   - Check log files for error messages

2. **Configuration Not Loading**
   - Ensure configuration files are in the correct location
   - Verify JSON/TOML syntax is valid
   - Check file permissions

3. **API Errors**
   - Verify API keys are valid and have correct permissions
   - Check rate limits and quotas
   - Review API documentation for changes

### Log Files Location

- **Main Log**: `logs\mcp-manager.log`
- **Server Logs**: `logs\{server-name}.log`
- **Error Logs**: `logs\errors.log`

## Advanced Configuration

### Custom Workflows

You can create custom workflows by modifying the `unified-mcp-config.json` file:

```json
{
  "workflows": {
    "custom": {
      "name": "Custom Workflow",
      "description": "Your custom workflow description",
      "servers": ["filesystem", "memory", "github"],
      "integrations": {
        "customFeature": true
      }
    }
  }
}
```

### Environment Variables

You can set custom environment variables for servers in the configuration files:

```json
{
  "servers": {
    "custom-server": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-custom"],
      "env": {
        "CUSTOM_API_KEY": "your-api-key",
        "CUSTOM_SETTING": "value"
      }
    }
  }
}
```

## Support

For issues and questions:

1. Check the log files first
2. Review this documentation
3. Check the MCP server documentation
4. Create an issue in the project repository

## Version Information

- **Configuration Version**: 2.0.0
- **Last Updated**: 2025-01-15
- **Compatible With**: Cursor >=0.42.0, Warp >=0.2024.12.1
