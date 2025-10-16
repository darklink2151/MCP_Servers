# MCP Configuration Guide

This document explains the configuration structure for your MCP server setup.

## Configuration Files Overview

| File | Purpose |
|------|---------|
| `unified-mcp-config.json` | Master reference file that points to all other configs |
| `cursor-mcp-config.json` | Cursor-specific MCP configuration |
| `warp-mcp-config.toml` | Warp-specific MCP configuration |
| `configs/master-config.json` | Complete server and workflow definitions |
| `configs/ai-config.toml` | AI server behavior settings |

## Configuration Structure

### unified-mcp-config.json

This is the entry point that references all other configuration files:

```json
{
  "version": "2.0.0",
  "cursor": {
    "config_path": "cursor-mcp-config.json"
  },
  "warp": {
    "config_path": "warp-mcp-config.toml"
  },
  "master": {
    "config_path": "configs/master-config.json"
  }
}
```

### configs/master-config.json

This is the main configuration file that defines all servers and workflows:

```json
{
  "mcp": {
    "config_dir": "C:\\Users\\beckd\\MCP_Servers\\configs",
    "log_dir": "C:\\Users\\beckd\\MCP_Servers\\logs",
    "data_dir": "C:\\Users\\beckd\\MCP_Servers\\data",
    "servers": {
      "filesystem": { ... },
      "memory": { ... },
      "sequential_thinking": { ... },
      "everything": { ... },
      "fetch": { ... },
      "sqlite": { ... },
      "github": { ... },
      "brave_search": { ... },
      "puppeteer": { ... },
      "ai": { ... }
    },
    "workflows": {
      "development": {
        "name": "Software Development",
        "servers": ["filesystem", "memory", "sequential_thinking", "everything"]
      },
      "research": {
        "name": "Research & Analysis",
        "servers": ["filesystem", "memory", "sequential_thinking", "everything", "puppeteer", "brave_search"]
      },
      "automation": {
        "name": "Task Automation", 
        "servers": ["filesystem", "memory", "puppeteer", "everything"]
      },
      "ai_development": {
        "name": "AI Development",
        "servers": ["filesystem", "memory", "sequential_thinking", "everything", "ai"]
      }
    }
  }
}
```

### cursor-mcp-config.json

This is the format required by Cursor for its MCP integration:

```json
{
  "mcp": {
    "servers": [
      {
        "name": "filesystem",
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", "..."]
      },
      {
        "name": "memory",
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-memory"]
      },
      ...
    ]
  }
}
```

### warp-mcp-config.toml

This is the format required by Warp for its MCP integration:

```toml
[mcp]
config_dir = "C:\\Users\\beckd\\MCP_Servers\\configs"
log_dir = "C:\\Users\\beckd\\MCP_Servers\\logs"
data_dir = "C:\\Users\\beckd\\MCP_Servers\\data"

[mcp.servers.filesystem]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-filesystem", "..."]
env = {}

[mcp.servers.memory]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-memory"]
env = {}
...
```

## Managing Configurations

### Adding a New Server

To add a new server:

1. Add it to `configs/master-config.json` under the `mcp.servers` section
2. Update `cursor-mcp-config.json` to include the new server
3. Update `warp-mcp-config.toml` to include the new server

### Adding a New Workflow

To add a new workflow:

1. Add it to `configs/master-config.json` under the `mcp.workflows` section
2. Specify which servers should be included in the workflow

### Backing Up Configurations

Use the built-in backup functionality:

```powershell
.\scripts\mcp-manager.ps1 -Action backup
```

This will create a timestamped backup in the `backups/` directory.

## Troubleshooting

- If configurations get out of sync, use `SETUP-UNIFIED-MCP.ps1` to regenerate them
- Check the logs in the `logs/` directory for error messages
- Verify that all paths in configuration files are correct and accessible
