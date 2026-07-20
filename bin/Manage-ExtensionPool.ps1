#Requires -Version 7.0
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
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is required for CI/CD logging and workflow orchestration')]
[CmdletBinding(DefaultParameterSetName = 'None')]
param (
    [Parameter(ParameterSetName = 'Add', Mandatory = $true)]
    [string[]]$Add,

    [Parameter(ParameterSetName = 'Add', Mandatory = $false)]
    [Parameter(ParameterSetName = 'Remove', Mandatory = $false)]
    [switch]$Force,

    [Parameter(ParameterSetName = 'Remove', Mandatory = $true)]
    [string[]]$Remove,

    [Parameter(ParameterSetName = 'Add', Mandatory = $false)]
    [Parameter(ParameterSetName = 'Remove', Mandatory = $false)]
    [switch]$AutoCommit,

    [Parameter(ParameterSetName = 'Search', Mandatory = $true)]
    [string]$Search,

    [Parameter(ParameterSetName = 'CheckStale', Mandatory = $true)]
    [switch]$CheckStale,

    [Parameter(ParameterSetName = 'CheckAge', Mandatory = $true)]
    [switch]$CheckAge,

    [Parameter(ParameterSetName = 'Audit', Mandatory = $true)]
    [switch]$Audit
)

$ErrorActionPreference = 'Stop'

# =============================================================================
# 1. Initialization & Logging Helpers
# =============================================================================
Import-Module "$PSScriptRoot\..\lib\CoreHelpers.psm1" -ErrorAction Stop
Import-Module "$PSScriptRoot\..\lib\ConfigHelpers.psm1" -ErrorAction Stop
Import-Module "$PSScriptRoot\..\lib\VsCodeMarketplace.psm1" -ErrorAction Stop

# Load config.yaml safely
$configPath = Resolve-Path "$PSScriptRoot\..\etc\config.yaml" -ErrorAction SilentlyContinue
if (-not $configPath) {
    $configPath = "$PSScriptRoot\..\etc\config.yaml"
}
else {
    $configPath = $configPath.Path
}

