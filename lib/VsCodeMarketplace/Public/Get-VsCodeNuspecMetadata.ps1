<#
.SYNOPSIS
    Centralized helper to transform VS Code Marketplace JSON into Chocolatey Nuspec strings.

.DESCRIPTION
    Maps raw JSON fields from the VS Code Marketplace API into a sanitized hashtable of standard Chocolatey attributes, ensuring special XML characters are safely escaped.

.PARAMETER ExtMeta
    The raw JSON payload returned by the VS Code Marketplace API.

.PARAMETER ExtensionPublisher
    The canonical publisher name.

.PARAMETER ExtensionName
    The canonical extension name.

.PARAMETER Description
    Optional pre-formatted Markdown description block to inject into the returned object.

.EXAMPLE
    $nuspecMeta = Get-VsCodeNuspecMetadata -ExtMeta $extMeta -ExtensionPublisher "ms-python" -ExtensionName "python"

.INPUTS
    None

.OUTPUTS
    [System.Collections.Hashtable]
    Contains standard string properties: Title, Authors, ProjectUrl, Description, and Summary.

.NOTES
    Critical for ensuring invalid ampersands or brackets do not break the `.nuspec` XML compilation.
#>
function Get-VsCodeNuspecMetadata {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Matching external API or established domain terminology')]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$ExtMeta,
        [Parameter(Mandatory = $true)][string]$ExtensionPublisher,
        [Parameter(Mandatory = $true)][string]$ExtensionName
    )

    function ConvertTo-XmlSafeString([string]$text) {
        if ([string]::IsNullOrEmpty($text)) { return "" }
        return [System.Security.SecurityElement]::Escape($text)
    }

    $extNameDisplay = if ($ExtMeta.displayName) { $ExtMeta.displayName } else { $ExtensionName }
    $title = ConvertTo-XmlSafeString "Visual Studio Code Extension - $extNameDisplay"

    $summaryRaw = if ($ExtMeta.shortDescription) { $ExtMeta.shortDescription } else { "" }
    $summaryEscaped = ConvertTo-XmlSafeString $summaryRaw

    $authorRaw = if ($ExtMeta.publisher.publisherName) { $ExtMeta.publisher.publisherName } else { $ExtensionPublisher }
    $author = ConvertTo-XmlSafeString $authorRaw

    $extId = "$ExtensionPublisher.$ExtensionName"
    $repoUrl = "$script:MarketplaceBaseUrl/items?itemName=$extId"

    $sourceLink = $null
    $supportLink = $null
    $learnLink = $null

    if ($ExtMeta.versions -and $ExtMeta.versions.Count -gt 0) {
        $sourceLink = $ExtMeta.versions[0].properties | Where-Object { $_.key -eq "Microsoft.VisualStudio.Services.Links.Source" }
        $supportLink = $ExtMeta.versions[0].properties | Where-Object { $_.key -eq "Microsoft.VisualStudio.Services.Links.Support" }
        $learnLink = $ExtMeta.versions[0].properties | Where-Object { $_.key -eq "Microsoft.VisualStudio.Services.Links.Learn" }
    }

    $projectSourceUrl = ""
    if ($sourceLink) {
        $repoUrl = $sourceLink.value
        $projectSourceUrl = $sourceLink.value -replace '\.git$', ''
    }

    $bugTrackerUrl = ""
    if ($supportLink) {
        $bugTrackerUrl = $supportLink.value
    }

    $docsUrl = ""
    if ($learnLink) {
        $docsUrl = $learnLink.value
    }

    $baseTags = @("vscode", "extension", $ExtensionName.ToLower())
    if ($ExtMeta.tags) {
        # Filter and sanitize marketplace tags
        $mpTags = $ExtMeta.tags | Where-Object { $_ -notmatch '^\s*$' } | ForEach-Object {
            $cleaned = $_ -replace '[^\w\.-]+', '-' -replace '^-+|-+$', ''
            if ($cleaned) { $cleaned.ToLower() }
        }
        $baseTags += $mpTags
    }
    # Ensure unique tags and join with spaces
    $finalTags = ($baseTags | Select-Object -Unique) -join " "

    $iconUrl = ""
    if ($ExtMeta.versions -and $ExtMeta.versions.Count -gt 0) {
        $iconUrlNode = $ExtMeta.versions[0].files | Where-Object { $_.assetType -eq "Microsoft.VisualStudio.Services.Icons.Default" }
        if ($iconUrlNode) {
            $iconUrl = $iconUrlNode.source
        }
    }

    return @{
        Title            = $title
        Summary          = $summaryEscaped
        Authors          = $author
        ProjectUrl       = ConvertTo-XmlSafeString $repoUrl
        ProjectSourceUrl = ConvertTo-XmlSafeString $projectSourceUrl
        BugTrackerUrl    = ConvertTo-XmlSafeString $bugTrackerUrl
        DocsUrl          = ConvertTo-XmlSafeString $docsUrl
        Tags             = ConvertTo-XmlSafeString $finalTags
        MarketplaceUrl   = ConvertTo-XmlSafeString "$script:MarketplaceBaseUrl/items?itemName=$extId"
        LicenseUrl       = ConvertTo-XmlSafeString "$script:MarketplaceBaseUrl/items/$extId/license"
        IconUrl          = ConvertTo-XmlSafeString $iconUrl
    }
}
