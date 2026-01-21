#Requires -Version 7.0

param(
    [switch]$RemoveData,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$script:PSKitDataPath   = Join-Path $env:LOCALAPPDATA 'PSKit'
$script:PSKitModulePath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules\PSKit'
$script:ProfileMarker   = 'PSKit'

function Remove-ProfileBlock {
    $profilePath = $PROFILE.CurrentUserCurrentHost
    if (-not (Test-Path $profilePath)) { return $false }
    
    $content = Get-Content $profilePath -Raw
    if (-not $content) { return $false }
    
    $pattern = "(?ms)\r?\n?#region $script:ProfileMarker.*?#endregion $script:ProfileMarker\r?\n?"
    if ($content -match $pattern) {
        $newContent = $content -replace $pattern, ''
        Set-Content -Path $profilePath -Value $newContent.TrimEnd() -Encoding UTF8
        return $true
    }
    return $false
}

Write-Host ""
Write-Host "PSKit Uninstaller" -ForegroundColor Yellow
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "Remove PSKit? (y/N)"
    if ($confirm -notmatch '^[Yy]') {
        Write-Host "Cancelled."
        return
    }
    Write-Host ""
}

if (Remove-ProfileBlock) {
    Write-Host "  Removed profile block" -ForegroundColor Green
} else {
    Write-Host "  No profile block found"
}

if (Test-Path $script:PSKitModulePath) {
    Remove-Item $script:PSKitModulePath -Recurse -Force
    Write-Host "  Removed module" -ForegroundColor Green
} else {
    Write-Host "  Module not found"
}

if ($RemoveData) {
    if (Test-Path $script:PSKitDataPath) {
        Remove-Item $script:PSKitDataPath -Recurse -Force
        Write-Host "  Removed data folder" -ForegroundColor Green
    } else {
        Write-Host "  Data folder not found"
    }
} else {
    Write-Host "  Theme files kept at: $script:PSKitDataPath (use -RemoveData to delete)"
}

Write-Host ""
Write-Host "Done! Restart your terminal." -ForegroundColor Green
Write-Host ""
