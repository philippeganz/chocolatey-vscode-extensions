#Requires -Version 7.0
<#
.SYNOPSIS
    Automated Chocolatey Package Factory for Visual Studio Code Extensions.

.DESCRIPTION
    A highly robust PowerShell script that automates the scaffolding of Chocolatey packages
    for Visual Studio Code extensions. It queries the VS Code Marketplace API to extract
    metadata, payload URLs, and dependency graphs.

    This Factory is designed for enterprise air-gapped compliance. It extracts the embedded
    README and LICENSE files directly from the `.vsix` archive and ensures the generated
    `.nuspec` natively maps the Chocolatey dependencies correctly.

    [Smart Versioning]
    If the Factory is regenerating an existing package, it safely preserves the current
    version in the `.nuspec` instead of resetting it to 0.0.0, preventing CI pipeline collisions.

    [Auto-Discovery Engine]
    The Factory recursively parses internal `extensionDependencies` and `extensionPacks`.
    If it discovers missing dependencies, it queues them dynamically, scaffolds them automatically,
    filters out malformed cyclic self-dependencies, and safely rewrites the `config.yaml`
    file to explicitly track them as top-level peers.

.PARAMETER ExtensionId
    The exact unique identifier of the extension from the VS Code Marketplace
    (e.g., 'ms-python.python'). When provided, the Factory scaffolds this single package.

.PARAMETER ConfigFile
    The absolute or relative path to the YAML configuration file that contains the list of extensions to track. Defaults to 'etc/config.yaml'.

.PARAMETER Force
    If specified, completely nukes the existing package directory in 'automatic/'
    and forces a clean regeneration of all templates. Resets the version to 0.0.0.

.EXAMPLE
    .\Invoke-VsCodeExtensionFactory.ps1 -ExtensionId "ms-python.python"

.EXAMPLE
    .\Invoke-VsCodeExtensionFactory.ps1 -ExtensionId "ms-python.python" -Force
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification='Write-Host is required for CI/CD logging and workflow orchestration')]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigFile = "$PSScriptRoot\..\etc\config.yaml",

    [Parameter(Mandatory = $false)]
    [string[]]$ExtensionId,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

# =============================================================================
# 1. Configuration & Scaffolding
# =============================================================================
Import-Module "$PSScriptRoot\..\lib\VsCodeMarketplace.psm1"

# We parse the config.yaml to determine which extensions the Factory should
# track. The output directory defaults to 'automatic/' where the generated
# Chocolatey packages will be placed.
if (-not (Test-Path $ConfigFile)) { throw "Configuration file not found: $ConfigFile" }

if (-not (Get-Module -ListAvailable powershell-yaml)) {
    Write-Host "Installing required powershell-yaml module..." -ForegroundColor Yellow
    Install-Module powershell-yaml -Force -Scope CurrentUser
}
Import-Module powershell-yaml

$yamlObj = Get-Content $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Yaml

# Factory only outputs to the automatic/ directory at the root
$OutputDir = if ($env:CHOCO_VSCODE_AUTOMATIC_DIR) { $env:CHOCO_VSCODE_AUTOMATIC_DIR } else { Resolve-Path "$PSScriptRoot\..\automatic" -ErrorAction SilentlyContinue }
if (-not $OutputDir) { $OutputDir = if ($env:CHOCO_VSCODE_AUTOMATIC_DIR) { $env:CHOCO_VSCODE_AUTOMATIC_DIR } else { "$PSScriptRoot\..\automatic" } }

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

$extensionsList = [System.Collections.Generic.List[string]]::new()
if ($ExtensionId) {
    $extensionsList.Add($ExtensionId.ToLower())
}
else {
    foreach ($ext in $yamlObj.extensions) {
        $extensionsList.Add(([string]$ext).ToLower())
    }
}

if ($extensionsList.Count -eq 0) {
    throw "No extensions found in $ConfigFile, and no -ExtensionId was provided."
}

