# 🚀 MCP Servers - Quick Start Guide

## ONE-COMMAND START

```powershell
.\START-MCP.ps1
```

That's it! This starts your daily essentials automatically.

---

## 📋 Common Commands

### Start Servers
```powershell
# Start daily workflow (default)
.\START-MCP.ps1

# Start specific workflow
.\START-MCP.ps1 -Workflow development
.\START-MCP.ps1 -Workflow cybersecurity
.\START-MCP.ps1 -Workflow redTeam
```

### Control Dashboard
```powershell
# Open interactive dashboard
.\START-MCP.ps1 -Dashboard
```

### Check Status
```powershell
# Quick status check
.\START-MCP.ps1 -Status

# Detailed status
.\scripts\Get-MCPStatus.ps1
```

### Stop Servers
```powershell
# Stop all servers
.\START-MCP.ps1 -Stop
```

---

## 🎯 Available Workflows

| Workflow | Description | Servers |
|----------|-------------|---------|
| **daily** | Core servers for daily use | filesystem, memory, webSearch, fetch, sequentialThinking |
| **development** | Full development environment | + github, sqlite |
| **research** | Research and analysis | + puppeteer, sqlite |
| **automation** | Task automation | + puppeteer |
| **cybersecurity** | Security operations | All except metasploit |
| **redTeam** | Red team engagement | OSINT-focused, no exploitation |
| **osint** | Intelligence gathering | Web scraping and data collection |
| **webDevelopment** | Web development | Full stack with testing |
| **organization** | System maintenance | File management focused |

---

## ⚙️ Setup Auto-Start

Make MCP servers start automatically when you log in:

```powershell
# Setup auto-start on login
.\scripts\Setup-AutoStart.ps1

# Setup auto-start at boot (requires admin)
.\scripts\Setup-AutoStart.ps1 -TriggerType Boot

# Setup both
.\scripts\Setup-AutoStart.ps1 -TriggerType Both

# Remove auto-start
.\scripts\Setup-AutoStart.ps1 -Remove
```

---

## 🎛️ Control Dashboard

The interactive dashboard provides:

- ✅ Real-time server status
- 🚀 Start/stop workflows
- 📊 System health monitoring
- 📝 Log viewing
- 💾 Backup management
- ⚙️ Auto-start configuration

```powershell
.\START-MCP.ps1 -Dashboard
```

Or directly:
```powershell
.\scripts\MCP-Dashboard.ps1
```

---

## 🔧 Advanced Usage

### Manual Server Management
```powershell
# Using mcp-cli.js (recommended)
node .\scripts\mcp-cli.js status
node .\scripts\mcp-cli.js start-server filesystem
node .\scripts\mcp-cli.js stop-server filesystem
node .\scripts\mcp-cli.js start-workflow development

# Using PowerShell manager
.\scripts\mcp-manager.ps1 -Action status
.\scripts\mcp-manager.ps1 -Action start -Workflow development
.\scripts\mcp-manager.ps1 -Action stop
```

### View Logs
```powershell
# View specific log
Get-Content logs\filesystem.log -Tail 20

# View all recent logs
Get-ChildItem logs\*.log | ForEach-Object {
    Write-Host $_.Name -ForegroundColor Cyan
    Get-Content $_.FullName -Tail 5
    Write-Host ""
}
```

### Backup Configuration
```powershell
.\scripts\mcp-manager.ps1 -Action backup
```

---

## 🔒 Red Team Workflows

### OSINT Workflow
Perfect for intelligence gathering:
```powershell
.\START-MCP.ps1 -Workflow osint
```

**Capabilities:**
- Social media analysis
- Public records search
- Domain intelligence
- Email harvesting (from public sources)
- Metadata extraction
- Network mapping
- Data aggregation

### Cybersecurity Workflow
General security operations:
```powershell
.\START-MCP.ps1 -Workflow cybersecurity
```

**Capabilities:**
- Vulnerability assessment
- Evidence collection
- Threat intelligence
- Report generation
- Web reconnaissance

