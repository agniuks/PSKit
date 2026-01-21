param(
    [string]$Branch = 'main',
    [string]$RepoBase = 'https://raw.githubusercontent.com/agniuks/PSKit'
)

# If not running in PowerShell 7+, try to relaunch in pwsh
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) {
        Write-Host "  Switching to PowerShell 7..." -ForegroundColor Yellow
        $scriptUrl = "$RepoBase/$Branch/install.ps1"
        & pwsh -NoProfile -Command "& { irm '$scriptUrl' | iex }"
        return
    } else {
        Write-Host ""
        Write-Host "PSKit Installer" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  FAIL: PSKit requires PowerShell 7+. Current: $($PSVersionTable.PSVersion)" -ForegroundColor Red
        Write-Host "  Install PowerShell 7: winget install Microsoft.PowerShell" -ForegroundColor Yellow
        Write-Host ""
        return
    }
}

$ErrorActionPreference = 'Stop'

$script:PSKitDataPath   = Join-Path $env:LOCALAPPDATA 'PSKit'
$script:PSKitThemesPath = Join-Path $script:PSKitDataPath 'themes'
$script:PSKitModulePath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules\PSKit'
$script:ThemeFileName   = 'pskit-simple.omp.json'
$script:ProfileMarker   = 'PSKit'

function Install-OhMyPosh {
    Write-Host "  Checking Oh My Posh..."
    $omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
    if ($omp) {
        Write-Host "  OK: Already installed" -ForegroundColor Green
        return $true
    }
    
    Write-Host "  Installing via winget..."
    winget install JanDeDobbeleer.OhMyPosh --accept-source-agreements --accept-package-agreements | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  FAIL: Could not install Oh My Posh" -ForegroundColor Red
        return $false
    }
    
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + 
                [Environment]::GetEnvironmentVariable('Path', 'User')
    
    Write-Host "  OK: Installed" -ForegroundColor Green
    return $true
}

function Install-PSKitModule {
    Write-Host "  Installing module..."
    
    if (Test-Path $script:PSKitModulePath) {
        Remove-Item $script:PSKitModulePath -Recurse -Force
    }
    New-Item -Path $script:PSKitModulePath -ItemType Directory -Force | Out-Null
    
    try {
        $baseUrl = "$RepoBase/$Branch/PSKit"
        @('PSKit.psd1', 'PSKit.psm1') | ForEach-Object {
            Invoke-RestMethod -Uri "$baseUrl/$_" -OutFile (Join-Path $script:PSKitModulePath $_)
        }
    } catch {
        Write-Host "  FAIL: Could not download module files" -ForegroundColor Red
        throw
    }
    
    Write-Host "  OK: Module installed" -ForegroundColor Green
}

function Install-PSKitTheme {
    Write-Host "  Installing theme..."
    
    if (-not (Test-Path $script:PSKitThemesPath)) {
        New-Item -Path $script:PSKitThemesPath -ItemType Directory -Force | Out-Null
    }
    
    try {
        $themeUrl = "$RepoBase/$Branch/themes/$script:ThemeFileName"
        Invoke-RestMethod -Uri $themeUrl -OutFile (Join-Path $script:PSKitThemesPath $script:ThemeFileName)
    } catch {
        Write-Host "  FAIL: Could not download theme" -ForegroundColor Red
        throw
    }
    
    Write-Host "  OK: Theme installed" -ForegroundColor Green
}

function Add-ProfileBlock {
    Write-Host "  Configuring profile..."
    
    $profilePath = $PROFILE.CurrentUserCurrentHost
    
    if (-not (Test-Path $profilePath)) {
        $profileDir = Split-Path $profilePath -Parent
        if (-not (Test-Path $profileDir)) {
            New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
        }
        New-Item -Path $profilePath -ItemType File -Force | Out-Null
    }
    
    $content = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
    if ($content -match "#region $script:ProfileMarker") {
        Write-Host "  OK: Already configured" -ForegroundColor Green
        return
    }
    
    $block = @"

#region $script:ProfileMarker - Managed by PSKit (do not edit manually)
Import-Module PSKit -ErrorAction SilentlyContinue
Initialize-PSKit
#endregion $script:ProfileMarker
"@
    
    Add-Content -Path $profilePath -Value $block -Encoding UTF8
    Write-Host "  OK: Profile configured" -ForegroundColor Green
}

Write-Host ""
Write-Host "PSKit Installer" -ForegroundColor Cyan
Write-Host ""
Write-Host "  OK: PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Green

if (-not (Install-OhMyPosh)) { return }
Install-PSKitModule
Install-PSKitTheme
Add-ProfileBlock

Write-Host ""
Write-Host "Done! Restart your terminal or run: . `$PROFILE" -ForegroundColor Green
Write-Host ""
