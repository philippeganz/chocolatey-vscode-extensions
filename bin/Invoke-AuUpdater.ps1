#Requires -Version 7.0
<#
.SYNOPSIS
    The core Orchestrator for the Chocolatey Automatic Updater (AU) Engine.

.DESCRIPTION
    This script is executed by the GitHub Actions CI/CD pipeline on a cron schedule.
    It iterates over all packages in the automatic/ directory, triggers their update
    hooks, and determines if new versions need to be compiled and published to the
    Chocolatey Community Repository.

.PARAMETER ForcedPackages
    A comma-separated string of package names to force-update, bypassing the native
    version-matching math. Useful for emergency hotfixes.

.PARAMETER PushUrl
    Override the default Chocolatey Community push endpoint with a custom NuGet repository URL.

.PARAMETER ModerationRepush
    A comma-separated string of package names (or '*' for all) to rebuild and push without
    running the standard AU pipeline. Useful for pushing to the moderation queue.

.PARAMETER OutputDir
    An absolute path where compiled `.nupkg` artifacts should be moved instead of pushing
    them to a live repository. Disables automated push.

.EXAMPLE
    .\Invoke-AuUpdater.ps1

.EXAMPLE
    .\Invoke-AuUpdater.ps1 -ForcedPackages "vscode-python,vscode-docker" -OutputDir "C:\artifacts"
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification='Global variables are required for AU configuration and workflow state')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification='Write-Host is required for CI/CD logging and workflow orchestration')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='Preference variable used by the PowerShell engine')]
param(
    [string]$ForcedPackages = '',
    [string]$PushUrl = '',
    [string]$ModerationRepush = '',
    [string]$OutputDir = ''
)

# WARNING: The Chocolatey AU module relies on legacy PowerShell 5.1 native command argument parsing.
# When pushing packages, AU evaluates empty string flags ($force_push = ''). In PowerShell 7,
# empty strings are explicitly passed to choco.exe, causing choco to misinterpret the empty string
# as an invalid 'filePath' parameter. Reverting to Legacy argument passing resolves this.
$PSNativeCommandArgumentPassing = 'Legacy'

$ErrorActionPreference = 'Stop'
Import-Module "$PSScriptRoot\..\lib\VsCodeMarketplace.psm1" -Global -Force

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


$packagesDir = if ($env:CHOCO_VSCODE_AUTOMATIC_DIR) { $env:CHOCO_VSCODE_AUTOMATIC_DIR } else { "$PSScriptRoot\..\automatic" }

if (-not (Test-Path $packagesDir)) {
    throw "Configured packages directory not found: $packagesDir"
}

Push-Location $packagesDir

<#
.SYNOPSIS
A dependency graph resolver for ordered building.

.DESCRIPTION
Ensures that if Package A depends on Package B, Package B is strictly built
and tested FIRST, preventing Chocolatey AU from failing local dependency checks.

.PARAMETER Packages
An array of package names to resolve.

.OUTPUTS
An ordered array of package names optimized for dependency-first execution.
#>
function Resolve-PackageDependency {
    param([string[]]$Packages)

    $graph = @{}
    foreach ($pkg in $Packages) {
        $graph[$pkg] = @()
        $nuspec = Get-ChildItem "$packagesDir\$pkg\*.nuspec" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($nuspec) {
            $xml = [xml](Get-Content $nuspec.FullName -Encoding UTF8)
            $deps = $xml.package.metadata.dependencies.dependency
            if ($deps) {
                foreach ($dep in $deps) {
                    if ($Packages -contains $dep.id) {
                        $graph[$pkg] += [string]$dep.id
                    }
                }
            }
        }
    }

    $sortedList = [System.Collections.Generic.List[string]]::new()
    $visited = @{}
    $tempMark = @{}

    <#
    .SYNOPSIS
    Recursive DFS helper function for Topological Sort.

    .PARAMETER node
    The current node/package being visited in the graph.
    #>
    function Visit($node) {
        if ($tempMark[$node]) { return } # Cycle detected, gracefully break
        if (-not $visited[$node]) {
            $tempMark[$node] = $true
            foreach ($dep in $graph[$node]) {
                Visit $dep
            }
            $tempMark[$node] = $false
            $visited[$node] = $true
            $sortedList.Add($node)
        }
    }

    foreach ($pkg in $Packages) {
        Visit $pkg
    }

    return $sortedList.ToArray()
}