# =============================================================================
# 3. Execution Logic
# =============================================================================
if ($PSCmdlet.ParameterSetName -eq 'Add') {
    Write-Info "Executing Pre-flight Checks for Add Operation..."
    $state = Get-ConfigState -ConfigPath $configPath

    foreach ($id in $Add) {
        $cleanId = $id.ToLower()
        $parts = $cleanId -split '\.'
        if ($parts.Count -ne 2) {
            Write-Err "Invalid ID format for '$cleanId'. Must be 'publisher.extension'."
            continue
        }

        if ($state.Extensions.Contains($cleanId)) {
            if ($Force) {
                Write-Info "Extension '$cleanId' is already tracked, but -Force was requested. Regenerating..."
            }
            else {
                Write-Skip "Extension '$cleanId' is already tracked in state. Use -Force to regenerate."
                continue
            }
        }

        try {
            Write-Info "Pinging Marketplace API for $cleanId..."
            $meta = Get-VsCodeMarketplaceMetadata -Publisher $parts[0] -ExtensionName $parts[1]
            if ($meta) {
                if (($meta.displayName -match '(?i)deprecated') -or ($meta.shortDescription -match '(?i)deprecated')) {
                    if (-not $Force) {
                        Write-Err "Extension '$cleanId' is marked as deprecated by the author. Aborting. Use -Force to add it anyway."
                        continue
                    }
                    else {
                        Write-Yellow "Extension '$cleanId' is deprecated, but -Force was specified. Proceeding."
                    }
                }

                Write-Success "Verified '$cleanId' exists on the VS Code Marketplace!"

                $baseAuto = Get-AutomaticDirectory
                $pkgName = Get-ChocoPackageName $cleanId
                if ((Test-Path (Join-Path $baseAuto $pkgName)) -and (-not $Force)) {
                    Write-Err "Package directory '$pkgName' already exists but is not tracked. Aborting to prevent adoption of unverified files. Use -Force to overwrite."
                    continue
                }

                if (-not $state.Extensions.Contains($cleanId)) {
                    $state.Extensions.Add($cleanId)
                }

                Write-Info "Invoking Factory API for scaffolding $cleanId..."
                $factoryParams = @{
                    ExtensionId = @($cleanId)
                    Force       = $Force.IsPresent
                }
                $factoryPath = Join-Path $PSScriptRoot "Invoke-ExtensionFactory.ps1"
                & $factoryPath @factoryParams

                # Save state
                Save-ConfigState -ConfigPath $configPath -ExtensionsList $state.Extensions

                if ($AutoCommit) {
                    Write-Info "Evaluating git state for auto-commit of $cleanId..."
                    git add "etc/config.yaml"
                    git add "etc/badge.json"
                    $baseAuto = Get-AutomaticDirectory
                    $pkgName = Get-ChocoPackageName $cleanId

                    if (Test-Path (Join-Path $baseAuto $pkgName)) {
                        git add (Join-Path $baseAuto $pkgName)
                    }

                    $staged = git diff --name-only --cached
                    if (-not $staged) {
                        Write-Skip "No git changes detected for $cleanId. Skipping auto-commit."
                    }
                    else {
                        $msg = "Add new $cleanId extension"
                        [void](git commit -m $msg)
                        Write-Success "Auto-Committed: '$msg'"
                    }
                }
            }
        }
        catch {
            Write-Err "Marketplace API rejected '$cleanId' (404 Not Found or Invalid). Skipping."
        }
    }
}
elseif ($PSCmdlet.ParameterSetName -eq 'Remove') {
    foreach ($id in $Remove) {
        $cleanId = $id.ToLower()
        Write-Info "Invoking Shredder for removal of $cleanId..."
        $shredderParams = @{
            ExtensionId = @($cleanId)
            Force       = $Force.IsPresent
        }
        $shredderPath = Join-Path $PSScriptRoot "Invoke-ExtensionShredder.ps1"
        & $shredderPath @shredderParams

        if ($AutoCommit) {
            Write-Info "Evaluating git state for auto-commit of $cleanId..."
            git add "etc/config.yaml"
            git add "etc/badge.json"
            $baseAuto = Get-AutomaticDirectory

            $pkgName = Get-ChocoPackageName $cleanId
            if ($pkgName) {
                # Suppress errors in case the package wasn't scaffolded or tracked in git
                git add --all (Join-Path $baseAuto $pkgName) 2>$null
            }

            $staged = git diff --name-only --cached
            if (-not $staged) {
                Write-Skip "No git changes detected for $cleanId. Skipping auto-commit."
            }
            else {
                $msg = "Remove $cleanId extension"
                [void](git commit -m $msg)
                Write-Success "Auto-Committed: '$msg'"
            }
        }
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
    $autoDir = Get-AutomaticDirectory
    if (-not (Test-Path $autoDir)) { throw "Automatic directory not found." }
    $packages = (Get-ChildItem -Path $autoDir -Directory).Name

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $cutoff = (Get-Date).AddMonths(-3)
    $ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36"

    foreach ($pkg in $packages) {
        $nuspecPath = Join-Path -Path (Join-Path -Path $autoDir -ChildPath $pkg) -ChildPath "$pkg.nuspec"
        $localVersion = "Unknown"
        if (Test-Path $nuspecPath) {
            $xml = [System.Xml.XmlDocument]::new()
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
            Write-Verbose "Package '$pkg' could not be queried from Chocolatey API (likely unpublished). Error: $_"
        }
    }

    if ($results.Count -gt 0) {
        $results | Sort-Object MonthsStale -Descending | Format-Table -AutoSize
    }
    else {
        Write-Success "All packages are perfectly up to date with the Community Feed!"
    }
}
elseif ($CheckAge) {
    Write-Info "Scanning VS Code Marketplace for abandoned extensions (> 3 years old)..."
    $state = Get-ConfigState -ConfigPath $configPath
    $cutoff = (Get-Date).AddYears(-3)

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    # Query Marketplace API in chunks of 50
    $chunkSize = 50
    $total = $state.Extensions.Count
    $url = "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
    $headers = @{
        "Accept"       = "application/json;api-version=3.0-preview.1"
        "Content-Type" = "application/json"
    }

    for ($i = 0; $i -lt $total; $i += $chunkSize) {
        $chunk = $state.Extensions | Select-Object -Skip $i -First $chunkSize
        $criteria = @()
        foreach ($ext in $chunk) {
            $criteria += @{ filterType = 7; value = $ext }
        }

        $bodyObj = @{
            filters = @( @{ criteria = $criteria } )
            flags   = 914
        }
        $bodyStr = $bodyObj | ConvertTo-Json -Depth 10 -Compress

        try {
            $response = Invoke-RestMethod -Method POST -Uri $url -Headers $headers -Body $bodyStr -ErrorAction Stop
            if ($response.results -and $response.results[0].extensions) {
                foreach ($extData in $response.results[0].extensions) {
                    $lastUpdatedStr = $extData.versions[0].lastUpdated
                    if ($lastUpdatedStr) {
                        $lastUpdated = [datetime]$lastUpdatedStr
                        if ($lastUpdated -lt $cutoff) {
                            $results.Add([PSCustomObject]@{
                                Extension   = "$($extData.publisher.publisherName).$($extData.extensionName)"
                                DisplayName = $extData.displayName
                                LastUpdated = $lastUpdated.ToString("yyyy-MM-dd")
                                YearsOld    = [math]::Round(((Get-Date) - $lastUpdated).TotalDays / 365.25, 1)
                            })
                        }
                    }
                }
            }
        }
        catch {
            Write-Warning "Failed to query a chunk of extensions from the Marketplace API: $_"
        }
    }

    if ($results.Count -gt 0) {
        $results | Sort-Object YearsOld -Descending | Format-Table -AutoSize
    }
    else {
        Write-Success "All extensions have been updated within the last 3 years!"
    }
}
elseif ($Audit) {
    Write-Info "Auditing state configuration against local directory structures..."
    $state = Get-ConfigState -ConfigPath $configPath
    $autoDir = Get-AutomaticDirectory
    $directories = if (Test-Path $autoDir) { (Get-ChildItem -Path $autoDir -Directory).Name } else { @() }

    $expectedDirs = [System.Collections.Generic.List[string]]::new()
    foreach ($id in $state.Extensions) {
        $pkgName = Get-ChocoPackageName $id
        if ($pkgName) {
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
        $orphans | ForEach-Object { Write-Red "    - $_" }
    }
    if ($missing.Count -gt 0) {
        Write-Err "Found $($missing.Count) tracked packages missing their /automatic directory scaffolds:"
        $missing | ForEach-Object { Write-Red "    - $_" }
    }
    if ($orphans.Count -eq 0 -and $missing.Count -eq 0) {
        Write-Success "Audit Complete! The config.yaml state perfectly matches the local directory scaffolds."
    }
}
else {
    Write-Err "Please specify a valid operation: -Add, -Remove, -Search, -CheckStale, -CheckAge, or -Audit"
}
