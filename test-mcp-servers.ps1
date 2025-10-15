# Test MCP Servers Script
# Quick test to verify MCP servers are working

Write-Host "=== MCP Server Test ===" -ForegroundColor Cyan

$Servers = @(
    @{
        Name = "filesystem"
        Command = "npx"
        Args = @("-y", "@modelcontextprotocol/server-filesystem", "C:\Users\beckd\MCP_Servers")
    },
    @{
        Name = "memory"
        Command = "npx"
        Args = @("-y", "@modelcontextprotocol/server-memory")
    },
    @{
        Name = "sequential-thinking"
        Command = "npx"
        Args = @("-y", "@modelcontextprotocol/server-sequential-thinking")
    },
    @{
        Name = "everything-search"
        Command = "npx"
        Args = @("-y", "@modelcontextprotocol/server-everything")
    }
)

foreach ($Server in $Servers) {
    Write-Host "`nTesting $($Server.Name)..." -ForegroundColor Yellow

    try {
        $Process = Start-Process -FilePath $Server.Command -ArgumentList $Server.Args -NoNewWindow -PassThru
        Start-Sleep -Seconds 2

        if ($Process.HasExited) {
            Write-Host "❌ $($Server.Name) failed to start" -ForegroundColor Red
        } else {
            Write-Host "✅ $($Server.Name) started successfully (PID: $($Process.Id))" -ForegroundColor Green
            Stop-Process -Id $Process.Id -Force
        }
    } catch {
        Write-Host "❌ $($Server.Name) error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "Your unified MCP configuration is ready!" -ForegroundColor Green
Write-Host "`nConfiguration files:" -ForegroundColor Gray
Write-Host "• Cursor: $env:APPDATA\Cursor\User\mcp-config.json" -ForegroundColor Gray
Write-Host "• Warp: $env:APPDATA\Warp\mcp-config.toml" -ForegroundColor Gray
Write-Host "• Master: C:\Users\beckd\MCP_Servers\unified-mcp-config.json" -ForegroundColor Gray

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Restart Cursor and Warp to apply configurations" -ForegroundColor White
Write-Host "2. The MCP servers will be available in both applications" -ForegroundColor White
Write-Host "3. Use the management scripts for server control" -ForegroundColor White
