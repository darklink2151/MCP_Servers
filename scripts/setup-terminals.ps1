# Terminal Environment Setup Script
# Helps users understand and properly configure separate terminal environments

param(
    [switch]$FixWSL,
    [switch]$SetupWarp,
    [switch]$TestAll,
    [switch]$ShowStatus
)

function Write-TerminalInfo {
    param([string]$Message, [string]$Color = "White")
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $Message" -ForegroundColor $Color
}

Write-TerminalInfo "Terminal Environment Setup" "Cyan"

if ($ShowStatus) {
    Write-TerminalInfo "=== TERMINAL STATUS ===" "Yellow"

    # Check current environment
    Write-TerminalInfo "Current Session:" "Green"
    Write-TerminalInfo "  User: $env:USERNAME"
    Write-TerminalInfo "  Computer: $env:COMPUTERNAME"
    Write-TerminalInfo "  OS: $(Get-CimInstance Win32_OperatingSystem).Caption"
    Write-TerminalInfo "  PowerShell Version: $($PSVersionTable.PSVersion)"

    # Check WSL
    Write-TerminalInfo "`nWSL Status:" "Green"
    try {
        $wslOutput = wsl -l -v 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-TerminalInfo "  WSL Available: Yes"
            Write-TerminalInfo "  Distributions:"
            wsl -l -v | ForEach-Object {
                if ($_ -match "(\*?\s+)(\S+)\s+(\S+)\s+(\d+)") {
                    $marker = $matches[1].Trim()
                    $name = $matches[2]
                    $state = $matches[3]
                    $version = $matches[4]
                    Write-TerminalInfo "    $marker $name ($state, WSL$version)" "Gray"
                }
            }
        } else {
            Write-TerminalInfo "  WSL Available: No" "Red"
        }
    } catch {
        Write-TerminalInfo "  WSL Available: Error checking" "Red"
    }

    # Check terminal emulators
    Write-TerminalInfo "`nTerminal Emulators:" "Green"
    $terminals = @("Warp", "WindowsTerminal", "fluent-terminal", "tabby")
    foreach ($terminal in $terminals) {
        $installed = Get-Command $terminal -ErrorAction SilentlyContinue
        if ($installed) {
            Write-TerminalInfo "  $terminal : Installed" "Green"
        } else {
            Write-TerminalInfo "  $terminal : Not found" "Gray"
        }
    }

    # Check Cursor
    $cursorPath = "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe"
    if (Test-Path $cursorPath) {
        Write-TerminalInfo "  Cursor IDE: Installed" "Green"
    } else {
        Write-TerminalInfo "  Cursor IDE: Not found" "Gray"
    }

    Write-TerminalInfo "`n=== USAGE GUIDE ===" "Yellow"
    Write-TerminalInfo "1. Windows PowerShell: Native Windows commands, system admin"
    Write-TerminalInfo "2. WSL Terminal: Linux environment, development tools"
    Write-TerminalInfo "3. Warp/Cursor Terminal: Modern terminal with MCP integration"
    Write-TerminalInfo ""
    Write-TerminalInfo "To switch between environments:" "Cyan"
    Write-TerminalInfo "  - Windows PowerShell: 'powershell' or 'pwsh'"
    Write-TerminalInfo "  - WSL: 'wsl' or 'wsl -d kali-linux'"
    Write-TerminalInfo "  - Warp: Launch from Start Menu"
    Write-TerminalInfo "  - Cursor: Use built-in terminal (Ctrl+`)"

    return
}

