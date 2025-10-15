# Docker and WSL Test Script

Write-Host "=== Docker & WSL Test Project ===" -ForegroundColor Cyan

Write-Host "`n1. Testing Docker Desktop..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker CLI: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker CLI not working" -ForegroundColor Red
}

Write-Host "`n2. Testing Docker Engine..." -ForegroundColor Yellow
try {
    docker info > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker Engine: Running" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Docker Engine: Not responding (may need restart)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Docker Engine: Not available" -ForegroundColor Red
}

Write-Host "`n3. Testing WSL..." -ForegroundColor Yellow
try {
    $wslVersion = wsl --version
    Write-Host "✅ WSL Version: $wslVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ WSL not available" -ForegroundColor Red
}

Write-Host "`n4. Testing WSL Kali Linux..." -ForegroundColor Yellow
try {
    wsl -d kali-linux echo "WSL Kali Linux connection test" > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ WSL Kali Linux: Working" -ForegroundColor Green
    } else {
        Write-Host "⚠️ WSL Kali Linux: Needs to be started" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ WSL Kali Linux: Error" -ForegroundColor Red
}

Write-Host "`n5. Testing Docker Build (if engine is working)..." -ForegroundColor Yellow
try {
    docker build -t docker-test . > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker Build: Success" -ForegroundColor Green
        
        Write-Host "`n6. Testing Docker Run..." -ForegroundColor Yellow
        docker run --rm docker-test > $null 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker Run: Success" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Docker Run: Failed" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️ Docker Build: Failed (engine not responding)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Docker Build: Error" -ForegroundColor Red
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "If Docker Engine is not responding:" -ForegroundColor Yellow
Write-Host "1. Restart Docker Desktop" -ForegroundColor White
Write-Host "2. Wait 30 seconds for full startup" -ForegroundColor White
Write-Host "3. Run this test again" -ForegroundColor White
