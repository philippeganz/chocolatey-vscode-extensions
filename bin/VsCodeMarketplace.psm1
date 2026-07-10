<#
.SYNOPSIS
Centralized helper module for interacting with the Visual Studio Code Marketplace API.
Contains robust, self-healing functions to abstract away API quirks, rate limits,
and platform-specific payload ambiguities.
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
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
        [Parameter(Mandatory = $true)][string]$DestinationDir
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

        if ($readmeEntry) {
            $readmePath = Join-Path $DestinationDir "tools\README.md"
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($readmeEntry, $readmePath, $true)

            # Scrub emails from the README itself to pass Chocolatey Moderation checks.
            $readmeRaw = Get-Content $readmePath -Raw -Encoding UTF8
            $readmeRaw = $readmeRaw -replace '(?i)[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}', '[email removed]'
            $readmeFull = $readmeRaw

            # Semantically truncate to comply with Chocolatey's 4000 character `<description>` limit
            $limit = 3750
            if ($readmeRaw.Length -gt $limit) {
                $searchSpace = $readmeRaw.Substring(0, $limit)
                $truncated = ""

                $match = [regex]::Match($searchSpace, '(?is).*(</table>|</ul>|</ol>|</p>|</div>|</pre>|</blockquote>|\r?\n[ \t]*\r?\n|</tr>|</li>|</dd>)')
                if ($match.Success -and $match.Length -gt 1500) {
                    $truncated = $match.Value
                }
                else {
                    $match = [regex]::Match($searchSpace, '(?is).*\.(?=\s)')
                    if ($match.Success -and $match.Length -gt 1500) {
                        $truncated = $match.Value
                    }
                    else {
                        $match = [regex]::Match($searchSpace, '(?is).*(?=\r?\n)')
                        if ($match.Success -and $match.Length -gt 1500) {
                            $truncated = $match.Value
                        }
                        else {
                            $idx = $searchSpace.LastIndexOf(' ')
                            if ($idx -gt 0) {
                                $truncated = $searchSpace.Substring(0, $idx)
                            }
                            else {
                                $truncated = $searchSpace
                            }
                        }
                    }
                }

                $truncated = $truncated.TrimEnd()

                # Auto-close any unclosed HTML tags (from innermost to outermost) to prevent layout breaking
                $tagsToBalance = @("td", "th", "tr", "thead", "tbody", "table", "li", "ul", "ol", "pre", "div", "blockquote", "dd", "dl")
                foreach ($tag in $tagsToBalance) {
                    $open = ([regex]::Matches($truncated, "(?i)<$tag\b")).Count
                    $close = ([regex]::Matches($truncated, "(?i)</$tag>")).Count
                    if ($open -gt $close) {
                        for ($i = 0; $i -lt ($open - $close); $i++) {
                            $truncated += "</$tag>"
                        }
                    }
                }

                $marketplaceUrl = "https://marketplace.visualstudio.com/items?itemName=$($packageJson.publisher).$($packageJson.name)"
                $readmeRaw = $truncated + "`n`n... [Truncated due to Chocolatey character limits. See [extension page]($marketplaceUrl) for full documentation]"
            }

            # We save the FULL readme back to tools/README.md for the user, but we will return the $readmeRaw (which is truncated) for the nuspec
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($readmePath, $readmeFull, $utf8NoBom)
        }

        if ($licenseEntry) {
            $licenseFileName = $licenseEntry.Name
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($licenseEntry, (Join-Path $DestinationDir "tools\$licenseFileName"), $true)
        }
    }
    finally {
        if ($null -ne $zip) {
            $zip.Dispose()
        }
    }

    return [PSCustomObject]@{
        PackageJson     = $packageJson
        TruncatedReadme = $readmeRaw
    }
}


<#
.SYNOPSIS
Dynamically updates the Chocolatey .nuspec XML to append discovered extension dependencies.

.DESCRIPTION
Scans the raw package.json of a VS Code extension for internal `extensionDependencies` or `extensionPacks` arrays.
It maps these dependencies to their Chocolatey package equivalents, appends them to the `<dependencies>` block of the .nuspec, and auto-queues missing ones to the Factory.

.PARAMETER NuspecXml
An [xml] object representing the parsed .nuspec file.

.PARAMETER PackageJson
A JSON object representing the parsed package.json from the extension payload.

.PARAMETER PackageName
The canonical Chocolatey package name currently being processed.

