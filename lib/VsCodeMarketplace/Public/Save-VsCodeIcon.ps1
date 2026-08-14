<#
.SYNOPSIS
    Downloads and guarantees an icon.png file for the package.

.DESCRIPTION
    Chocolatey highly recommends an icon.png file inside the package folder.
    This function downloads the icon from the VS Code Marketplace URL.
    If the download fails or the icon doesn't exist, it generates a 1x1 transparent
    dummy base64 PNG to prevent packaging schema errors.

.PARAMETER IconUrl
    The URL of the icon to download. Can be null if the marketplace has no icon.

.PARAMETER PackageDir
    The absolute path to the package directory where icon.png will be saved.

.PARAMETER PackageName
    The name of the package (used for logging warnings).

.EXAMPLE
    Save-VsCodeIcon -IconUrl "https://cdn.example.com/icon.png" -PackageDir "C:\temp\pkg" -PackageName "vscode-test"

.INPUTS
    None

.OUTPUTS
    None
#>
function Save-VsCodeIcon {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Internal utility for downloading files')]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$IconUrl,
        [Parameter(Mandatory = $true)][string]$PackageDir,
        [Parameter(Mandatory = $true)][string]$PackageName
    )

    $localIconPath = Join-Path $PackageDir "icon.png"
    if (-not (Test-Path $localIconPath)) {
        if ($IconUrl) {
            try {
                Invoke-RobustDownload -Url $IconUrl -OutFile $localIconPath
            }
            catch {
                Write-Verbose "Failed to download icon from $($IconUrl): $_"
            }
        }
        if (-not (Test-Path $localIconPath)) {
            Write-Warning "No icon.png found for package $PackageName. Creating a placeholder icon.png to prevent packaging failure."
            $dummyPngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
            $bytes = [System.Convert]::FromBase64String($dummyPngBase64)
            [System.IO.File]::WriteAllBytes($localIconPath, $bytes)
        }
    }
}
