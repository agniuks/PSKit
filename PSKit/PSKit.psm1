#Requires -Version 7.0

# Configuration
$script:PSKitDataPath   = Join-Path $env:LOCALAPPDATA 'PSKit'
$script:PSKitThemesPath = Join-Path $script:PSKitDataPath 'themes'
$script:ThemeFileName   = 'pskit-simple.omp.json'
$script:ProfileMarker   = 'PSKit'

function Get-PSKitThemePath {
    Join-Path $script:PSKitThemesPath $script:ThemeFileName
}

function Test-OhMyPoshInstalled {
    $null -ne (Get-Command oh-my-posh -ErrorAction SilentlyContinue)
}

function Remove-ProfileBlock {
    $profilePath = $PROFILE.CurrentUserCurrentHost
    if (-not (Test-Path $profilePath)) { return $false }
    
    $content = Get-Content $profilePath -Raw
    if (-not $content) { return $false }
    
    $pattern = "(?m)\r?\n?#region $script:ProfileMarker.*?#endregion $script:ProfileMarker\r?\n?"
    if ($content -match $pattern) {
        $newContent = $content -replace $pattern, ''
        Set-Content -Path $profilePath -Value $newContent.TrimEnd() -Encoding UTF8
        return $true
    }
    return $false
}

function Initialize-PSKit {
    # Initialize Oh My Posh
    $themePath = Get-PSKitThemePath
    if ((Test-OhMyPoshInstalled) -and (Test-Path $themePath)) {
        oh-my-posh init pwsh --config $themePath | Invoke-Expression
    }
}

function Get-PSKitStatus {
    $themePath = Get-PSKitThemePath
    $profilePath = $PROFILE.CurrentUserCurrentHost
    $profileHasBlock = $false
    
    if (Test-Path $profilePath) {
        $content = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
        $profileHasBlock = $content -match "#region $script:ProfileMarker"
    }
    
    $status = [PSCustomObject]@{
        PSVersion         = $PSVersionTable.PSVersion.ToString()
        OhMyPoshInstalled = Test-OhMyPoshInstalled
        ThemePath         = $themePath
        ThemeInstalled    = Test-Path $themePath
        ProfileConfigured = $profileHasBlock
    }
    
    Write-Host ""
    Write-Host "PSKit Status" -ForegroundColor Cyan
    Write-Host "  PowerShell: $($status.PSVersion)"
    Write-Host "  Oh My Posh: $(if($status.OhMyPoshInstalled){'Installed'}else{'Not found'})"
    Write-Host "  Theme: $(if($status.ThemeInstalled){'Installed'}else{'Not found'})"
    Write-Host "  Profile: $(if($status.ProfileConfigured){'Configured'}else{'Not configured'})"
    Write-Host ""
    
    return $status
}

function Uninstall-PSKit {
    param(
        [switch]$RemoveData,
        [switch]$Force
    )
    
    $modulePath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules\PSKit'
    
    Write-Host ""
    Write-Host "PSKit Uninstaller" -ForegroundColor Yellow
    
    if (-not $Force) {
        $confirm = Read-Host "Remove PSKit? (y/N)"
        if ($confirm -notmatch '^[Yy]') {
            Write-Host "Cancelled."
            return
        }
    }
    
    if (Remove-ProfileBlock) {
        Write-Host "  Removed profile block" -ForegroundColor Green
    } else {
        Write-Host "  No profile block found"
    }
    
    if (Test-Path $modulePath) {
        Remove-Item $modulePath -Recurse -Force
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
}

Export-ModuleMember -Function Initialize-PSKit, Get-PSKitStatus, Uninstall-PSKit
