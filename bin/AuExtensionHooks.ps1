#Requires -Version 7.0
#Requires -Module au

<#
.SYNOPSIS
    The centralized Logic Engine for Chocolatey AU packages.

.DESCRIPTION
    Instead of maintaining massive 100-line update.ps1 scripts in every package folder,
    all packages use a tiny 3-line stub that dot-sources this file. This script injects
    the global AU hooks (au_GetLatest, au_BeforeUpdate) into the runtime context so AU
    knows how to update the package.

.EXAMPLE
    . $PSScriptRoot\..\..\bin\AuExtensionHooks.ps1
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is required for CI/CD logging and workflow orchestration')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Global variables are required for AU configuration and workflow state')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Preference variable used by the PowerShell engine')]
param()

# =============================================================================
# Global Error Handling
# =============================================================================
# Enforce strict fail-fast behavior across this entire script/module.
# Any cmdlet or module import failure will immediately throw a terminating error.
# Override locally with -ErrorAction SilentlyContinue when needed.
$ErrorActionPreference = 'Stop'

# =============================================================================
# Import Modules
# =============================================================================
Import-Module au
Import-Module "$PSScriptRoot\..\lib\VsCodeMarketplace.psm1" -Global

# We bypass the registry checks since these are portable VS Code extensions.
# Push settings are natively inherited from the global orchestrator.
$global:au_NoCheckRegistry = $true

# WARNING: The Chocolatey AU module relies on legacy PowerShell 5.1 native command argument parsing.
# When pushing packages, AU evaluates empty string flags ($force_push = ''). In PowerShell 7,
# empty strings are explicitly passed to choco.exe, causing choco to misinterpret the empty string
# as an invalid 'filePath' parameter. Reverting to Legacy argument passing inside the hook script
# ensures that every Start-Job worker process inherits this fix.
$global:PSNativeCommandArgumentPassing = 'Legacy'


<#
.SYNOPSIS
    The Metadata Resolver hook for Chocolatey AU.

.DESCRIPTION
    AU executes this function on a schedule. It sends a REST API POST request to the
    Visual Studio Code Marketplace to natively query the absolute latest version
    of the extension, resolving icon URLs and download paths dynamically.

    This function intercepts the normal version check and injects the proper upstream
    version into AU's internal state mechanism.

.EXAMPLE
    # This function is not meant to be called directly. It is invoked natively by AU:
    Update-Package -ChecksumFor none

.INPUTS
    None

.OUTPUTS
    [System.Collections.Hashtable]
    Returns a hashtable containing the parsed Version, download URLs (URL32, URL64),
    IconUrl, and the raw metadata object (RawMeta) for injection into downstream hooks.

.NOTES
    This relies on the `VsCodeMarketplace` module for robust rate-limit handling.
    If `$global:ExtensionVersion` is defined, it forces moderation overrides.
#>
function global:au_GetLatest {
    if ($global:ExtensionVersion) {
        $ext = Get-VsCodeMarketplaceMetadata -Publisher $ExtensionPublisher -ExtensionName $ExtensionName -IncludeAllVersions
    }
    else {
        $ext = Get-VsCodeMarketplaceMetadata -Publisher $ExtensionPublisher -ExtensionName $ExtensionName
    }

    if ($global:ExtensionVersion) {
        $matchedVersion = $ext.versions | Where-Object { $_.version -eq $global:ExtensionVersion }
        if ($matchedVersion) {
            $ext.versions = @($matchedVersion)
            Write-Host "    [INFO] Moderation Override: Locking to version $($global:ExtensionVersion)" -ForegroundColor Cyan
        }
        else {
            Write-Host "    [WARNING] Target override version $($global:ExtensionVersion) not found on Marketplace!" -ForegroundColor Yellow
        }
    }

    $version = $ext.versions[0].version
    # Simple SemVer sanitization
    $version = $version -replace '[^\d\.-]', ''

    $vsixUrl = Get-VsCodeExtensionUrl -Publisher $ExtensionPublisher -ExtensionName $ExtensionName -Version $version -ExtMeta $ext
    $iconUrl = $ext.versions[0].files | Where-Object { $_.assetType -eq "Microsoft.VisualStudio.Services.Icons.Default" } | Select-Object -ExpandProperty source

    return @{
        Version            = $version
        URL32              = $vsixUrl
        URL64              = $vsixUrl
        MarketplaceIconUrl = $iconUrl
        RawMeta            = $ext
    }
}

<#
.SYNOPSIS
    The Payload Downloader hook for Chocolatey AU.

.DESCRIPTION
    If AU detects that the version returned by au_GetLatest is newer than the
    current package (or is forced), it triggers this hook. This downloads the actual
    VSIX binary, extracts the metadata and LICENSE, dynamically injects dependencies,
    and algorithmically truncates the README to update the nuspec.

    This function is strictly responsible for fulfilling the Air-Gap mandate by
    physically embedding the upstream .vsix payload into the package directory.

.PARAMETER package
    The AU package object representing the current context, containing properties like
    Path, Name, and NuspecXml.

.EXAMPLE
    # This function is not meant to be called directly. It is invoked natively by AU.

.INPUTS
    [System.Management.Automation.PSCustomObject]

.OUTPUTS
    None

