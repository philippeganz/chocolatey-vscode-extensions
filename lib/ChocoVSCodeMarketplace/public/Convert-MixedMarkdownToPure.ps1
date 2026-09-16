#Requires -Version 7.0
<#
.SYNOPSIS
    Standardizes a mixed Markdown/HTML document into 100% pure Markdown.

.DESCRIPTION
    Chocolatey's Markdig Markdown engine breaks on complex embedded HTML tags (tables, figures, etc.).
    This function implements the "Holy Grail" of document standardization:
    1. It downloads Markdig and ReverseMarkdown natively via NuGet.
    2. It uses Markdig to parse the mixed Markdown+HTML document into a unified HTML DOM.
    3. It uses ReverseMarkdown to convert the unified DOM back into 100% pure Markdown.
    The result perfectly translates all raw HTML tables, links, and figures into native Markdown equivalents,
    stripping problematic wrapping tags while perfectly preserving the document's structure and spacing.

.PARAMETER Text
    The raw, mixed Markdown and HTML text to be converted into pure Markdown.

.EXAMPLE
    $pureMd = Convert-MixedMarkdownToPure -Text $rawText

.OUTPUTS
    [System.String]
#>
function Convert-MixedMarkdownToPure {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $cacheDir = Join-Path $env:TEMP "ChocoVSCodeCache"
    if (-not (Test-Path $cacheDir)) { [void](New-Item -ItemType Directory -Path $cacheDir) }

    if (-not ('ReverseMarkdown.Converter' -as [type])) {
        Write-Verbose "Downloading and loading Markdown processing engines..."

        $hapZip = Join-Path $cacheDir "hap.zip"
        $rmZip = Join-Path $cacheDir "rm.zip"
        $mdZip = Join-Path $cacheDir "md.zip"

        if (-not (Test-Path $hapZip)) { Invoke-RobustDownload -Url "https://www.nuget.org/api/v2/package/HtmlAgilityPack/1.11.59" -OutFile $hapZip }
        if (-not (Test-Path $rmZip)) { Invoke-RobustDownload -Url "https://www.nuget.org/api/v2/package/ReverseMarkdown/4.3.0" -OutFile $rmZip }
        if (-not (Test-Path $mdZip)) { Invoke-RobustDownload -Url "https://www.nuget.org/api/v2/package/Markdig/0.37.0" -OutFile $mdZip }

        if (-not (Test-Path "$cacheDir\hap")) { Expand-Archive $hapZip -DestinationPath "$cacheDir\hap" -Force }
        if (-not (Test-Path "$cacheDir\rm")) { Expand-Archive $rmZip -DestinationPath "$cacheDir\rm" -Force }
        if (-not (Test-Path "$cacheDir\md")) { Expand-Archive $mdZip -DestinationPath "$cacheDir\md" -Force }

        Add-Type -Path "$cacheDir\hap\lib\netstandard2.0\HtmlAgilityPack.dll"
        Add-Type -Path "$cacheDir\rm\lib\netstandard2.0\ReverseMarkdown.dll"
        Add-Type -Path "$cacheDir\md\lib\netstandard2.0\Markdig.dll"
    }

    Write-Verbose "Parsing Mixed Markdown into unified HTML DOM..."
    $html = [Markdig.Markdown]::ToHtml($Text)

    Write-Verbose "Translating unified HTML DOM into Pure Markdown..."
    $config = [ReverseMarkdown.Config]::new()
    $config.GithubFlavored = $true
    $config.UnknownTags = [ReverseMarkdown.Config+UnknownTagsOption]::Bypass
    $converter = [ReverseMarkdown.Converter]::new($config)

    return $converter.Convert($html).Trim()
}