.PARAMETER ConfigPath
The absolute path to the config.yaml tracker.
#>
function Update-NuspecDependency {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    param(
        [Parameter(Mandatory = $true)][object]$NuspecXml,
        [Parameter(Mandatory = $true)][object]$PackageJson,
        [Parameter(Mandatory = $true)][string]$ConfigPath
    )

    $dependencyAliases = @{
        "vscode.docker"               = "ms-azuretools.vscode-docker"
        "PeterJausovec.vscode-docker" = "ms-azuretools.vscode-docker"
        "vscode.yaml"                 = "redhat.vscode-yaml"
        "donjayamanne.python"         = "ms-python.python"
        "lukehoban.Go"                = "golang.Go"
        "ms-vscode.Go"                = "golang.Go"
        "ms-vscode.csharp"            = "ms-dotnettools.csharp"
        "eg2.tslint"                  = "ms-vscode.vscode-typescript-tslint-plugin"
    }

    $ns = $NuspecXml.DocumentElement.NamespaceURI
    $depsNode = $NuspecXml.package.metadata.dependencies
    if ($null -eq $depsNode) {
        $depsNode = $NuspecXml.CreateElement("dependencies", $ns)
        $NuspecXml.package.metadata.AppendChild($depsNode) | Out-Null
    }
    else {
        $depsNode.RemoveAll()
    }

    $baseDep = $NuspecXml.CreateElement("dependency", $ns)
    $baseDep.SetAttribute("id", "chocolatey-vscode.extension")
    $baseDep.SetAttribute("version", "1.1.0")
    $depsNode.AppendChild($baseDep) | Out-Null

    if (-not (Get-Module -Name powershell-yaml)) {
        Import-Module powershell-yaml -ErrorAction Stop
    }
    $config = Get-Content $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Yaml
    $trackedExtensions = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($ext in $config.extensions) { $trackedExtensions.Add($ext) | Out-Null }

    $processDep = {
        param($depRaw)
        if ($depRaw.ToLower().StartsWith("vscode.")) { return }
        $dep = if ($dependencyAliases.ContainsKey($depRaw)) { $dependencyAliases[$depRaw] } else { $depRaw }
        $depName = ($dep -split '\.')[1].ToLower()
        $depPackageName = if ($depName.StartsWith("vscode-")) { $depName } else { "vscode-$depName" }

        if ($depPackageName -ne $PackageName) {
            $depNode = $NuspecXml.CreateElement("dependency", $ns)
            $depNode.SetAttribute("id", $depPackageName)
            $depsNode.AppendChild($depNode) | Out-Null

            if (-not $trackedExtensions.Contains($dep)) {
                Write-Host "    [AUTO-DISCOVERY] Queuing missing dependency via Factory: $dep" -ForegroundColor Magenta
                $factoryPath = Join-Path (Split-Path $ConfigPath) "Manage-ExtensionPool.ps1"
                & $factoryPath -Add $dep
                $trackedExtensions.Add($dep) | Out-Null
                $global:au_RequiresSecondRun = $true
            }
        }
    }

    if ($PackageJson.extensionDependencies) {
        foreach ($depRaw in $PackageJson.extensionDependencies) { & $processDep $depRaw }
    }
    if ($PackageJson.extensionPack) {
        foreach ($depRaw in $PackageJson.extensionPack) { & $processDep $depRaw }
    }
}

<#
.SYNOPSIS
Centralized helper to transform VS Code Marketplace JSON into Chocolatey Nuspec strings.

.DESCRIPTION
Maps raw JSON fields from the VS Code Marketplace API into a sanitized hashtable of standard Chocolatey attributes, ensuring special XML characters are safely escaped.

.PARAMETER RawMeta
The raw JSON payload returned by the VS Code Marketplace API.
#>
function Get-VsCodeNuspecMetadata {
    param(
        [Parameter(Mandatory = $true)][object]$ExtMeta,
        [Parameter(Mandatory = $true)][string]$ExtensionPublisher,
        [Parameter(Mandatory = $true)][string]$ExtensionName,
        [Parameter(Mandatory = $false)][string]$Description = ''
    )

    $extNameDisplay = if ($ExtMeta.displayName) { $ExtMeta.displayName } else { $ExtensionName }
    $title = "Visual Studio Code Extension - $extNameDisplay"

    $summaryRaw = if ($ExtMeta.shortDescription) { $ExtMeta.shortDescription } else { "" }
    $summaryEscaped = $summaryRaw -replace '"', '&quot;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '&', '&amp;'

    $author = if ($ExtMeta.publisher.publisherName) { $ExtMeta.publisher.publisherName } else { $ExtensionPublisher }

    $extId = "$ExtensionPublisher.$ExtensionName"
    $repoUrl = "https://marketplace.visualstudio.com/items?itemName=$extId"
    $links = $ExtMeta.versions[0].properties | Where-Object { $_.key -eq "Microsoft.VisualStudio.Services.Links.Source" }
    if ($links) {
        $repoUrl = $links.value
    }

    $iconUrl = $ExtMeta.versions[0].files | Where-Object { $_.assetType -eq "Microsoft.VisualStudio.Services.Icons.Default" } | Select-Object -ExpandProperty source
    if (-not $iconUrl) { $iconUrl = "" }

    return @{
        Title          = $title
        Summary        = $summaryEscaped
        Authors        = $author
        ProjectUrl     = $repoUrl
        MarketplaceUrl = "https://marketplace.visualstudio.com/items?itemName=$extId"
        IconUrl        = $iconUrl
        Description    = $Description
    }
}

Export-ModuleMember -Function Get-VsCodeMarketplaceMetadata, Get-VsCodeExtensionUrl, Invoke-RobustDownload, Expand-VsCodePayload, Update-NuspecDependency, Get-VsCodeNuspecMetadata



