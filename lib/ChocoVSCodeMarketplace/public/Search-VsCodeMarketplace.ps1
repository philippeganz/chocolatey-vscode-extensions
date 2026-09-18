#Requires -Version 7.0
<#
.SYNOPSIS
    Searches the VS Code Marketplace API using a generic text query.

.DESCRIPTION
    Constructs a robust POST request to the official VS Code Marketplace Gallery API using filterType 10 (SearchText).
    It abstracts away rate-limiting quirks and ensures retries on transient network failures, returning a list of matching extensions.

.PARAMETER Query
    The generic text string to search for (e.g. 'java', 'python', 'docker').

.EXAMPLE
    $results = Search-VsCodeMarketplace -Query "java"

.INPUTS
    None

.OUTPUTS
    [System.Management.Automation.PSCustomObject[]]
    An array of parsed extensions returned from the Marketplace API.

.NOTES
    Throws a terminating error if the API request fails after all retry attempts.
#>
function Search-VsCodeMarketplace {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Matching external API or established domain terminology')]
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $Query
    )

    $marketplaceUrl = "$script:MarketplaceBaseUrl/_apis/public/gallery/extensionquery"

    $body = @{
        filters = @(
            @{
                criteria = @(
                    @{ filterType = 10; value = $Query }
                )
            }
        )
        flags   = 914
    } | ConvertTo-Json -Depth 10 -Compress

    $headers = @{
        "Accept"       = "application/json;api-version=3.0-preview.1"
        "Content-Type" = "application/json"
    }

    $response = Invoke-WithMarketplaceRetry -Action {
        Invoke-RestMethod -Uri $marketplaceUrl -Method Post -Body $body -Headers $headers
    } -ErrorMessage "VS Code Marketplace API failed"

    if (-not $response.results[0].extensions) {
        return @()
    }

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($ext in $response.results[0].extensions) {
        $desc = $ext.shortDescription
        if ($desc -and $desc.Length -gt 50) { $desc = $desc.Substring(0, 47) + "..." }
        $results.Add([PSCustomObject]@{
                Id          = "$($ext.publisher.publisherName).$($ext.extensionName)"
                DisplayName = $ext.displayName
                Description = $desc
            })
    }

    return $results.ToArray()
}
