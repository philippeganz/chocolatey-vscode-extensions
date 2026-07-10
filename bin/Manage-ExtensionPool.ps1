<#
.SYNOPSIS
    The robust, scriptable CLI for managing the VS Code Extension Pool.

.DESCRIPTION
    A state-aware CLI that acts as the single entry point for adding, removing, and
    auditing Chocolatey VS Code extensions in this repository. It natively manages
    the config.yaml file and delegates scaffolding logic to the backend Factory API.

    Features:
    - Add/Remove extensions with complete lifecycle and state management.
    - Search the VS Code Marketplace API directly from the terminal.
    - Audit local directories against config.yaml tracking state.
    - Scan for stale packages on the Chocolatey Community Feed.

.PARAMETER Add
    An array of extension identifiers (Publisher.ExtensionName) to add to the pool.
    This triggers the Factory API to scaffold the new package automatically.

.PARAMETER Remove
    An array of extension identifiers to cleanly remove from the pool.
    Deletes the local scaffolding directory and removes the entry from config.yaml.

.PARAMETER Search
    A string query to search the live VS Code Marketplace API directly from the terminal.
    Useful for finding the exact unique identifier before running -Add.

.PARAMETER CheckStale
    Queries the public Chocolatey Community Feed to identify packages in our pool
    that are potentially out of sync or missing from the gallery.

.PARAMETER Audit
    Validates the local state of the 'automatic/' directory against the declared
    state in 'config.yaml', identifying ghost packages or missing scaffolding.

.EXAMPLE
    .\Manage-ExtensionPool.ps1 -Search "python"

.EXAMPLE
    .\Manage-ExtensionPool.ps1 -Add "ms-python.python"
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[CmdletBinding(DefaultParameterSetName = 'None')]
param (
    [Parameter(ParameterSetName = 'Add', Mandatory = $true)]
    [string[]]$Add,

    [Parameter(ParameterSetName = 'Remove', Mandatory = $true)]
    [string[]]$Remove,

    [Parameter(ParameterSetName = 'Search', Mandatory = $true)]
    [string]$Search,

    [Parameter(ParameterSetName = 'CheckStale', Mandatory = $true)]
    [switch]$CheckStale,

    [Parameter(ParameterSetName = 'Audit', Mandatory = $true)]
    [switch]$Audit
)

$ErrorActionPreference = 'Stop'

# =============================================================================
# 1. Initialization & Logging Helpers
# =============================================================================
$script:IsPS7 = $PSVersionTable.PSVersion.Major -ge 7

<#
.SYNOPSIS
A cross-platform helper for rendering colorized, structured console messages.
#>
function Write-StyledMessage {
    param(
        [Parameter(Mandatory = $true)][string]$Prefix,
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][ConsoleColor]$FallbackColor,
        [string]$AnsiColor
    )
    if ($script:IsPS7 -and $PSStyle) {
        Write-Host "$AnsiColor$Prefix$($PSStyle.Reset) $Message"
    }
    else {
        Write-Host "$Prefix " -ForegroundColor $FallbackColor -NoNewline
        Write-Host $Message
    }
}

<#
.SYNOPSIS
Writes a green success message to the console.
#>
function Write-Success ([string]$msg) { Write-StyledMessage -Prefix "[SUCCESS]" -Message $msg -FallbackColor Green -AnsiColor "`e[32m" }

<#
.SYNOPSIS
Writes a cyan info message to the console.
#>
function Write-Info    ([string]$msg) { Write-StyledMessage -Prefix "[INFO]"    -Message $msg -FallbackColor Cyan  -AnsiColor "`e[36m" }

<#
.SYNOPSIS
Writes a yellow skip message to the console.
#>
function Write-Skip    ([string]$msg) { Write-StyledMessage -Prefix "[SKIP]"    -Message $msg -FallbackColor Yellow -AnsiColor "`e[33m" }

<#
.SYNOPSIS
Writes a red error message to the console.
#>
function Write-Err     ([string]$msg) { Write-StyledMessage -Prefix "[ERROR]"   -Message $msg -FallbackColor Red   -AnsiColor "`e[31m" }

Import-Module "$PSScriptRoot\VsCodeMarketplace.psm1" -Force

# Load config.yaml safely
$configPath = Resolve-Path (Join-Path $PSScriptRoot "config.yaml") -ErrorAction SilentlyContinue
if (-not $configPath) {
    $configPath = Join-Path $PSScriptRoot "config.yaml"
}
if (-not (Get-Module -ListAvailable powershell-yaml)) {
    Write-Info "Installing required powershell-yaml module..."
    Install-Module powershell-yaml -Force -Scope CurrentUser
}
Import-Module powershell-yaml

# =============================================================================
# 2. State Management Helpers
# =============================================================================

<#
.SYNOPSIS
Reads and parses the config.yaml state tracker.