### Red Team Workflow
Focused on reconnaissance and documentation:
```powershell
.\START-MCP.ps1 -Workflow redTeam
```

**Phases:**
1. **Reconnaissance** - Target analysis
2. **Weaponization** - Tool preparation
3. **Delivery** - Access attempts (documentation only)
4. **Documentation** - Comprehensive reporting

**NOTE:** Exploitation capabilities are DISABLED by design for ethical use.

---

## 📊 Monitoring

### Real-Time Status
```powershell
# Watch mode (updates every 5 seconds)
while ($true) {
    Clear-Host
    .\START-MCP.ps1 -Status
    Start-Sleep -Seconds 5
}
```

### System Health
```powershell
.\scripts\MCP-Dashboard.ps1 health
```

---

## 🆘 Troubleshooting

### Servers Won't Start
```powershell
# Check if Node.js is available
node --version

# Check for port conflicts
netstat -ano | findstr ":<port>"

# View error logs
Get-Content logs\mcp-manager.log -Tail 50
```

### Reset Everything
```powershell
# Stop all servers
.\START-MCP.ps1 -Stop

# Wait a moment
Start-Sleep -Seconds 3

# Start fresh
.\START-MCP.ps1
```

### Clean Reinstall
```powershell
# Stop servers
.\START-MCP.ps1 -Stop

# Remove old processes
Get-Process node | Where-Object {
    $_.CommandLine -like "*mcp*"
} | Stop-Process -Force

# Restart
.\START-MCP.ps1
```

---

## 📁 Directory Structure

```
C:\Users\beckd\MCP_Servers\
├── START-MCP.ps1              ⭐ Main entry point
├── README-QUICKSTART.md        📖 This file
├── configs/                    ⚙️ Server configurations
│   └── master-config.json      🎯 Master configuration
├── scripts/                    🔧 Management scripts
│   ├── MCP-Dashboard.ps1       🎛️ Control dashboard
│   ├── Setup-AutoStart.ps1     ⚡ Auto-start setup
│   ├── Start-Autostart.ps1     🚀 Autostart runner
│   ├── Get-MCPStatus.ps1       📊 Status checker
│   ├── Stop-AllMCP.ps1         🛑 Stop all servers
│   ├── mcp-cli.js              💻 CLI interface
│   └── mcp-manager.ps1         🎛️ Server manager
├── logs/                       📝 Log files
├── data/                       💾 Runtime data
├── databases/                  🗄️ SQLite databases
└── backups/                    💾 Configuration backups
```

---

## 🎉 Next Steps

1. **First Time Setup:**
   ```powershell
   .\scripts\Setup-AutoStart.ps1
   ```

2. **Daily Use:**
   ```powershell
   .\START-MCP.ps1
   ```

3. **Explore Dashboard:**
   ```powershell
   .\START-MCP.ps1 -Dashboard
   ```

4. **Check Status:**
   ```powershell
   .\START-MCP.ps1 -Status
   ```

---

## 💡 Pro Tips

1. **Pin to Taskbar:** Right-click `START-MCP.ps1` → "Pin to Taskbar" for one-click access

2. **Create Desktop Shortcut:**
   ```powershell
   $WshShell = New-Object -comObject WScript.Shell
   $Shortcut = $WshShell.CreateShortcut("$Home\Desktop\MCP Servers.lnk")
   $Shortcut.TargetPath = "pwsh.exe"
   $Shortcut.Arguments = "-File `"$PWD\START-MCP.ps1`" -Dashboard"
   $Shortcut.Save()
   ```

3. **Auto-Start on Boot:** Run `.\scripts\Setup-AutoStart.ps1` once

4. **Quick Status Check:** Add alias to your PowerShell profile:
   ```powershell
   Set-Alias mcp "$PWD\START-MCP.ps1"
   ```

---

**Version:** 2.0.0
**Author:** DirtyWork AI
**Last Updated:** 2025-10-16

🚀 **Happy Hacking!** 🚀