if ($FixWSL) {
    Write-TerminalInfo "=== FIXING WSL CONFIGURATION ===" "Yellow"

    # Check and fix WSL config
    $wslConfigPath = "$env:USERPROFILE\.wslconfig"
    if (Test-Path $wslConfigPath) {
        Write-TerminalInfo "Checking .wslconfig..." "Green"
        $config = Get-Content $wslConfigPath -Raw

        # Remove problematic settings
        $fixedConfig = $config -replace "(?m)^wsl2\.vmCompaction.*\r?\n?" -replace "(?m)^wsl2\.autoMemoryReclaim.*\r?\n?" -replace "(?m)^wsl2\.vmCompute.*\r?\n?"

        if ($fixedConfig -ne $config) {
            Set-Content -Path $wslConfigPath -Value $fixedConfig -Encoding UTF8
            Write-TerminalInfo "Fixed .wslconfig - removed unknown settings" "Green"
        } else {
            Write-TerminalInfo ".wslconfig appears clean" "Green"
        }
    }

    # Set up proper user in WSL
    Write-TerminalInfo "Setting up WSL user..." "Green"

    # Start WSL and create proper user setup
    $username = $env:USERNAME
    $wslSetupScript = @'
#!/bin/bash
echo 'Setting up WSL user environment...'
useradd -m -s /bin/bash {0} 2>/dev/null || echo 'User may already exist'
echo '{0} ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/{0}
chmod 0440 /etc/sudoers.d/{0}
mkdir -p /home/{0}/.config
echo ''export PATH=$PATH:/usr/local/bin'' >> /home/{0}/.bashrc
chown -R {0}:{0} /home/{0}
echo 'WSL user setup complete'
'@ -f $username

    # Write script to temp file and execute
    $tempScript = "$env:TEMP\wsl-setup.sh"
    $wslSetupScript | Out-File -FilePath $tempScript -Encoding ASCII
    wsl -d kali-linux -u root bash $tempScript
    Remove-Item $tempScript -ErrorAction SilentlyContinue

    Write-TerminalInfo "WSL configuration fixed. Restart WSL: 'wsl --shutdown && wsl'" "Green"
}

if ($SetupWarp) {
    Write-TerminalInfo "=== SETTING UP WARP TERMINAL ===" "Yellow"

    $warpConfigDir = "$env:APPDATA\Warp"
    $mcpConfigDir = "C:\Users\$env:USERNAME\MCP_Servers"
    $configFile = "$mcpConfigDir\warp-mcp-config.toml"

    if (!(Test-Path $warpConfigDir)) {
        New-Item -Path $warpConfigDir -ItemType Directory -Force | Out-Null
        Write-TerminalInfo "Created Warp config directory" "Green"
    }

    if (Test-Path $configFile) {
        $warpMCPConfig = "$warpConfigDir\mcp-config.toml"
        Copy-Item -Path $configFile -Destination $warpMCPConfig -Force
        Write-TerminalInfo "Copied MCP configuration to Warp" "Green"

        # Create Warp settings
        $warpSettings = "$warpConfigDir\settings.toml"
        $settingsContent = @"
[mcp]
enabled = true
auto_start = true
log_level = "info"
config_path = "$warpMCPConfig"

[mcp.servers]
# Servers loaded from MCP config file
"@

        Set-Content -Path $warpSettings -Value $settingsContent -Encoding UTF8
        Write-TerminalInfo "Created Warp settings with MCP integration" "Green"
    } else {
        Write-TerminalInfo "MCP config not found at $configFile" "Red"
    }

    Write-TerminalInfo "Warp setup complete. Restart Warp to apply changes." "Green"
}

if ($TestAll) {
    Write-TerminalInfo "=== TESTING ALL TERMINAL ENVIRONMENTS ===" "Yellow"

    # Test Windows PowerShell
    Write-TerminalInfo "Testing Windows PowerShell..." "Green"
    $psVersion = $PSVersionTable.PSVersion
    Write-TerminalInfo "  ✓ PowerShell $psVersion working" "Green"

    # Test WSL
    Write-TerminalInfo "Testing WSL..." "Green"
    try {
        $wslTest = wsl -d kali-linux -- echo "WSL test successful" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-TerminalInfo "  ✓ WSL working" "Green"
        } else {
            Write-TerminalInfo "  ✗ WSL test failed" "Red"
        }
    } catch {
        Write-TerminalInfo "  ✗ WSL not available" "Red"
    }

    # Test basic connectivity
    Write-TerminalInfo "Testing network connectivity..." "Green"
    try {
        $testConnection = Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet
        if ($testConnection) {
            Write-TerminalInfo "  ✓ Internet connection working" "Green"
        } else {
            Write-TerminalInfo "  ✗ No internet connection" "Red"
        }
    } catch {
        Write-TerminalInfo "  ✗ Network test failed" "Red"
    }

    Write-TerminalInfo "Environment tests complete" "Green"
}

Write-TerminalInfo "Terminal setup script completed" "Cyan"