.NOTES
    It utilizes the `$Latest` global variable injected by AU to access metadata returned
    by `au_GetLatest`.
#>
function global:au_BeforeUpdate {
    param($package)

    # =========================================================================
    # Step 1. Pre-Load CI Dependencies
    # =========================================================================
    # Intelligent CI Bootstrapper: Only install VS Code test dependencies if an update is actively happening
    if (-not (Get-Command code -ErrorAction SilentlyContinue) -and -not $script:VsCodeDependenciesLoaded) {
        Write-Host ">>> Pre-loading Test Dependencies for CI Environment..." -ForegroundColor Cyan
        choco install vscode chocolatey-vscode.extension -y --no-progress
        $script:VsCodeDependenciesLoaded = $true
    }

    $toolsDir = Join-Path $package.Path 'tools'
    if (-not (Test-Path $toolsDir)) { [void](New-Item -ItemType Directory -Path $toolsDir) }

    $vsixPath = Join-Path $toolsDir "$ExtensionPublisher.$ExtensionName-$($Latest.Version).vsix"

    # =========================================================================
    # Step 2. Download and Verify Payload (Air-Gap Mandate)
    # =========================================================================
    # Purge any old VSIX payloads to prevent package bloat
    Get-ChildItem -Path $toolsDir -Filter "*.vsix" | Remove-Item -Force

    # Download the new upstream VSIX payload directly into the tools folder
    Invoke-RobustDownload -Url $Latest.URL64 -OutFile $vsixPath

    # Compute checksums and generate the VERIFICATION.txt file required by Chocolatey
    New-VerificationFile -VsixPath $vsixPath -PackageDir $package.Path -Publisher $ExtensionPublisher -ExtensionName $ExtensionName

    # =========================================================================
    # Step 3. Extract Payload Metadata
    # =========================================================================
    # Automatically rip the newest README.md, LICENSE, and package.json from the ZIP payload
    # so AU can natively inject the updated documentation into the Chocolatey package.
    $payloadResult = Expand-VsCodePayload -VsixPath $vsixPath -DestinationDir $package.Path

    # =========================================================================
    # Step 4. Update In-Memory String (Pre-DOM)
    # =========================================================================
    # Update the raw text template with Title, Authors, Summary, etc. via regex
    # before converting to a native XML DOM object.
    $nuspecPath = Join-Path $package.Path "$($package.Name).nuspec"
    $nuspecContent = Get-Content $nuspecPath -Raw -Encoding UTF8
    $meta = Get-VsCodeNuspecMetadata -ExtMeta $Latest.RawMeta -ExtensionPublisher $ExtensionPublisher -ExtensionName $ExtensionName
    $nuspecContent = Update-VsCodeNuspecMetadata -NuspecContent $nuspecContent -Meta $meta
    $package.NuspecXml = [xml]$nuspecContent

    # =========================================================================
    # Step 5. Update XML DOM (AU State) & Physical Templates
    # =========================================================================
    # We must inject the CDataSafeReadme natively as a pure CDataSection
    # so that PowerShell's XML parser doesn't incorrectly escape the payload when saving.
    Update-NuspecCDataDescription -NuspecXml $package.NuspecXml -CDataSafeReadme $payloadResult.CDataSafeReadme -ShortDescription $Latest.RawMeta.shortDescription

    # Dynamically discover missing dependencies (e.g. extension packs) and auto-queue them to the Factory
    $configPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\var\state\config.yaml"))
    Update-NuspecDependency -NuspecXml $package.NuspecXml -PackageJson $payloadResult.PackageJson -ConfigPath $configPath

    Save-NuspecXml -NuspecXml $package.NuspecXml -NuspecPath $nuspecPath

    # =========================================================================
    # Step 6. Validate Required Assets
    # =========================================================================
    # Guarantee icon.png exists to prevent choco pack validation failures (every nuspec includes icon.png in <files>)
    Save-VsCodeIcon -IconUrl $Latest.MarketplaceIconUrl -PackageDir $package.Path -PackageName $package.Name
}

<#
.SYNOPSIS
    The String Replacer hook for Chocolatey AU.

.DESCRIPTION
    AU executes this function to natively update the hardcoded version strings
    inside our runtime scripts (like chocolateyInstall.ps1) so the new binaries are properly targeted.

    It constructs a dictionary of RegEx rules that AU applies directly to the file paths
    specified in the dictionary keys.

.EXAMPLE
    # This function is not meant to be called directly. It is invoked natively by AU.

.INPUTS
    None

.OUTPUTS
    [System.Collections.Hashtable]
    Returns a hashtable mapping file paths to their respective RegEx replacement rules.
#>
function global:au_SearchReplace {
    $targetIconUrl = "https://cdn.jsdelivr.net/gh/philippeganz/chocolatey-vscode-extensions@main/automatic/vscode-$ExtensionName/icon.png"

    $rules = @{
        "tools\chocolateyInstall.ps1" = @{
            "(?i)($ExtensionPublisher\.$ExtensionName-)[\d\.]+(\.vsix)" = "`${1}$($Latest.Version)`${2}"
        }
        "*.nuspec"                    = @{
            "(?is)<iconUrl>.*?</iconUrl>" = "<iconUrl>$targetIconUrl</iconUrl>"
        }
    }

    return $rules
}

Update-Package -ChecksumFor none