if ($ModerationRepush) {
    Write-Host "`n>>> Initiating Moderation Repush Bypass..." -ForegroundColor Magenta

    $versionOverrides = @{}
    $rawPackages = if ($ModerationRepush -eq '*') {
        Get-ChildItem $packagesDir -Directory | Select-Object -ExpandProperty Name
    }
    else {
        $ModerationRepush -split ',' | Where-Object { $_.Trim() -ne '' } | ForEach-Object { $_.Trim() }
    }

    $targetPackages = @()
    foreach ($pkgRaw in $rawPackages) {
        $pkgId = $pkgRaw
        if ($pkgRaw -match '@') {
            $parts = $pkgRaw -split '@'
            $pkgId = $parts[0]
            $versionOverrides[$pkgId] = $parts[1]
        }
        $targetPackages += $pkgId
    }

    $targetPackages = Resolve-PackageDependency -Packages $targetPackages


    foreach ($pkg in $targetPackages) {
        $pkgDir = Join-Path $packagesDir $pkg
        if (-not (Test-Path $pkgDir)) { Write-Host "    [ERROR] Not found: $pkg" -ForegroundColor Red; continue }

        Push-Location $pkgDir
        Write-Host "    Processing $pkg" -ForegroundColor Cyan

        if ($versionOverrides.ContainsKey($pkg)) {
            $global:ExtensionVersion = $versionOverrides[$pkg]
        } else {
            $global:ExtensionVersion = $null
        }

        # 1. Scrape exact upstream version from Marketplace using local update.ps1
        . .\update.ps1
        $latestMeta = au_GetLatest
        $upstreamVersion = $latestMeta.Version
        Write-Host "    Target Upstream Version: $upstreamVersion"

        # 2. Download the VSIX payload and extract fresh documentation FIRST
        $global:Latest = $latestMeta
        au_BeforeUpdate -package @{ Path = $pkgDir; Name = $pkg }

        # 3. Hardcode the exact version into the .nuspec
        $nuspecPath = Join-Path $pkgDir "$pkg.nuspec"
        $nuspec = [xml](Get-Content $nuspecPath -Encoding UTF8)
        $nuspec.package.metadata.version = $upstreamVersion

        $nuspec.Save($nuspecPath)

        # 4. Pack and Push natively to bypass AU's timestamp logic
        Write-Host "    Compiling Payload..."
        choco pack

        if ($OutputDir) {
            Write-Host "    >>> Output Directory specified. Moving payload to $OutputDir..." -ForegroundColor Cyan
            if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
            Move-Item "$pkg.$upstreamVersion.nupkg" -Destination $OutputDir -Force
        }
        elseif ($env:api_key) {
            Write-Host "    Pushing to Chocolatey Moderation Queue..."
            choco push "$pkg.$upstreamVersion.nupkg" --source https://push.chocolatey.org --key $env:api_key --force
        }
        else {
            Write-Host "    [WARNING] No api_key found in environment. Skipping push." -ForegroundColor Yellow
        }

        Pop-Location
    }
    Pop-Location
    Write-Host "`n>>> Moderation Repush / Manual Build Complete!" -ForegroundColor Green
    exit 0
}

try {
    if ($ForcedPackages) {
        $targetPackages = Resolve-PackageDependency -Packages ($ForcedPackages -split ',')
        Update-AUPackages -Name $targetPackages -Options $opts
    }
    else {
        $allPackages = Get-ChildItem $packagesDir -Directory | Select-Object -ExpandProperty Name
        $sortedPackages = Resolve-PackageDependency -Packages $allPackages
        Update-AUPackages -Name $sortedPackages -Options $opts
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
        }
        else {
            Write-Host "    No compiled packages found to move." -ForegroundColor Yellow
        }
    }
}

if ($global:au_RequiresSecondRun) {
    Write-Host "
>>> [AUTO-DISCOVERY] New dependencies were scaffolded! Triggering secondary AU run to package them..." -ForegroundColor Magenta
    $global:au_RequiresSecondRun = $false
    & $MyInvocation.MyCommand.Path -ForcedPackages $ForcedPackages -PushUrl $PushUrl -ModerationRepush $ModerationRepush -OutputDir $OutputDir
}
