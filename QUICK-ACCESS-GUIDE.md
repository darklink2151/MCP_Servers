# Quick Access Guide for MCP

This guide explains the fastest ways to use your MCP setup with minimal manual configuration.

## One-Click Daily Startup

The simplest way to start your MCP environment:

```powershell
.\START-DAILY.ps1
```

This script:
1. Starts your default workflow (initially set to "development")
2. Opens the MCP dashboard
3. Shows quick reference commands

## Desktop Shortcuts

For even faster access, create desktop shortcuts:

```powershell
.\scripts\quick-access.ps1
```

This creates:
- **MCP-Start** - Launches your daily workflow
- **MCP-Dashboard** - Opens the control dashboard
- **MCP-Stop-All** - Stops all running MCP servers

## Automatic Startup

To have MCP start automatically when you log in:

```powershell
.\scripts\Setup-AutoStart.ps1 -StartTrigger Login -WorkflowName development
```

Options:
- `-StartTrigger`: Either `Login` (user login) or `Boot` (system startup)
- `-WorkflowName`: The workflow to start (`development`, `research`, `automation`, `ai_development`)

## Customizing Your Default Workflow

Edit `START-DAILY.ps1` and change:

```powershell
$defaultWorkflow = "development"  # Change to your preferred workflow
```

Available workflows:
- `development` - For software development
- `research` - For research and analysis
- `automation` - For task automation
- `ai_development` - For AI development

## Common Tasks Without Opening Config Files

| Task | Command |
|------|---------|
| Start default workflow | `.\START-DAILY.ps1` |
| Open dashboard | `.\scripts\MCP-Dashboard.ps1` |
| Check server status | `.\scripts\Get-MCPStatus.ps1` |
| Stop all servers | `.\scripts\Stop-AllMCP.ps1` |
| Start specific workflow | `.\scripts\Start-Workflow.ps1 -WorkflowName research` |

## Dashboard Shortcuts

When using the MCP Dashboard:

1. Press `1` to start a workflow
2. Press `3` to stop all servers
3. Press `R` to refresh status
4. Press `Q` to quit

## Workflow-Specific Quick Starts

For specialized workflows:

```powershell
# AI Development
.\START-MCP.ps1 -Workflow ai_development

# Research
.\START-MCP.ps1 -Workflow research

# Automation
.\START-MCP.ps1 -Workflow automation
```

## Only Configure When Needed

You should only need to edit configuration files when:
1. Adding a new MCP server
2. Creating a custom workflow
3. Changing server behavior

For day-to-day use, the scripts and shortcuts above should be sufficient.
