<#
.SYNOPSIS
    Saves an XML DOM to disk with strictly enforced LF line endings.

.DESCRIPTION
    Natively saves the .NET XML DOM object, then performs a raw string normalization pass
    to convert any CRLF line endings to LF before persisting to disk using UTF8 no-BOM.

.PARAMETER NuspecXml
    An [xml] object representing the parsed .nuspec file.

.PARAMETER NuspecPath
    The absolute path to the physical .nuspec file on disk to save to.

.EXAMPLE
    $nuspecXml = [xml](Get-Content -Path .\package.nuspec -Raw)
    Save-NuspecXml -NuspecXml $nuspecXml -NuspecPath "C:\temp\pkg\package.nuspec"

.INPUTS
    None

.OUTPUTS
    None
#>
function Save-NuspecXml {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Internal utility for saving files')]
    param(
        [Parameter(Mandatory = $true)][object]$NuspecXml,
        [Parameter(Mandatory = $true)][string]$NuspecPath
    )

    $NuspecXml.Save($NuspecPath)
    $finalNuspecContent = Get-Content $NuspecPath -Raw -Encoding UTF8
    $finalNuspecContent = $finalNuspecContent.Replace("`r`n", "`n")
    [System.IO.File]::WriteAllText($NuspecPath, $finalNuspecContent, [System.Text.UTF8Encoding]::new($false))
}
