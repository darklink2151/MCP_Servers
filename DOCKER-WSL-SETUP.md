# Docker & WSL Setup Guide

## ✅ Current Status

### Windows Virtualization Features

- ✅ **Virtual Machine Platform**: Enabled
- ✅ **Windows Subsystem for Linux**: Enabled
- ✅ **Windows Hypervisor Platform**: Just enabled (requires restart)
- ⚠️ **Hyper-V**: Detected but may need full configuration

### Docker Status

- ✅ **Docker CLI**: v28.5.1 working
- ⚠️ **Docker Engine**: 500 Internal Server Error (restarting)
- ✅ **Docker Desktop**: Process restarted

### WSL Status

- ✅ **WSL Version**: 2.6.1.0
- ✅ **Kali Linux**: Available but stopped
- ⚠️ **WSL Config**: Some unknown keys in config

## 🔧 Next Steps

### 1. System Restart Required

The Windows Hypervisor Platform was just enabled and requires a restart:

```powershell
# After restart, verify:
Get-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform
```

### 2. Docker Desktop Configuration

After restart:

1. **Open Docker Desktop**
2. **Go to Settings → General**
3. **Enable "Use the WSL 2 based engine"**
4. **Enable "Use WSL 2 integration"**
5. **Select Kali Linux distribution**

### 3. WSL Configuration Fix

Fix the unknown keys in `.wslconfig`:

```bash
# Edit C:\Users\beckd\.wslconfig
# Remove or comment out:
# wsl2.vmCompaction
# wsl2.autoMemoryReclaim
# wsl2.vmCompute
```

### 4. Test Docker & WSL Integration

```powershell
# Test WSL
wsl -d kali-linux echo "WSL working!"

# Test Docker
docker run hello-world

# Test Docker with WSL
docker run --rm -it alpine sh
```

## 🐳 Docker Project Ready

Created in `docker-test-project/`:

- ✅ **Dockerfile**: Alpine-based test container
- ✅ **docker-compose.yml**: Multi-service setup
- ✅ **test-docker.ps1**: Comprehensive test script

## 🚀 After Restart Commands

```powershell
cd C:\Users\beckd\MCP_Servers\docker-test-project

# Test everything
.\test-docker.ps1

# Build and run test container
docker build -t docker-test .
docker run --rm docker-test

# Test WSL integration
docker run --rm -it alpine sh
```

## 🔍 Troubleshooting

### If Docker still shows 500 errors

1. **Check BIOS/UEFI**: Ensure Intel VT-x/AMD-V is enabled
2. **Disable Secure Boot**: May conflict with Docker
3. **Reinstall Docker Desktop**: Clean installation after restart
4. **Check Windows Features**: Ensure all Hyper-V components enabled

### If WSL issues persist

1. **Update WSL**: `wsl --update`
2. **Restart WSL**: `wsl --shutdown`
3. **Fix config**: Remove unknown keys from `.wslconfig`
4. **Reinstall distribution**: `wsl --unregister kali-linux`

---

**Status**: Virtualization enabled, restart required for full functionality
