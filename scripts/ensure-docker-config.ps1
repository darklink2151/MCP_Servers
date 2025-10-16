# ensure-docker-config.ps1 – Creates/updates %USERPROFILE%\.docker\config.json with BuildKit GC settings

param(
    [string]$KeepStorage = "20GB",
    [switch]$DisableExperimental
)

$target = Join-Path $HOME ".docker\config.json"
$desired = @{
    builder = @{
        gc = @{
            enabled = $true
            defaultKeepStorage = $KeepStorage
        }
    }
    experimental = -not $DisableExperimental.IsPresent
}

# Ensure directory exists
$targetDir = Split-Path $target -Parent
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

if (Test-Path $target) {
    try {
        $existing = Get-Content $target -Raw | ConvertFrom-Json -AsHashtable -ErrorAction Stop
    } catch {
        Write-Warning "Existing config.json is not valid JSON – backing up and creating new one."
        Copy-Item $target "$target.bak" -Force
        $existing = @{}
    }
    if (-not $existing) { $existing = @{} }
    foreach ($key in $desired.Keys) {
        $existing[$key] = $desired[$key]
    }
    $existing | ConvertTo-Json -Depth 4 | Set-Content $target -Encoding UTF8
    Write-Host "Updated Docker config -> $target" -ForegroundColor Green
} else {
    $desired | Set-Content $target -Encoding UTF8
    Write-Host "Created Docker config -> $target" -ForegroundColor Green
}
