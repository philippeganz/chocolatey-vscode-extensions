#Requires -Version 7.0

<#
.SYNOPSIS
    The robust, scriptable CLI for managing the VS Code Extension Pool.

.DESCRIPTION
    A state-aware CLI that acts as the single entry point for adding, removing, and
    auditing Chocolatey VS Code extensions in this repository. It natively manages
    the extensions.json file and delegates scaffolding logic to the backend Factory API.

    Features:
    - Add/Remove extensions with complete lifecycle and state management.
    - Search the VS Code Marketplace API directly from the terminal.
    - Audit local directories against extensions.json tracking state.
    - Scan for stale packages on the Chocolatey Community Feed.

.PARAMETER Add
    An array of extension identifiers (Publisher.ExtensionName) to add to the pool.
    This triggers the Factory API to scaffold the new package automatically.

.PARAMETER Remove
    An array of extension identifiers to cleanly remove from the pool.
    Deletes the local scaffolding directory and removes the entry from extensions.json.

.PARAMETER Search
    A string query to search the live VS Code Marketplace API directly from the terminal.
    Useful for finding the exact unique identifier before running -Add.

.PARAMETER CheckStale
    Queries the public Chocolatey Community Feed to identify packages in our pool
    that are potentially out of sync or missing from the gallery.

.PARAMETER AutoCommit
    If specified alongside -Add or -Remove, automatically performs a git commit using the generic Checkpoint-GitRepository module after the operation completes.

.PARAMETER CheckAge
    Queries the VS Code Marketplace API in bulk to identify active extensions that haven't received an update from their publisher in over 3 years (abandoned extensions).

.PARAMETER Audit
    Validates the local state of the 'automatic/' directory against the declared
    state in 'extensions.json', identifying ghost packages or missing scaffolding.

.EXAMPLE
    .\Manage-ExtensionPool.ps1 -Search "python"

.EXAMPLE
    .\Manage-ExtensionPool.ps1 -Add "ms-python.python"

.INPUTS
    None

.OUTPUTS
    None

.NOTES
    This script is the human-facing orchestrator. It safely bridges the gap between the
    Factory (`Add-VSCodeExtension`) and the Shredder (`Remove-VSCodeExtension`).
#>

