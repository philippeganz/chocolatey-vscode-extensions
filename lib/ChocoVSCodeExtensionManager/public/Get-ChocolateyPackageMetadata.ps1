#Requires -Version 7.0

<#
.SYNOPSIS
    Queries the Chocolatey Community v2 OData feed for package metadata.
.DESCRIPTION
    A centralized helper to extract ownership, version, and publication dates for a specific
    package from the Chocolatey API. Ensures all repository scripts evaluate the live feed
    using the exact same logic.
.PARAMETER PackageName
    The compiled Chocolatey package name (e.g. 'vscode-python').
.OUTPUTS
    [System.Management.Automation.PSCustomObject]
#>
function Get-ChocolateyPackageMetadata {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $PackageName
    )

    $url = "https://community.chocolatey.org/api/v2/Packages()?$filter=Id eq '$PackageName' and IsLatestVersion eq true"
    $ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36"

    try {
        $res = Invoke-WebRequest -Uri $url -UserAgent $ua -UseBasicParsing -ErrorAction Stop
        if (-not $res -or -not $res.Content) { return $null }
        $c = $res.Content

        $meta = [PSCustomObject]@{
            PackageName   = $PackageName
            Owners        = $null
            RemoteVersion = $null
            Published     = $null
        }

        if ($c -match '<d:Owners[^>]*>(.*?)</d:Owners>') {
            $meta.Owners = $matches[1]
        }
        if ($c -match '<d:Version[^>]*>(.*?)</d:Version>') {
            $meta.RemoteVersion = $matches[1]
        }
        if ($c -match '<d:Published[^>]*>(.*?)</d:Published>') {
            $meta.Published = [datetime]($matches[1])
        }

        return $meta
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        if ($_.Exception.Response.StatusCode -eq 'NotFound') { return $null }
        throw $_
    }
}