.OUTPUTS
A hashtable containing the raw parsed YAML and a populated List of tracked extensions.
#>
function Get-ConfigState {
    if (-not (Test-Path $configPath)) { throw "config.yaml not found at $($configPath)" }
    $yamlObj = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Yaml
    $extensions = [System.Collections.Generic.List[string]]::new()
    if ($yamlObj.extensions) {
        foreach ($ext in $yamlObj.extensions) {
            $extensions.Add([string]$ext.ToLower())
        }
    }
    return @{ Raw = $yamlObj; Extensions = $extensions }
}

<#
.SYNOPSIS
Saves the modified extension pool back to config.yaml safely.

.PARAMETER yamlObj
The original YAML object to preserve structure.

.PARAMETER extensionsList
The updated System.Collections.Generic.List of active extensions.
#>
function Save-ConfigState ([object]$yamlObj, [System.Collections.Generic.List[string]]$extensionsList) {
    $sortedExtensions = $extensionsList | Sort-Object -Unique
    $orderedYaml = [ordered]@{
        extensions = @($sortedExtensions)
    }
    $yamlStr = ConvertTo-Yaml $orderedYaml
    $formattedYaml = "---`n" + ($yamlStr -replace '(?m)^-', '  -').TrimEnd() + "`n"
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($configPath, $formattedYaml, $utf8NoBom)
    Write-Success "State saved to config.yaml ($($sortedExtensions.Count) total extensions tracked)."
}

