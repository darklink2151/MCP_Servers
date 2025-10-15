# Unified MCP Server Configuration

## 🚀 Quick Start

This is your centralized MCP (Model Context Protocol) server configuration that works with both **Cursor** and **Warp**. Everything is consolidated in one place for maximum efficiency.

### One-Command Setup

```powershell
.\SETUP-UNIFIED-MCP.ps1
```

## 📁 What's Included

### 🛠️ MCP Servers (9 Total)

- **filesystem** - File operations and management
- **memory** - Knowledge graph and persistent memory
- **github** - Repository management and code operations
- **web-search** - Real-time web search capabilities
- **fetch** - HTTP requests and content fetching
- **sqlite** - Database operations and data storage
- **puppeteer** - Browser automation and web scraping
- **sequential-thinking** - Advanced reasoning and problem-solving
- **everything-search** - Lightning-fast file search

### 🔄 Workflows

- **Development** - Complete software development workflow
- **Research** - Data collection and analysis workflow
- **Automation** - Task automation and system management
- **Cybersecurity** - Penetration testing and security analysis
- **Organization** - File organization and system maintenance

### 📋 Management Scripts

- `mcp-manager.ps1` - Complete server management
- `setup-cursor.ps1` - Cursor configuration
- `setup-warp.ps1` - Warp configuration
- `SETUP-UNIFIED-MCP.ps1` - One-command setup

## 🎯 Common Commands

### Start Development Workflow

```powershell
.\scripts\mcp-manager.ps1 -Action start -Workflow development
```

### Check Server Status

```powershell
.\scripts\mcp-manager.ps1 -Action status
```

### Stop All Servers

```powershell
.\scripts\mcp-manager.ps1 -Action stop
```

### Backup Configuration

```powershell
.\scripts\mcp-manager.ps1 -Action backup
```

## 📖 Documentation

- **Complete Setup Guide**: `docs\UNIFIED-MCP-SETUP.md`
- **Configuration Files**:
  - `cursor-mcp-config.json` (Cursor)
  - `warp-mcp-config.toml` (Warp)
  - `unified-mcp-config.json` (Master config)

## 🔧 Configuration Files

| File | Purpose |
|------|---------|
| `cursor-mcp-config.json` | Cursor-specific MCP configuration |
| `warp-mcp-config.toml` | Warp-specific MCP configuration |
| `unified-mcp-config.json` | Master configuration with all servers and workflows |

## 🗂️ Directory Structure

```
C:\Users\beckd\MCP_Servers\
├── configs\                 # Individual server configurations
├── data\                    # Runtime data and caches
├── databases\               # SQLite databases
├── docs\                    # Documentation
├── logs\                    # Log files
├── scripts\                 # Management scripts
├── backups\                 # Configuration backups
└── *.json, *.toml          # Configuration files
```

## 🔒 Security Features

- ✅ API key protection
- ✅ Access logging
- ✅ Permission enforcement
- ✅ Input sanitization
- ✅ Isolated execution contexts

## 📊 Monitoring & Logging

- **Centralized logging** in `logs\` directory
- **Automatic log rotation**
- **Performance monitoring**
- **Error tracking and alerting**

## 🆘 Troubleshooting

### Quick Fixes

1. **Server won't start**: Check `logs\mcp-manager.log`
2. **Config not loading**: Verify JSON/TOML syntax
3. **API errors**: Check API keys and permissions

### Get Help

```powershell
# Check logs
Get-Content logs\mcp-manager.log -Tail 20

# Test configuration
.\scripts\mcp-manager.ps1 -Action status

# Restart everything
.\scripts\mcp-manager.ps1 -Action restart
```

## 🎉 Benefits of This Setup

### ✅ **Centralized**

- One location for all configurations
- No more scattered config files
- Easy to backup and restore

### ✅ **Unified**

- Same configuration for Cursor and Warp
- Consistent experience across tools
- No duplicate setups

### ✅ **Automated**

- One-command setup
- Automated server management
- Built-in backup and recovery

### ✅ **Professional**

- Enterprise-grade security
- Comprehensive monitoring
- Production-ready logging

## 🚀 Next Steps

1. **Run the setup**: `.\SETUP-UNIFIED-MCP.ps1`
2. **Restart Cursor and Warp**
3. **Start your workflow**: `.\scripts\mcp-manager.ps1 -Action start -Workflow development`
4. **Enjoy your unified MCP experience!**

---

**Created by DirtyWork AI** | **Version 2.0.0** | **2025-01-15**