[CmdletBinding(DefaultParameterSetName = 'None')]
param (
    [Parameter(ParameterSetName = 'Add', Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Add,

    [Parameter(ParameterSetName = 'Add', Mandatory = $false)]
    [Parameter(ParameterSetName = 'Remove', Mandatory = $false)]
    [switch]$Force,

    [Parameter(ParameterSetName = 'Remove', Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Remove,

    [Parameter(ParameterSetName = 'Add', Mandatory = $false)]
    [Parameter(ParameterSetName = 'Remove', Mandatory = $false)]
    [switch]$AutoCommit,

    [Parameter(ParameterSetName = 'Search', Mandatory = $true)]
    [ValidateNotNullOrWhiteSpace()]
    [string]$Search,

    [Parameter(ParameterSetName = 'CheckStale', Mandatory = $true)]
    [switch]$CheckStale,

    [Parameter(ParameterSetName = 'CheckAge', Mandatory = $true)]
    [switch]$CheckAge,

    [Parameter(ParameterSetName = 'Audit', Mandatory = $true)]
    [switch]$Audit
)

# =============================================================================
# Global Error Handling
# =============================================================================
# Enforce strict fail-fast behavior across this entire script/module.
# Any cmdlet or module import failure will immediately throw a terminating error.
# Override locally with -ErrorAction SilentlyContinue when needed.
$ErrorActionPreference = 'Stop'

# =============================================================================
# Import Modules
# =============================================================================
$env:PSModulePath = "$PSScriptRoot\..\lib;$env:PSModulePath"
Import-Module ChocoVSCodeCore
Import-Module ChocoVSCodeMarketplace
Import-Module ChocoVSCodeExtensionManager

# =============================================================================
# 1. State Initialization
# =============================================================================
# Load extensions.json safely
$repoRoot = (Split-Path $PSScriptRoot -Parent)
$StatePath = Join-Path $repoRoot "var\state\extensions.json"
$AutomaticDir = Join-Path $repoRoot "automatic"
$TemplatesDir = Join-Path $repoRoot "etc\templates"

# =============================================================================
# 2. Execution Logic
# =============================================================================
if ($PSCmdlet.ParameterSetName -eq 'Add') {
    Write-Info "Executing Pre-flight Checks for Add Operation..."
    $state = [System.Collections.Generic.List[string]]::new([string[]](Get-ChocoVSCodeExtensionState -StatePath $StatePath))

    # Natively deduplicate the input array to prevent redundant validation loops
    [string[]]$uniqueAdd = $Add | Select-Object -Unique
    $addList = [System.Collections.Generic.List[string]]::new($uniqueAdd)
    for ($i = 0; $i -lt $addList.Count; $i++) {
        $id = $addList[$i]
        $cleanId = $id.ToLower()

        Write-StyledMessage -Color Cyan -Message "`n================================================================================"
        Write-StyledMessage -Color Cyan -Message " QUEUED: $cleanId"
        Write-StyledMessage -Color Cyan -Message "================================================================================"

        $parts = $cleanId -split '\.'
        if ($parts.Count -ne 2) {
            Write-Err "Invalid ID format for '$cleanId'. Must be 'publisher.extension'."
            continue
        }

        # Strict Regex validation according to VS Code Marketplace rules
        if ($cleanId -notmatch '^[a-z0-9-]+\.[a-z0-9-]+$') {
            Write-Err "Invalid characters in '$cleanId'. Publisher and Extension names must contain only lowercase alphanumeric characters and hyphens."
            continue
        }

        if (($state.Contains($cleanId))) {
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
                        Write-StyledMessage -Color Yellow -Message "Extension '$cleanId' is deprecated, but -Force was specified. Proceeding."
                    }
                }

                Write-Success "Verified '$cleanId' exists on the VS Code Marketplace!"

                $baseAuto = $AutomaticDir
                $pkgName = Get-ChocoVSCodePackageName $cleanId
                if ((Test-Path (Join-Path $baseAuto $pkgName)) -and (-not $Force)) {
                    Write-Err "Package directory '$pkgName' already exists but is not tracked. Aborting to prevent adoption of unverified files. Use -Force to overwrite."
                    continue
                }

                if (-not ($state.Contains($cleanId))) {
                    $state.Add($cleanId)
                }

                Write-Info "Invoking Factory API for scaffolding $cleanId..."
                $factoryParams = @{
                    ExtensionId  = $cleanId
                    StatePath    = $StatePath
                    AutomaticDir = $AutomaticDir
                    TemplatesDir = $TemplatesDir
                    Force        = $Force.IsPresent
                }
                $discoveredDeps = Add-VSCodeExtension @factoryParams

                # Save state
                Save-ChocoVSCodeExtensionState -StatePath $StatePath -ExtensionsList $state
                if ($AutoCommit) {
                    Checkpoint-GitRepository -ExtensionId $cleanId -CommitMessage "Add new $cleanId extension"
                }

                # --------------------------------------------------------------------------------
                # Dependency DAG Resolution (Add Mode)
                # --------------------------------------------------------------------------------
                # Instead of recursively spawning new Factory processes (which loses visibility
                # and complicates error handling), the Factory simply returns a list of any
                # untracked dependencies it discovered during scaffolding.
                # We dynamically append them to our local $addList queue. Since the main loop
                # iterates over $addList, these new dependencies will be natively processed
                # in subsequent iterations within this exact same runspace.
                # --------------------------------------------------------------------------------
                if ($discoveredDeps) {
                    foreach ($dep in $discoveredDeps) {
                        $depLower = $dep.ToLower()
                        if (-not $addList.Contains($depLower)) {
                            Write-StyledMessage -Color Magenta -Message "`n    [POOL] Discovered untracked dependency '$depLower'. Queueing..."
                            $addList.Add($depLower)
                        }
                    }
                }
            }
        }
        catch {
            $errMessage = $_.Exception.Message
            if ($errMessage -match 'MarketplaceThrottlingError') {
                Write-Err "ABORTING: VS Code Marketplace is throttling requests. This is a rate-limit error, not a 404."
                throw $_
            }
            Write-Err "Marketplace API rejected '$cleanId' (404 Not Found or Invalid). Skipping. Details: $errMessage"
        }
    }
}
elseif ($PSCmdlet.ParameterSetName -eq 'Remove') {
    foreach ($id in $Remove) {
        $cleanId = $id.ToLower()
        Write-Info "Invoking Shredder for removal of $cleanId..."
        $shredderParams = @{
            ExtensionId  = @($cleanId)
            StatePath    = $StatePath
            AutomaticDir = $AutomaticDir
            Force        = $Force.IsPresent
        }
        Remove-VSCodeExtension @shredderParams
        if ($AutoCommit) {
            Checkpoint-GitRepository -ExtensionId $cleanId -CommitMessage "Remove $cleanId extension"
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
    $marketplaceBaseUrl = "https://marketplace.visualstudio.com"
    $url = "$marketplaceBaseUrl/_apis/public/gallery/extensionquery"
    $headers = @{
        "Accept"       = "application/json;api-version=3.0-preview.1"
        "Content-Type" = "application/json"
    }

    $response = Invoke-WithMarketplaceRetry -Action {
        Invoke-RestMethod -Method POST -Uri $url -Headers $headers -Body $bodyStr
    } -ErrorMessage "VS Code Marketplace API failed"

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
    $autoDir = $AutomaticDir
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
            $c = (Invoke-WebRequest -Uri $url -UserAgent $ua -UseBasicParsing).Content
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
    $state = [System.Collections.Generic.List[string]]::new([string[]](Get-ChocoVSCodeExtensionState -StatePath $StatePath))
    $cutoff = (Get-Date).AddYears(-3)

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    # Query Marketplace API in chunks of 50
    $chunkSize = 50
    $total = $state.Count
    $marketplaceBaseUrl = "https://marketplace.visualstudio.com"
    $url = "$marketplaceBaseUrl/_apis/public/gallery/extensionquery"
    $headers = @{
        "Accept"       = "application/json;api-version=3.0-preview.1"
        "Content-Type" = "application/json"
    }

    for ($i = 0; $i -lt $total; $i += $chunkSize) {
        $chunk = $state | Select-Object -Skip $i -First $chunkSize
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
            $response = Invoke-WithMarketplaceRetry -Action {
                Invoke-RestMethod -Method POST -Uri $url -Headers $headers -Body $bodyStr
            } -ErrorMessage "Failed to query a chunk of extensions from the Marketplace API"

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
    $state = [System.Collections.Generic.List[string]]::new([string[]](Get-ChocoVSCodeExtensionState -StatePath $StatePath))
    $autoDir = $AutomaticDir
    $directories = if (Test-Path $autoDir) { (Get-ChildItem -Path $autoDir -Directory).Name } else { @() }

    $expectedDirs = [System.Collections.Generic.List[string]]::new()
    foreach ($id in $state) {
        $pkgName = Get-ChocoVSCodePackageName $id
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
        Write-Err "Found $($orphans.Count) orphaned directories in /automatic that are NOT tracked in extensions.json:"
        $orphans | ForEach-Object { Write-StyledMessage -Color Red -Message "    - $_" }
    }
    if ($missing.Count -gt 0) {
        Write-Err "Found $($missing.Count) tracked packages missing their /automatic directory scaffolds:"
        $missing | ForEach-Object { Write-StyledMessage -Color Red -Message "    - $_" }
    }
    if ($orphans.Count -eq 0 -and $missing.Count -eq 0) {
        Write-Success "Audit Complete! The extensions.json state perfectly matches the local directory scaffolds."
    }
}
else {
    Write-Err "Please specify a valid operation: -Add, -Remove, -Search, -CheckStale, -CheckAge, or -Audit"
}
