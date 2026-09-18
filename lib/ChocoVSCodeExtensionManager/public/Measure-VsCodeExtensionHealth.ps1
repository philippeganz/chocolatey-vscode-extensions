#Requires -Version 7.0

<#
.SYNOPSIS
    Evaluates the health metrics of a VS Code extension based on Marketplace metadata.
.DESCRIPTION
    A centralized function that takes raw VS Code Marketplace extension metadata and returns
    a standardized health profile object containing metrics like age, staleness, and deprecation status.
    This guarantees that both the factory CI and the scheduled repository health checks use the
    exact same logic and mathematical thresholds for metrics like "abandonware".
.PARAMETER Metadata
    The raw extension metadata object returned from the VS Code Marketplace API.
.EXAMPLE
    $meta = Get-VsCodeMarketplaceMetadata -Publisher "ms-python" -ExtensionName "python"
    $health = Measure-VsCodeExtensionHealth -Metadata $meta
.OUTPUTS
    [System.Management.Automation.PSCustomObject]
#>
function Measure-VsCodeExtensionHealth {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]
        $Metadata
    )

    $health = [PSCustomObject]@{
        IsDeprecated       = $false
        DeprecationMessage = $null
        IsAbandonware      = $false
        LastUpdated        = $null
        YearsOld           = 0
    }

    # Deprecation Check
    if ($Metadata.flags -match 'deprecated' -or $null -ne $Metadata.deprecationSettings) {
        $health.IsDeprecated = $true
        $msg = "Extension is deprecated on the Marketplace."
        if ($Metadata.deprecationSettings.alternateExtensionId) {
            $msg += " Replaced by: $($Metadata.deprecationSettings.alternateExtensionId)"
        }
        $health.DeprecationMessage = $msg
    }

    # Abandonware Check (3 Year Cutoff)
    $lastUpdatedStr = $Metadata.versions[0].lastUpdated
    if ($lastUpdatedStr) {
        $lastUpdated = [datetime]$lastUpdatedStr
        $health.LastUpdated = $lastUpdated

        $yearsOld = [math]::Round(((Get-Date) - $lastUpdated).TotalDays / 365.25, 1)
        $health.YearsOld = $yearsOld

        if ($lastUpdated -lt (Get-Date).AddYears(-3)) {
            $health.IsAbandonware = $true
        }
    }

    return $health
}
