<#
.SYNOPSIS
Centralized helper module for interacting with the Visual Studio Code Marketplace API.
Contains robust, self-healing functions to abstract away API quirks, rate limits,
and platform-specific payload ambiguities.
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
param()

<#
.SYNOPSIS
Fetches the raw JSON metadata payload for a specific extension from the VS Code Marketplace API.
#>
function Get-VsCodeMarketplaceMetadata {
    param (
        [Parameter(Mandatory = $true)][string]$Publisher,
        [Parameter(Mandatory = $true)][string]$ExtensionName
    )

    $marketplaceUrl = "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
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
        flags   = 914
    } | ConvertTo-Json -Depth 10

    $headers = @{
        "Accept"       = "application/json;api-version=3.0-preview.1"
        "Content-Type" = "application/json"
    }

    $retryCount = 0
    $success = $false
    $res = $null

    while (-not $success -and $retryCount -lt 5) {
        try {
            $res = Invoke-RestMethod -Uri $marketplaceUrl -Method Post -Body $body -Headers $headers -ErrorAction Stop
            $success = $true
        }
        catch {
            Write-Host "    [WARNING] VS Code Marketplace API failed (Rate Limit/Network). Retrying in 5 seconds..." -ForegroundColor Yellow
            $retryCount++
            if ($retryCount -ge 5) { throw $_ }
            Start-Sleep -Seconds 5
        }
    }

    $ext = $res.results[0].extensions[0]
    if (-not $ext) { throw "Extension not found on Marketplace: $Publisher.$ExtensionName" }

    return $ext
}

<#
.SYNOPSIS
Constructs the direct VSIX payload download URL, handling platform-specific ambiguities.
#>
function Get-VsCodeExtensionUrl {
    param (
        [Parameter(Mandatory = $true)][string]$Publisher,
        [Parameter(Mandatory = $true)][string]$ExtensionName,
        [Parameter(Mandatory = $true)][string]$Version,
        [Parameter(Mandatory = $true)][object]$ExtMeta
    )

    $vsixUrl = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/$Publisher/vsextensions/$ExtensionName/$Version/vspackage"

    # Dynamic Platform Detection: Explicitly request the Windows binary if the extension is OS-specific
    $isPlatformSpecific = $ExtMeta.versions | Where-Object { $_.version -eq $ExtMeta.versions[0].version -and $_.targetPlatform -eq "win32-x64" }
    if ($isPlatformSpecific) {
        Write-Host "    [INFO] Platform-specific extension detected. Targeting win32-x64 binary." -ForegroundColor Cyan
        $vsixUrl = "$($vsixUrl)?targetPlatform=win32-x64"
    }

    return $vsixUrl
}

<#
.SYNOPSIS
Wraps Invoke-WebRequest with robust, auto-healing retry logic to survive CDN rate-limits and timeouts.
#>
function Invoke-RobustDownload {
    param (
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$OutFile
    )

    Write-Host "    Downloading VSIX Payload..."
    $retryCount = 0
    $success = $false
    while (-not $success -and $retryCount -lt 3) {
        try {
            Invoke-WebRequest -Uri $Url -OutFile $OutFile -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -TimeoutSec 600 -ErrorAction Stop
            $success = $true
        }
        catch {
            Write-Host "    [WARNING] Download failed. Retrying in 5 seconds ($($retryCount + 1)/3)..." -ForegroundColor Yellow
            $retryCount++
            if ($retryCount -ge 3) { throw }
            Start-Sleep -Seconds 5
        }
    }
}

<#
.SYNOPSIS
Cracks open a VSIX ZIP archive, extracts package.json, README.md, and LICENSE, and scrubs emails.
#>
function Expand-VsCodePayload {
    param (
        [Parameter(Mandatory = $true)][string]$VsixPath,
        [Parameter(Mandatory = $true)][string]$DestinationDir,
        [Parameter(Mandatory = $false)][switch]$ExtractPackageJsonOnly
    )

    Write-Host "    Extracting Metadata from VSIX Archive..."
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($VsixPath)
    $packageJson = $null

    try {
        $packageJsonEntry = $zip.Entries | Where-Object FullName -eq 'extension/package.json' | Select-Object -First 1
        $readmeEntry = $zip.Entries | Where-Object FullName -match '(?i)^extension/README\.md$' | Select-Object -First 1
        $licenseEntry = $zip.Entries | Where-Object FullName -match '(?i)^extension/LICENSE(?:\.txt|\.md)?$' | Select-Object -First 1

        if ($packageJsonEntry) {
            $stream = $packageJsonEntry.Open()
            $reader = New-Object System.IO.StreamReader($stream)
            $packageJsonContent = $reader.ReadToEnd()
            $reader.Close(); $stream.Close()
            $packageJson = $packageJsonContent | ConvertFrom-Json
        }

        if (-not $ExtractPackageJsonOnly) {
            if ($readmeEntry) {
                $readmePath = Join-Path $DestinationDir "README.md"
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($readmeEntry, $readmePath, $true)

                # Scrub emails from the README itself to pass Chocolatey Moderation checks.
                $readmeRaw = Get-Content $readmePath -Raw -Encoding UTF8
                $readmeRaw = $readmeRaw -replace '(?i)[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}', '[email removed]'
                $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                [System.IO.File]::WriteAllText($readmePath, $readmeRaw, $utf8NoBom)
            }

            if ($licenseEntry) {
                $licenseFileName = $licenseEntry.Name
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($licenseEntry, (Join-Path $DestinationDir $licenseFileName), $true)
            }
        }
    }
    finally {
        if ($null -ne $zip) {
            $zip.Dispose()
        }
    }

    return $packageJson
}

Export-ModuleMember -Function Get-VsCodeMarketplaceMetadata, Get-VsCodeExtensionUrl, Invoke-RobustDownload, Expand-VsCodePayload