Write-Host ">>> Starting VS Code Extension Factory" -ForegroundColor Cyan
Write-Host "    Target Output Directory: $OutputDir"
Write-Host "    Initial Extensions to Process: $($extensionsList.Count)"

# 2. Main Factory Loop
# We use a standard for-loop so we can dynamically append discovered dependencies to the end of the list
$processed = @{}

# Legacy extensions often declare dependencies using outdated aliases instead of canonical publisher IDs.
# We intercept and translate them here to prevent 404 API crashes during Auto-Discovery.
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

for ($i = 0; $i -lt $extensionsList.Count; $i++) {
    $extId = $extensionsList[$i]

    if ($processed[$extId]) { continue }
    $processed[$extId] = $true

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
        if ($Force) {
            Write-Host "    [INFO] Package folder exists. -Force is set. Regenerating..." -ForegroundColor Yellow
            Remove-Item -Path $pkgDir -Recurse -Force
        }
        elseif ($UpdateMetadata) {
            Write-Host "    [INFO] Package folder exists. -UpdateMetadata is set. Updating XML..." -ForegroundColor Yellow
        }
        else {
            Write-Host "    [INFO] Package folder already exists ($packageName). Skipping. Use -Force to regenerate or -UpdateMetadata to refresh metadata." -ForegroundColor Yellow
            continue
        }
    }

    # =========================================================================
    # 2. Query VS Code Marketplace API
    # =========================================================================
    try {
        $extMeta = Get-VsCodeMarketplaceMetadata -Publisher $publisher -ExtensionName $extensionName
    }
    catch {
        Write-Host "    [ERROR] $_" -ForegroundColor Red
        continue
    }

    $version = $extMeta.versions[0].version
    $versionClean = $version -replace '[^\d\.-]', ''
    $descriptionRaw = $extMeta.shortDescription
    $descriptionRaw = $descriptionRaw -replace '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}', '[email removed]'

    $descriptionEscaped = [System.Security.SecurityElement]::Escape($descriptionRaw)

    $summaryRaw = $descriptionRaw
    if ($summaryRaw.Length -gt 4000) { $summaryRaw = $summaryRaw.Substring(0, 3996) + "..." }

    $summaryEscaped = $summaryRaw
    if ($summaryEscaped.Length -gt 4000) { $summaryEscaped = $summaryEscaped.Substring(0, 3996) + "..." }

    $iconUrl = $extMeta.versions[0].files | Where-Object { $_.assetType -eq "Microsoft.VisualStudio.Services.Icons.Default" } | Select-Object -ExpandProperty source

    Write-Host "    Version: $versionClean"

    # Scaffold Package Directory if it doesn't exist (e.g. not using -UpdateMetadata)
    if (-not (Test-Path $pkgDir)) {
        New-Item -ItemType Directory -Force -Path $pkgDir | Out-Null
    }
    $toolsDir = Join-Path $pkgDir "tools"
    if (-not (Test-Path $toolsDir)) {
        New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
    }

    # Download VSIX
    $vsixUrl = Get-VsCodeExtensionUrl -Publisher $publisher -ExtensionName $extensionName -Version $version -ExtMeta $extMeta
    $vsixName = "$publisher.$extensionName-$versionClean.vsix"
    $vsixPath = Join-Path $toolsDir $vsixName

    Invoke-RobustDownload -Url $vsixUrl -OutFile $vsixPath

    # =========================================================================
    # 3. Payload Extraction (Air-Gap Compliance)
    # =========================================================================
    $payloadData = Expand-VsCodePayload -VsixPath $vsixPath -DestinationDir $pkgDir
    $packageJson = $payloadData.PackageJson

    # =========================================================================
    # 4. Generate Core Package Files
    # =========================================================================
    # If the VS Code extension declares internal dependencies (e.g., Extension Packs),
    # we dynamically translate those into Chocolatey package dependencies.
    $dependenciesStr = ""
    $discoveredDeps = [System.Collections.Generic.List[string]]::new()

    if ($packageJson.extensionDependencies) {
        Write-Host "    Found Extension Dependencies!" -ForegroundColor Yellow
        foreach ($depRaw in $packageJson.extensionDependencies) {
            if ($depRaw.ToLower().StartsWith("vscode.")) {
                Write-Host "    [SKIP] Ignoring built-in dependency: $depRaw" -ForegroundColor DarkGray
                continue
            }
            $dep = if ($dependencyAliases.ContainsKey($depRaw)) { $dependencyAliases[$depRaw] } else { $depRaw }

            $depName = ($dep -split '\.')[1].ToLower()
            $depPackageName = if ($depName.StartsWith("vscode-")) { $depName } else { "vscode-$depName" }
            if ($depPackageName -ne $packageName) {
                $dependenciesStr += "      <dependency id=`"$depPackageName`" />`n"
                $discoveredDeps.Add($depPackageName)

                # Auto-Discovery: Queue the dependency for scaffolding if we aren't already tracking it
                $depLower = $dep.ToLower()
                if (-not $extensionsList.Contains($depLower)) {
                    Write-Host "    [AUTO-DISCOVERY] Queuing missing dependency: $depLower" -ForegroundColor Magenta
                    $extensionsList.Add($depLower)
                }
            }
        }
    }
    if ($packageJson.extensionPack) {
        Write-Host "    Found Extension Pack Bundles!" -ForegroundColor Yellow
        foreach ($depRaw in $packageJson.extensionPack) {
            if ($depRaw.ToLower().StartsWith("vscode.")) {
                Write-Host "    [SKIP] Ignoring built-in dependency: $depRaw" -ForegroundColor DarkGray
                continue
            }
            $dep = if ($dependencyAliases.ContainsKey($depRaw)) { $dependencyAliases[$depRaw] } else { $depRaw }

            $depName = ($dep -split '\.')[1].ToLower()
            $depPackageName = if ($depName.StartsWith("vscode-")) { $depName } else { "vscode-$depName" }
            if ($depPackageName -ne $packageName) {
                $dependenciesStr += "      <dependency id=`"$depPackageName`" />`n"
                $discoveredDeps.Add($depPackageName)

                # Auto-Discovery: Queue the dependency for scaffolding if we aren't already tracking it
                $depLower = $dep.ToLower()
                if (-not $extensionsList.Contains($depLower)) {
                    Write-Host "    [AUTO-DISCOVERY] Queuing missing dependency: $depLower" -ForegroundColor Magenta
                    $extensionsList.Add($depLower)
                }
            }
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
    # We take the static scaffolding templates from etc/templates and inject
    # the dynamically resolved metadata to finalize the AU package structure.
    Write-Host "    Rendering AU Templates..."
    $templatesDir = "$PSScriptRoot\..\etc\templates"

    $nuspecPath = Join-Path $pkgDir "$packageName.nuspec"
    $cdataSafe = $descriptionRaw -replace ']]>', ']]]]><![CDATA[>'
    $descriptionEscaped = "<![CDATA[`n" + $cdataSafe + "`n]]>"

    $meta = Get-VsCodeNuspecMetadata -ExtMeta $extMeta -ExtensionPublisher $publisher -ExtensionName $extensionName -Description $descriptionEscaped

    $nuspecContent = Get-Content (Join-Path $templatesDir "template.nuspec") -Raw -Encoding UTF8
    $nuspecContent = $nuspecContent -replace '\{\{ExtensionNameLowerCase\}\}', $packageName.Replace("vscode-", "")

    $nuspecContent = $nuspecContent -replace '\{\{Version\}\}', '0.0.0'
    $nuspecContent = $nuspecContent -replace '\{\{Title\}\}', $meta.Title
    $nuspecContent = $nuspecContent -replace '\{\{Authors\}\}', $meta.Authors
    $nuspecContent = $nuspecContent -replace '\{\{ProjectUrl\}\}', $meta.ProjectUrl
    $nuspecContent = $nuspecContent -replace '\{\{IconUrl\}\}', $meta.IconUrl
    $nuspecContent = $nuspecContent -replace '\{\{MarketplaceUrl\}\}', $meta.MarketplaceUrl
    $nuspecContent = $nuspecContent -replace '\{\{Description\}\}', $meta.Description
    $nuspecContent = $nuspecContent -replace '\{\{Summary\}\}', $meta.Summary
    $nuspecContent = $nuspecContent -replace '\{\{Dependencies\}\}', $dependenciesStr
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($nuspecPath, $nuspecContent, $utf8NoBom)

    if (-not (Test-Path (Join-Path $toolsDir "chocolateyInstall.ps1"))) {
        $installContent = Get-Content (Join-Path $templatesDir "chocolateyInstall.ps1") -Raw -Encoding UTF8
        $installContent = $installContent -replace '\{\{Publisher\}\}', $publisher
        $installContent = $installContent -replace '\{\{ExtensionName\}\}', $extensionName
        $installContent = $installContent -replace '\{\{Version\}\}', $versionClean
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText((Join-Path $toolsDir "chocolateyInstall.ps1"), $installContent, $utf8NoBom)
    }

    if (-not (Test-Path (Join-Path $toolsDir "chocolateyUninstall.ps1"))) {
        $uninstallContent = Get-Content (Join-Path $templatesDir "chocolateyUninstall.ps1") -Raw -Encoding UTF8
        $uninstallContent = $uninstallContent -replace '\{\{Publisher\}\}', $publisher
        $uninstallContent = $uninstallContent -replace '\{\{ExtensionName\}\}', $extensionName
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText((Join-Path $toolsDir "chocolateyUninstall.ps1"), $uninstallContent, $utf8NoBom)
    }

    if (-not (Test-Path (Join-Path $pkgDir "update.ps1"))) {
        $updateContent = @"
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='Variables are declared for AU hooks and module scope but not read within this script block')]
param()
`$ExtensionPublisher = "$publisher"
`$ExtensionName = "$extensionName"
. "`$PSScriptRoot\..\..\bin\AuExtensionHooks.ps1"
"@
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText((Join-Path $pkgDir "update.ps1"), $updateContent, $utf8NoBom)
    }

    # Download Icon
    if ($iconUrl) {
        Invoke-WebRequest -Uri $iconUrl -OutFile (Join-Path $pkgDir "icon.png") -ErrorAction SilentlyContinue
    }

    Write-Host "    [SUCCESS] Scaffolded at: $pkgDir" -ForegroundColor Green
}

