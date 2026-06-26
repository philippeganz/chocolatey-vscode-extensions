[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigFile = "$PSScriptRoot\config.yaml"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

# =============================================================================
# 1. Configuration & Scaffolding
# =============================================================================
# We parse the config.yaml to determine which extensions the Factory should
# track. The output directory defaults to 'automatic/' where the generated
# Chocolatey packages will be placed.
if (-not (Test-Path $ConfigFile)) { throw "Configuration file not found: $ConfigFile" }

if (-not (Get-Module -ListAvailable powershell-yaml)) {
    Write-Host "Installing required powershell-yaml module..." -ForegroundColor Yellow
    Install-Module powershell-yaml -Force -Scope CurrentUser
}
Import-Module powershell-yaml

$yamlObj = Get-Content $ConfigFile -Raw | ConvertFrom-Yaml

# Resolve relative OutputDir
$OutputDir = $yamlObj.config.output_dir
if (-not [System.IO.Path]::IsPathRooted($OutputDir)) {
    $OutputDir = Resolve-Path (Join-Path $PSScriptRoot $OutputDir) -ErrorAction SilentlyContinue
    if (-not $OutputDir) {
        $OutputDir = Join-Path $PSScriptRoot $yamlObj.config.output_dir
    }
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

$extensions = $yamlObj.extensions
if (-not $extensions -or $extensions.Count -eq 0) {
    throw "No extensions found in $ConfigFile"
}

Write-Host ">>> Starting VS Code Extension Factory" -ForegroundColor Cyan
Write-Host "    Target Output Directory: $OutputDir"
Write-Host "    Extensions to Process: $($extensions.Count)"

# 2. Main Factory Loop
foreach ($extId in $extensions) {
    Write-Host "`n----------------------------------------" -ForegroundColor DarkGray
    Write-Host "Processing: $extId" -ForegroundColor Cyan

    $parts = $extId -split '\.'
    if ($parts.Count -ne 2) {
        Write-Host "    [ERROR] Invalid ExtensionId format. Skipping." -ForegroundColor Red
        continue
    }
    $publisher = $parts[0]
    $extensionName = $parts[1]

    $packageName = $extensionName.ToLower()
    if (-not $packageName.StartsWith("vscode-")) {
        $packageName = "vscode-$packageName"
    }

    $pkgDir = Join-Path $OutputDir $packageName
    if (Test-Path $pkgDir) {
        Write-Host "    [INFO] Package folder already exists ($packageName). Skipping." -ForegroundColor Yellow
        continue
    }

    # =========================================================================
    # 2. Query VS Code Marketplace API
    # =========================================================================
    # We send an undocumented POST request to the Gallery API to retrieve the
    # extension's metadata (version, description, icon URL).
    $marketplaceUrl = "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
    $body = @{
        filters = @(
            @{
                criteria   = @(
                    @{ filterType = 7; value = $extId }
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

    try {
        $res = Invoke-RestMethod -Uri $marketplaceUrl -Method Post -Body $body -Headers $headers
        $extMeta = $res.results[0].extensions[0]
    }
    catch {
        Write-Host "    [ERROR] Failed to fetch metadata for $extId" -ForegroundColor Red
        continue
    }

    if (-not $extMeta) {
        Write-Host "    [ERROR] Extension not found on Marketplace: $extId" -ForegroundColor Red
        continue
    }

    $version = $extMeta.versions[0].version
    $versionClean = $version -replace '[^\d\.-]', ''
    $displayName = $extMeta.displayName
    $description = $extMeta.shortDescription
    $iconUrl = $extMeta.versions[0].files | Where-Object { $_.assetType -eq "Microsoft.VisualStudio.Services.Icons.Default" } | Select-Object -ExpandProperty source

    Write-Host "    Version: $versionClean"

    # Scaffold Package Directory
    $toolsDir = Join-Path $pkgDir "tools"
    New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null

    # Download VSIX
    $vsixUrl = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/$publisher/vsextensions/$extensionName/$version/vspackage"
    $vsixName = "$publisher.$extensionName-$versionClean.vsix"
    $vsixPath = Join-Path $toolsDir $vsixName

    Write-Host "    Downloading VSIX Payload..."
    Invoke-WebRequest -Uri $vsixUrl -OutFile $vsixPath

    # =========================================================================
    # 3. Payload Extraction (Air-Gap Compliance)
    # =========================================================================
    # A .vsix file is just a ZIP archive. We crack it open using native .NET
    # libraries to extract the internal package.json, README.md, and LICENSE
    # files so we can natively bundle them into the Chocolatey .nupkg.
    Write-Host "    Extracting Metadata from VSIX Archive..."
    $zip = [System.IO.Compression.ZipFile]::OpenRead($vsixPath)

    $packageJsonEntry = $zip.Entries | Where-Object { $_.FullName -eq 'extension/package.json' }
    $readmeEntry = $zip.Entries | Where-Object { $_.FullName -match '(?i)extension/README\.md' }
    $licenseEntry = $zip.Entries | Where-Object { $_.FullName -match '(?i)extension/LICENSE' }

    if ($packageJsonEntry) {
        $stream = $packageJsonEntry.Open()
        $reader = New-Object System.IO.StreamReader($stream)
        $packageJsonContent = $reader.ReadToEnd()
        $reader.Close(); $stream.Close()

        $packageJson = $packageJsonContent | ConvertFrom-Json

        $repoUrl = if ($packageJson.repository.url) { $packageJson.repository.url } else { "" }
        $author = if ($packageJson.publisher) { $packageJson.publisher } else { $publisher }
    }

    if ($readmeEntry) {
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($readmeEntry, (Join-Path $pkgDir "README.md"), $true)
    }
    $licenseFileName = ""
    if ($licenseEntry) {
        $licenseFileName = $licenseEntry.Name
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($licenseEntry, (Join-Path $pkgDir $licenseFileName), $true)
    }

    $zip.Dispose()

    # =========================================================================
    # 4. Chocolatey Dependency Resolution
    # =========================================================================
    # If the VS Code extension declares internal dependencies (e.g., Extension Packs),
    # we dynamically translate those into Chocolatey package dependencies.
    $dependenciesStr = ""
    if ($packageJson.extensionDependencies) {
        Write-Host "    Found Extension Dependencies!" -ForegroundColor Yellow
        foreach ($dep in $packageJson.extensionDependencies) {
            $depName = ($dep -split '\.')[1].ToLower()
            $depPackageName = if ($depName.StartsWith("vscode-")) { $depName } else { "vscode-$depName" }
            $dependenciesStr += "      <dependency id=`"$depPackageName`" />`n"
        }
    }
    if ($packageJson.extensionPack) {
        Write-Host "    Found Extension Pack Bundles!" -ForegroundColor Yellow
        foreach ($dep in $packageJson.extensionPack) {
            $depName = ($dep -split '\.')[1].ToLower()
            $depPackageName = if ($depName.StartsWith("vscode-")) { $depName } else { "vscode-$depName" }
            $dependenciesStr += "      <dependency id=`"$depPackageName`" />`n"
        }
    }

    # =========================================================================
    # 5. Security Validation
    # =========================================================================
    # We scan the raw binary payload to look for forbidden runtime commands
    # that might attempt to break out of an offline/air-gapped network.
    Write-Host "    Deep Scanning VSIX for Network Triggers..."
    $dangerousMatches = Select-String -Path "$vsixPath" -Pattern "(wget\s|curl\s|Invoke-WebRequest|npm install|pip install)" -Quiet
    if ($dangerousMatches) {
        Write-Host "    [WARNING] Potential runtime network triggers found in VSIX payload!" -ForegroundColor Red
    }

    # =========================================================================
    # 6. Template Rendering
    # =========================================================================
    # We take the static scaffolding templates from bin/Templates and inject
    # the dynamically resolved metadata to finalize the AU package structure.
    Write-Host "    Rendering AU Templates..."
    $templatesDir = Join-Path $PSScriptRoot "Templates"

    $nuspecContent = Get-Content (Join-Path $templatesDir "template.nuspec") -Raw
    $nuspecContent = $nuspecContent -replace '\{\{ExtensionNameLowerCase\}\}', $packageName.Replace("vscode-", "")
    $nuspecContent = $nuspecContent -replace '\{\{Version\}\}', $versionClean
    $nuspecContent = $nuspecContent -replace '\{\{Title\}\}', $displayName
    $nuspecContent = $nuspecContent -replace '\{\{Authors\}\}', $author
    $nuspecContent = $nuspecContent -replace '\{\{ProjectUrl\}\}', $repoUrl
    $nuspecContent = $nuspecContent -replace '\{\{IconUrl\}\}', $iconUrl
    $nuspecContent = $nuspecContent -replace '\{\{MarketplaceUrl\}\}', "https://marketplace.visualstudio.com/items?itemName=$extId"
    $nuspecContent = $nuspecContent -replace '\{\{Description\}\}', $description
    $nuspecContent = $nuspecContent -replace '\{\{Dependencies\}\}', $dependenciesStr
    $nuspecContent | Out-File (Join-Path $pkgDir "$packageName.nuspec") -Encoding utf8

    $installContent = Get-Content (Join-Path $templatesDir "chocolateyInstall.ps1") -Raw
    $installContent = $installContent -replace '\{\{Publisher\}\}', $publisher
    $installContent = $installContent -replace '\{\{ExtensionName\}\}', $extensionName
    $installContent = $installContent -replace '\{\{Version\}\}', $versionClean
    $installContent | Out-File (Join-Path $toolsDir "chocolateyInstall.ps1") -Encoding utf8

    $updateContent = Get-Content (Join-Path $templatesDir "update.ps1") -Raw
    $updateContent = $updateContent -replace '\{\{Publisher\}\}', $publisher
    $updateContent = $updateContent -replace '\{\{ExtensionName\}\}', $extensionName
    $updateContent | Out-File (Join-Path $pkgDir "update.ps1") -Encoding utf8

    # Download Icon
    if ($iconUrl) {
        Invoke-WebRequest -Uri $iconUrl -OutFile (Join-Path $pkgDir "icon.png") -ErrorAction SilentlyContinue
    }

    Write-Host "    [SUCCESS] Scaffolded at: $pkgDir" -ForegroundColor Green
}
Write-Host "`n>>> Factory Run Complete!" -ForegroundColor Cyan