# =============================================================================
# 3. Execution Logic
# =============================================================================
if ($PSCmdlet.ParameterSetName -eq 'Add') {
    Write-Info "Executing Pre-flight Checks for Add Operation..."
    $state = Get-ConfigState
    $validIds = [System.Collections.Generic.List[string]]::new()

    foreach ($id in $Add) {
        $cleanId = $id.ToLower()
        $parts = $cleanId -split '\.'
        if ($parts.Count -ne 2) {
            Write-Err "Invalid ID format for '$cleanId'. Must be 'publisher.extension'."
            continue
        }

        if ($state.Extensions.Contains($cleanId)) {
            Write-Skip "Extension '$cleanId' is already tracked in state."
            # We still add it to validIds so the Factory can force a regenerate if requested
            $validIds.Add($cleanId)
            continue
        }

        try {
            Write-Info "Pinging Marketplace API for $cleanId..."
            $meta = Get-VsCodeMarketplaceMetadata -Publisher $parts[0] -ExtensionName $parts[1]
            if ($meta) {
                Write-Success "Verified '$cleanId' exists on the VS Code Marketplace!"
                $state.Extensions.Add($cleanId)
                $validIds.Add($cleanId)
            }
        }
        catch {
            Write-Err "Marketplace API rejected '$cleanId' (404 Not Found or Invalid). Skipping."
        }
    }

    if ($validIds.Count -gt 0) {
        Write-Info "Invoking Factory API for scaffolding..."
        $factoryParams = @{
            ExtensionId = $validIds.ToArray()
            Force       = $true
        }
        $factoryPath = Join-Path $PSScriptRoot "Invoke-VsCodeExtensionFactory.ps1"
        $processedIds = & $factoryPath @factoryParams

        # The Factory returns all processed packages (including auto-discovered dependencies)
        if ($processedIds) {
            foreach ($p in $processedIds) {
                if (-not $state.Extensions.Contains($p)) {
                    Write-Info "Auto-discovered dependency '$p' appended to state."
                    $state.Extensions.Add($p)
                }
            }
        }
        Save-ConfigState $state.Raw $state.Extensions
    }
    else {
        Write-Skip "No valid packages were queued for the Factory."
    }
}
elseif ($PSCmdlet.ParameterSetName -eq 'Remove') {
    $state = Get-ConfigState
    $mutated = $false

    foreach ($id in $Remove) {
        $cleanId = $id.ToLower()
        if ($state.Extensions.Contains($cleanId)) {
            $state.Extensions.Remove($cleanId) | Out-Null
            $mutated = $true
            Write-Success "Removed '$cleanId' from config.yaml."
        }
        else {
            Write-Skip "'$cleanId' was not found in config.yaml."
        }

        $parts = $cleanId -split '\.'
        if ($parts.Count -eq 2) {
            $pkgName = $parts[1]
            if (-not $pkgName.StartsWith("vscode-")) { $pkgName = "vscode-$pkgName" }
            $baseAuto = if ($env:CHOCO_VSCODE_AUTOMATIC_DIR) { $env:CHOCO_VSCODE_AUTOMATIC_DIR } else { Join-Path (Split-Path $PSScriptRoot -Parent) "automatic" }
            $pkgDir = Join-Path $baseAuto $pkgName
            if (Test-Path $pkgDir) {
                Remove-Item -Path $pkgDir -Recurse -Force
                Write-Success "Deleted local package directory: $(Split-Path $baseAuto -Leaf)\$pkgName"
            }
        }
    }

    if ($mutated) {
        Save-ConfigState $state.Raw $state.Extensions
    }
}
elseif ($PSCmdlet.ParameterSetName -eq 'Search') {
    Write-Info "Querying VS Code Marketplace for: '$Search'"
    $bodyObj = @{
        filters = @(
            @{ criteria = @( @{ filterType = 10; value = $Search } ) }
        )
        flags   = 914
    }
    $bodyStr = $bodyObj | ConvertTo-Json -Depth 10 -Compress
    $url = "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
    $headers = @{
        "Accept"       = "application/json;api-version=3.0-preview.1"
        "Content-Type" = "application/json"
    }

    $response = Invoke-RestMethod -Method POST -Uri $url -Headers $headers -Body $bodyStr -ErrorAction Stop
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

    if ($results.Count -gt 0) {
        $results | Format-Table -AutoSize
    }
    else {
        Write-Skip "No extensions found matching that query."
    }
}
elseif ($CheckStale) {
    Write-Info "Scanning Chocolatey Community API for stale packages (> 3 months old)..."
    $autoDir = if ($env:CHOCO_VSCODE_AUTOMATIC_DIR) { $env:CHOCO_VSCODE_AUTOMATIC_DIR } else { Join-Path (Split-Path $PSScriptRoot -Parent) "automatic" }
    if (-not (Test-Path $autoDir)) { throw "Automatic directory not found." }
    $packages = (Get-ChildItem -Path $autoDir -Directory).Name

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $cutoff = (Get-Date).AddMonths(-3)
    $ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36"

    foreach ($pkg in $packages) {
        $nuspecPath = Join-Path -Path (Join-Path -Path $autoDir -ChildPath $pkg) -ChildPath "$pkg.nuspec"
        $localVersion = "Unknown"
        if (Test-Path $nuspecPath) {
            $xml = New-Object System.Xml.XmlDocument
            $xml.Load($nuspecPath)
            $localVersion = $xml.package.metadata.version
        }

        $url = "https://community.chocolatey.org/api/v2/Packages()?`$filter=Id eq '$pkg' and IsLatestVersion eq true"
        try {
            $c = (Invoke-WebRequest -Uri $url -UserAgent $ua -UseBasicParsing -ErrorAction Stop).Content
            if ($c -match '<d:Version[^>]*>(.*?)</d:Version>') {
                $remoteVersion = $matches[1]
                if ($c -match '<d:Published[^>]*>(.*?)</d:Published>') {
                    $published = [datetime]($matches[1])
                    if ($published -lt $cutoff -and $remoteVersion -ne $localVersion) {
                        $results.Add([PSCustomObject]@{
                                Package       = $pkg
                                RemoteVersion = $remoteVersion
                                LocalVersion  = $localVersion
                                MonthsStale   = [math]::Round(((Get-Date) - $published).TotalDays / 30.44, 1)
                            })
                    }
                }
            }
        }
        catch {
            # Ignore HTTP 404s for unpublished packages
            Write-Verbose $_
        }
    }

    if ($results.Count -gt 0) {
        $results | Sort-Object MonthsStale -Descending | Format-Table -AutoSize
    }
    else {
        Write-Success "All packages are perfectly up to date with the Community Feed!"
    }
}
elseif ($Audit) {
    Write-Info "Auditing state configuration against local directory structures..."
    $state = Get-ConfigState
    $autoDir = if ($env:CHOCO_VSCODE_AUTOMATIC_DIR) { $env:CHOCO_VSCODE_AUTOMATIC_DIR } else { Join-Path (Split-Path $PSScriptRoot -Parent) "automatic" }
    $directories = if (Test-Path $autoDir) { (Get-ChildItem -Path $autoDir -Directory).Name } else { @() }

    $expectedDirs = [System.Collections.Generic.List[string]]::new()
    foreach ($id in $state.Extensions) {
        $parts = $id -split '\.'
        if ($parts.Count -eq 2) {
            $pkgName = $parts[1]
            if (-not $pkgName.StartsWith("vscode-")) { $pkgName = "vscode-$pkgName" }
            $expectedDirs.Add($pkgName)
        }
    }

    $orphans = [System.Collections.Generic.List[string]]::new()
    foreach ($dir in $directories) {
        if (-not $expectedDirs.Contains($dir)) {
            $orphans.Add($dir)
        }
    }

    $missing = [System.Collections.Generic.List[string]]::new()
    foreach ($exp in $expectedDirs) {
        if (-not ($directories -contains $exp)) {
            $missing.Add($exp)
        }
    }

    if ($orphans.Count -gt 0) {
        Write-Err "Found $($orphans.Count) orphaned directories in /automatic that are NOT tracked in config.yaml:"
        $orphans | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
    }
    if ($missing.Count -gt 0) {
        Write-Err "Found $($missing.Count) tracked packages missing their /automatic directory scaffolds:"
        $missing | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
    }
    if ($orphans.Count -eq 0 -and $missing.Count -eq 0) {
        Write-Success "Audit Complete! The config.yaml state perfectly matches the local directory scaffolds."
    }
}
else {
    Write-Err "Please specify a valid operation: -Add, -Remove, -Search, -CheckStale, or -Audit"
}