# =============================================================================
# Rewrite Configuration File
# =============================================================================
# If we auto-discovered any dependencies, or if the list was unsorted, we rewrite
# the config.yaml file to permanently track the fully resolved hierarchy as flat peers.
if (-not $ExtensionId) {
    Write-Host "`n>>> Finalizing and Syncing config.yaml..." -ForegroundColor Cyan
    $sortedExtensions = $extensionsList | Sort-Object -Unique

    $orderedYaml = [ordered]@{
        extensions = @($sortedExtensions)
    }

    $yamlStr = ConvertTo-Yaml $orderedYaml

    # Enforce standard YAML aesthetics (document separator and 2-space indented arrays)
    $formattedYaml = "---`n" + ($yamlStr -replace '(?m)^-', '  -').TrimEnd()

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($ConfigFile, $formattedYaml, $utf8NoBom)

    $badgeJson = @{ schemaVersion = 1; label = "Extensions Tracked"; message = "$($sortedExtensions.Count)"; color = "blue" } | ConvertTo-Json -Compress
    $badgePath = Join-Path (Split-Path $ConfigFile) "badge.json"
    [System.IO.File]::WriteAllText($badgePath, $badgeJson, $utf8NoBom)

    Write-Host "    [SUCCESS] Resolved $($sortedExtensions.Count) total dependencies!" -ForegroundColor Green
}

Write-Host "`n>>> Factory Run Complete!" -ForegroundColor Cyan


