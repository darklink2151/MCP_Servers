@echo off
REM MCP Workflow Startup Script
REM This script runs when Windows starts to prepare the MCP environment

echo Starting MCP Workflow Environment...

REM Set up environment variables
set MCP_WORKFLOW_ROOT=C:\Users\beckd\MCP-Workflow
set MCP_DAILY_MODE=true
set MCP_AUTO_START=true

REM Add MCP scripts to PATH for this session
set PATH=%PATH%;%MCP_WORKFLOW_ROOT%\scripts

REM Create log directory if it doesn't exist
if not exist "%MCP_WORKFLOW_ROOT%\logs" mkdir "%MCP_WORKFLOW_ROOT%\logs"

REM Log startup
echo [%date% %time%] MCP Workflow environment initialized >> "%MCP_WORKFLOW_ROOT%\logs\startup.log"

REM Check if this is a weekday (Monday=1, Friday=5)
for /f %%i in ('powershell -command "Get-Date -Format 'dddd'"') do set dayofweek=%%i

REM Run daily setup if it's a weekday
if "%dayofweek%"=="Monday" goto daily_setup
if "%dayofweek%"=="Tuesday" goto daily_setup
if "%dayofweek%"=="Wednesday" goto daily_setup
if "%dayofweek%"=="Thursday" goto daily_setup
if "%dayofweek%"=="Friday" goto daily_setup
goto weekend_mode

:daily_setup
echo Running weekday MCP setup...
powershell -ExecutionPolicy Bypass -File "%MCP_WORKFLOW_ROOT%\scripts\daily-workflow.ps1" -WorkflowType development
goto end

:weekend_mode
echo Weekend mode - minimal MCP setup...
powershell -ExecutionPolicy Bypass -File "%MCP_WORKFLOW_ROOT%\scripts\daily-workflow.ps1" -WorkflowType contentCreation
goto end

:end
echo MCP Workflow startup complete.
echo To start Cursor with MCP: Start-MCPWorkflow -StartCursor
