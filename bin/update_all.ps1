[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
param(
    [string]$ForcedPackages = '',
    [string]$PushUrl = '',
    [string]$ModerationRepush = '',
    [string]$OutputDir = ''
)

$ErrorActionPreference = 'Stop'

# -----------------------------------------------------------------------------
# AU ORCHESTRATOR CONFIGURATION
# -----------------------------------------------------------------------------
# The Chocolatey AU Engine evaluates parameters from the $global scope before it
# falls back to its Options dictionary. Due to a known parsing bug with the 'Force'
# parameter in Update-AUPackages, we explicitly inject our configurations globally.
#
# $global:au_Push = $true -> Ensures the package is uploaded to the Community Gallery
# $global:au_Force = $false -> Default state. When $true, it bypasses internal version math and forces AU to rebuild the package even if versions match.
# $global:au_NoCheckRegistry = $true -> Prevents Test-Package from scanning the Windows Registry (Add/Remove Programs) since VS Code extensions don't write to it.
# -----------------------------------------------------------------------------
$global:au_Push = $true
$global:au_Force = $false
$global:au_NoCheckRegistry = $true

if ($PushUrl) {
    $global:au_PushUrl = $PushUrl
    Write-Host ">>> Retargeting AU Push to Internal Repository: $PushUrl" -ForegroundColor Magenta
}

if ($ForcedPackages) {
    # Bypasses the internal math that aborts updates when local and remote versions match.
    $global:au_Force = $true
}

if ($OutputDir) {
    Write-Host ">>> Output Directory specified: $OutputDir (Disabling native AU Push)" -ForegroundColor Magenta
    $global:au_Push = $false
}

$opts = [ordered]@{
    Push  = if ($OutputDir) { $false } else { $true }
    Force = if ($ForcedPackages) { $true } else { $false }
}

# Resolve the path to the 'automatic' directory where packages live
$packagesDir = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "..\automatic"
if (-not (Test-Path $packagesDir)) {
    throw "Automatic packages directory not found: $packagesDir"
}

Push-Location $packagesDir

if ($ModerationRepush) {
    Write-Host "`n>>> Initiating Moderation Repush Bypass..." -ForegroundColor Magenta
    foreach ($pkg in ($ModerationRepush -split ',')) {
        $pkgDir = Join-Path $packagesDir $pkg
        if (-not (Test-Path $pkgDir)) { Write-Host "    [ERROR] Not found: $pkg" -ForegroundColor Red; continue }

        Push-Location $pkgDir
        Write-Host "    Processing $pkg" -ForegroundColor Cyan

        # 1. Scrape exact upstream version from Marketplace using local update.ps1
        . .\update.ps1
        $latestMeta = au_GetLatest
        $upstreamVersion = $latestMeta.Version
        Write-Host "    Target Upstream Version: $upstreamVersion"

        # 2. Hardcode the exact version into the .nuspec
        $nuspecPath = Join-Path $pkgDir "$pkg.nuspec"
        $nuspec = [xml](Get-Content $nuspecPath)
        $nuspec.package.metadata.version = $upstreamVersion

        if (Test-Path "README.md") {
            $readmeData = Get-Content "README.md" -Raw
            $descNode = $nuspec.SelectSingleNode("//*[local-name()='description']")
            if ($descNode) {
                $descNode.RemoveAll()
                $cdata = $nuspec.CreateCDataSection($readmeData)
                $descNode.AppendChild($cdata) | Out-Null
            }
        }

        $nuspec.Save($nuspecPath)

        # 3. Download the VSIX payload
        $global:Latest = $latestMeta
        au_BeforeUpdate -package @{ Path = $pkgDir }

        # 4. Pack and Push natively to bypass AU's timestamp logic
        Write-Host "    Compiling Payload..."
        choco pack

        if ($env:api_key) {
            Write-Host "    Pushing to Chocolatey Moderation Queue..."
            choco push "$pkg.$upstreamVersion.nupkg" --source https://push.chocolatey.org --key $env:api_key --force
        } else {
            Write-Host "    [WARNING] No api_key found in environment. Skipping push." -ForegroundColor Yellow
        }

        Pop-Location
    }
    Pop-Location
    Write-Host "`n>>> Moderation Repush Complete!" -ForegroundColor Green
    exit 0
}

try {
    if ($ForcedPackages) {
        Update-AUPackages -Name $ForcedPackages -Options $opts
    }
    else {
        Update-AUPackages -Options $opts
    }
}
finally {
    Pop-Location
    
    if ($OutputDir) {
        Write-Host "`n>>> Consolidating compiled .nupkg artifacts into Output Directory: $OutputDir" -ForegroundColor Cyan
        if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
        $payloads = Get-ChildItem -Path $packagesDir -Filter "*.nupkg" -Recurse
        if ($payloads) {
            $payloads | Move-Item -Destination $OutputDir -Force
            Write-Host "    Successfully moved $($payloads.Count) packages to $OutputDir" -ForegroundColor Green
        } else {
            Write-Host "    No compiled packages found to move." -ForegroundColor Yellow
        }
    }
}
