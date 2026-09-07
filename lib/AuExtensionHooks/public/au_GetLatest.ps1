<#
.SYNOPSIS
    The Metadata Resolution hook for Chocolatey AU.

.DESCRIPTION
    Instead of scraping HTML, it cleanly polls the upstream VS Code Marketplace REST API
    to fetch the exact, authoritative payload metadata (Version, URL, hashes, shortDescription).
    It natively evaluates the required Engine/Host platform (like windows-x64, linux-x64) and
    targets the correct VSIX payload.

.EXAMPLE
    # This function is not meant to be called directly. It is invoked natively by AU.

.INPUTS
    None

.OUTPUTS
    [System.Management.Automation.PSCustomObject]
    Returns an AU-compatible state object representing the absolute latest upstream release.
#>
function global:au_GetLatest {
    [OutputType([System.Collections.Hashtable])]
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for AU Engine state')]
    param()

    if ($global:ExtensionVersion) {
        $ext = Get-VsCodeMarketplaceMetadata -Publisher $global:ExtensionPublisher -ExtensionName $global:ExtensionName -IncludeAllVersions
    }
    else {
        $ext = Get-VsCodeMarketplaceMetadata -Publisher $global:ExtensionPublisher -ExtensionName $global:ExtensionName
    }

    if ($global:ExtensionVersion) {
        $matchedVersion = $ext.versions | Where-Object { $_.version -eq $global:ExtensionVersion }
        if ($matchedVersion) {
            $ext.versions = @($matchedVersion)
            Write-Info "Moderation Override: Locking to version $($global:ExtensionVersion)" -Indent 1
        }
        else {
            Write-Warn "Target override version $($global:ExtensionVersion) not found on Marketplace!" -Indent 1
        }
    }

    $version = $ext.versions[0].version
    # Simple SemVer sanitization
    $version = $version -replace '[^\d\.-]', ''

    $vsixUrl = Get-VsCodeExtensionUrl -Publisher $global:ExtensionPublisher -ExtensionName $global:ExtensionName -Version $version -ExtMeta $ext
    $iconUrl = $ext.versions[0].files | Where-Object { $_.assetType -eq "Microsoft.VisualStudio.Services.Icons.Default" } | Select-Object -ExpandProperty source

    return @{
        Version            = $version
        URL32              = $vsixUrl
        URL64              = $vsixUrl
        MarketplaceIconUrl = $iconUrl
        RawMeta            = $ext
        Options            = @{
            NoCheckUrl          = $true
            NoCheckRegistry     = $true
            NoCheckChocoVersion = $true
        }
    }
}
