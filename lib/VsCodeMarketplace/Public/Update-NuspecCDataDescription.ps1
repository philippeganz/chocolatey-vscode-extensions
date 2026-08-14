<#
.SYNOPSIS
    Injects the CDATA description into the nuspec XML DOM.

.DESCRIPTION
    Dynamically injects the Markdown README as a CDATA block into the <description> node of the DOM.
    If the README is empty, it gracefully falls back to the Marketplace shortDescription.

.PARAMETER NuspecXml
    An [xml] object representing the parsed .nuspec file.

.PARAMETER CDataSafeReadme
    The raw text content of the README.md, formatted safely for CDATA blocks.

.PARAMETER ShortDescription
    The short description string provided by the Marketplace API.

.EXAMPLE
    $nuspecXml = [xml](Get-Content -Path .\package.nuspec -Raw)
    Update-NuspecCDataDescription -NuspecXml $nuspecXml -CDataSafeReadme $readme -ShortDescription "Fallback description"

.INPUTS
    None

.OUTPUTS
    None
#>
function Update-NuspecCDataDescription {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Internal DOM manipulation')]
    param(
        [Parameter(Mandatory = $true)][object]$NuspecXml,
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$CDataSafeReadme,
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$ShortDescription
    )

    $descNode = $NuspecXml.SelectSingleNode("//*[local-name()='description']")
    if ($descNode) {
        $descNode.RemoveAll()
        $readmeContent = $CDataSafeReadme
        if ($readmeContent -eq "") {
            $readmeContent = $ShortDescription
        }
        $cdata = $NuspecXml.CreateCDataSection("`n" + $readmeContent + "`n")
        [void]$descNode.AppendChild($cdata)
    }
}
