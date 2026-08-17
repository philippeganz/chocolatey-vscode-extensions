<#
.SYNOPSIS
    Fetches the raw JSON metadata payload for a specific extension from the VS Code Marketplace API.

.DESCRIPTION
    Constructs a robust POST request to the official VS Code Marketplace Gallery API. It abstracts
    away rate-limiting quirks and ensures retries on transient network failures, returning the raw
    JSON payload block for the specified extension identifier.

.PARAMETER Publisher
    The canonical publisher name of the extension (e.g. 'ms-python').

.PARAMETER ExtensionName
    The canonical name of the extension (e.g. 'python').

.EXAMPLE
    $extMeta = Get-VsCodeMarketplaceMetadata -Publisher "ms-python" -ExtensionName "python"

.INPUTS
    None

.OUTPUTS
    [System.Management.Automation.PSCustomObject]
    The raw parsed JSON payload from the Marketplace API.

.NOTES
    Throws a terminating error if the API request fails after all retry attempts.
#>
function Get-VsCodeMarketplaceMetadata {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Matching external API or established domain terminology')]
    param (
        [Parameter(Mandatory = $true)][string]$Publisher,
        [Parameter(Mandatory = $true)][string]$ExtensionName,
        [switch]$IncludeAllVersions
    )

    $marketplaceUrl = "$script:MarketplaceBaseUrl/_apis/public/gallery/extensionquery"

    # Flag 914 includes 512 (IncludeLatestVersionOnly). 402 excludes it, fetching the full version history.
    $queryFlags = if ($IncludeAllVersions) { 402 } else { 914 }

    $body = @{
        filters = @(
            @{
                criteria   = @(
                    @{ filterType = 7; value = "$Publisher.$ExtensionName" }
                )
                pageNumber = 1
                pageSize   = 1
            }
        )
        flags   = $queryFlags
    } | ConvertTo-Json -Depth 10

    $headers = @{
        "Accept"       = "application/json;api-version=3.0-preview.1"
        "Content-Type" = "application/json"
    }

    $res = Invoke-WithMarketplaceRetry -Action {
        Invoke-RestMethod -Uri $marketplaceUrl -Method Post -Body $body -Headers $headers
    } -ErrorMessage "VS Code Marketplace API failed"

    $ext = $res.results[0].extensions[0]
    if (-not $ext) { throw "Extension not found on Marketplace: $Publisher.$ExtensionName" }

    return $ext
}

