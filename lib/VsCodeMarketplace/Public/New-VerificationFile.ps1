<#
.SYNOPSIS
    Generates the legal/VERIFICATION.txt file for a VS Code extension package.

.DESCRIPTION
    Fulfills the Chocolatey moderation requirement for embedded binaries by computing the
    SHA256 hash of the downloaded payload and providing clear verification instructions
    and license links for the moderators.

.PARAMETER VsixPath
    The absolute path to the locally downloaded .vsix payload.

.PARAMETER PackageDir
    The absolute path to the root of the package directory (where 'legal' will be created).

.PARAMETER Publisher
    The canonical publisher name.

.PARAMETER ExtensionName
    The canonical extension name.

.EXAMPLE
    New-VerificationFile
#>
function New-VerificationFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)][string]$VsixPath,
        [Parameter(Mandatory = $true)][string]$PackageDir,
        [Parameter(Mandatory = $true)][string]$Publisher,
        [Parameter(Mandatory = $true)][string]$ExtensionName
    )

    $legalDir = Join-Path $PackageDir "legal"

    if ($PSCmdlet.ShouldProcess((Join-Path $legalDir "VERIFICATION.txt"), "Create VERIFICATION.txt file")) {
        if (-not (Test-Path $legalDir)) { [void](New-Item -ItemType Directory -Force -Path $legalDir) }

        $hash = (Get-FileHash -Path $VsixPath -Algorithm SHA256).Hash
        $marketplaceUrl = "$script:MarketplaceBaseUrl/items?itemName=$Publisher.$ExtensionName"
        $licenseUrl = "$script:MarketplaceBaseUrl/items/$Publisher.$ExtensionName/license"
        $vsixName = Split-Path $VsixPath -Leaf

        $verificationContent = @"
1. Download the official extension binary directly from the VS Code Marketplace:
   Marketplace URL: $marketplaceUrl
   (Navigate to 'Version History' and download the exact version, or use the direct download API)

2. Run the following PowerShell command to compute its hash:
   Get-FileHash -Algorithm SHA256 -Path .\$vsixName

3. Compare that hash to the one embedded in this package. They should match exactly:
   Expected SHA256: $hash

---
SOFTWARE LICENSE:
The software license can be found at:
$licenseUrl
"@
        $verificationContent = $verificationContent.Replace("`r`n", "`n")
        [System.IO.File]::WriteAllText((Join-Path $legalDir "VERIFICATION.txt"), $verificationContent, [System.Text.UTF8Encoding]::new($false))
    }
}
