<#
.SYNOPSIS
    Constructs the direct VSIX payload download URL, handling platform-specific ambiguities.

.DESCRIPTION
    The Marketplace often hosts OS-specific precompiled binaries for heavy extensions (like C# or Go).
    This helper inspects the raw Marketplace Metadata and explicitly targets the `win32-x64` VSIX payload
    if the extension is platform-dependent, falling back to the universal payload otherwise.

.PARAMETER Publisher
    The canonical publisher name.

.PARAMETER ExtensionName
    The canonical extension name.

.PARAMETER Version
    The exact version string of the extension to download (e.g. '1.0.0').

.PARAMETER ExtMeta
    The raw JSON metadata payload retrieved from Get-VsCodeMarketplaceMetadata.

.EXAMPLE
    $url = Get-VsCodeExtensionUrl -Publisher "ms-python" -ExtensionName "python" -Version "1.0.0" -ExtMeta $extMeta

.INPUTS
    None

.OUTPUTS
    [System.String]
    The absolute download URL for the target .vsix payload.

.NOTES
    This is required to bypass Chocolatey moderation rejections caused by downloading
    Linux/Mac binaries on Windows environments.
#>
function Get-VsCodeExtensionUrl {
    param (
        [Parameter(Mandatory = $true)][string]$Publisher,
        [Parameter(Mandatory = $true)][string]$ExtensionName,
        [Parameter(Mandatory = $true)][string]$Version,
        [Parameter(Mandatory = $true)][object]$ExtMeta
    )

    $vsixUrl = "$script:MarketplaceBaseUrl/_apis/public/gallery/publishers/$Publisher/vsextensions/$ExtensionName/$Version/vspackage"

    # Dynamic Platform Detection: Explicitly request the Windows binary if the extension is OS-specific
    $isPlatformSpecific = $ExtMeta.versions | Where-Object { $_.version -eq $ExtMeta.versions[0].version -and $_.targetPlatform -eq "win32-x64" }
    if ($isPlatformSpecific) {
        Write-Cyan "    [INFO] Platform-specific extension detected. Targeting win32-x64 binary."
        $vsixUrl = "$($vsixUrl)?targetPlatform=win32-x64"
    }

    return $vsixUrl
}
