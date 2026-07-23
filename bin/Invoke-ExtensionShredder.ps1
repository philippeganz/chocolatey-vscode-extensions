#Requires -Version 7.0
#Requires -Module powershell-yaml
<#
.SYNOPSIS
    The Execution Engine for safely removing VS Code extensions from the pool.

.DESCRIPTION
    Reverse-lookups extension IDs, validates dependency trees to prevent orphaned packages,
    safely removes the target directories, and updates the state tracker config.

.PARAMETER ExtensionId
    An array of extension identifiers or package names to cleanly remove from the pool.

.PARAMETER Force
    Overrides dependency protection if the extension is required by another package.

.EXAMPLE
    .\Invoke-ExtensionShredder.ps1 -ExtensionId "ms-python.python"

.INPUTS
    [System.String[]]
    Accepts pipeline input for the ExtensionId parameter.

.OUTPUTS
    None

.NOTES
    This script is designed to be destructive. It wipes the package from the local filesystem
    and from the configuration tracker. Ensure you have run dependency validation before using -Force.
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is required for CI/CD logging and workflow orchestration')]
param (
    [Parameter(Mandatory = $true)]
    [string[]]$ExtensionId,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$ConfigFile = "$PSScriptRoot\..\var\state\config.yaml"
)

$ErrorActionPreference = 'Stop'

# =============================================================================
# Import Modules
# =============================================================================
Import-Module "$PSScriptRoot\..\lib\CoreHelpers.psm1" -ErrorAction Stop
Import-Module "$PSScriptRoot\..\lib\ConfigHelpers.psm1" -ErrorAction Stop

# =============================================================================
# 1. State Initialization
# =============================================================================
Write-Host ">>> Starting VS Code Extension Shredder" -ForegroundColor Cyan
Write-Host "    Target Configuration: $ConfigFile"
Write-Host "    Extensions to Process: $($ExtensionId.Count)"

$state = Get-ConfigState -ConfigPath $ConfigFile
$mutated = $false

# =============================================================================
# 2. Reverse Lookup & Pre-Processing
# =============================================================================
$removePackageNames = [System.Collections.Generic.List[string]]::new()
$removeIds = [System.Collections.Generic.List[string]]::new()

foreach ($id in $ExtensionId) {
    $cleanId = $id.ToLower()
    if (-not $cleanId.Contains('.')) {
        $matchedExtId = $null
        foreach ($trackedId in $state.Extensions) {
            if ((Get-ChocoPackageName $trackedId) -eq $cleanId) {
                $matchedExtId = $trackedId
                break
            }
        }
        if ($matchedExtId) {
            Write-Info "Reverse lookup resolved '$cleanId' to extension ID '$matchedExtId'."
            $cleanId = $matchedExtId
        }
    }
    $removeIds.Add($cleanId)
    $pkgName = Get-ChocoPackageName $cleanId
    if ($pkgName) { $removePackageNames.Add($pkgName) }
}

# =============================================================================
# 3. Dependency Validation & Shredding
# =============================================================================
foreach ($cleanId in $removeIds) {
    Write-Host "`n----------------------------------------" -ForegroundColor DarkGray
    Write-Host "Shredding: $cleanId" -ForegroundColor Cyan

    $pkgName = Get-ChocoPackageName $cleanId
    if ($pkgName) {
        $baseAuto = Get-AutomaticDirectory
        $pkgDir = Join-Path $baseAuto $pkgName

        # Dependency Validation
        $isDependency = $false
        $dependents = [System.Collections.Generic.List[string]]::new()

        $allNuspecs = Get-ChildItem -Path $baseAuto -Filter "*.nuspec" -Recurse
        foreach ($nuspec in $allNuspecs) {
            $nuspecPkgName = $nuspec.Directory.Name
            if ($removePackageNames.Contains($nuspecPkgName)) { continue }

            $xml = [System.Xml.XmlDocument]::new()
            $xml.Load($nuspec.FullName)

            $deps = $xml.package.metadata.dependencies.dependency
            if ($deps) {
                foreach ($dep in @($deps)) {
                    if ($dep.id -eq $pkgName) {
                        $isDependency = $true
                        $dependents.Add($nuspecPkgName)
                    }
                }
            }
        }

        if ($isDependency -and -not $Force) {
            Write-Err "Cannot safely remove '$cleanId'. It is declared as a dependency by: $($dependents -join ', ')."
            Write-Err "Use -Force to override this protection and remove it anyway."
            continue
        }
        elseif ($isDependency -and $Force) {
            Write-Warning "Overriding dependency protection! Removing '$cleanId' despite being required by: $($dependents -join ', ')."
        }

        if ($state.Extensions.Contains($cleanId)) {
            [void]$state.Extensions.Remove($cleanId)
            $mutated = $true
            Write-Success "Removed '$cleanId' from config.yaml tracking."
        }
        else {
            Write-Skip "'$cleanId' was not found in config.yaml."
        }

        if (Test-Path $pkgDir) {
            $sharedOwners = $state.Extensions | Where-Object { (Get-ChocoPackageName $_) -eq $pkgName }
            if ($sharedOwners.Count -gt 0) {
                Write-Warning "Skipping directory deletion for '$pkgName'. It is still owned by: $($sharedOwners -join ', ')."
            }
            else {
                Remove-Item -Path $pkgDir -Recurse -Force
                Write-Success "Deleted local package directory: $(Split-Path $baseAuto -Leaf)\$pkgName"
            }
        }
    }
}

if ($mutated) {
    Write-Host "`n>>> Finalizing and Syncing config.yaml..." -ForegroundColor Cyan
    Save-ConfigState -ConfigPath $ConfigFile -ExtensionsList $state.Extensions
}

Write-Host "`n>>> Shredder Run Complete!" -ForegroundColor Cyan


