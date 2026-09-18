#Requires -Version 7.0
#Requires -Module ChocoVSCodeCore
#Requires -Module ChocoVSCodeMarketplace
#Requires -Module ChocoVSCodeExtensionManager

<#
.SYNOPSIS
    Monthly Health Check pipeline for the VS Code Extension Repository.

.DESCRIPTION
    This script is designed to be executed by the GitHub Actions monthly cron workflow.
    It performs three distinct health checks:
    1. Audit: Cross-references the extensions.json tracker against physical folders in /automatic.
    2. CheckStale: Scans the Chocolatey Community API for updates that haven't been published locally for > 3 months.
    3. CheckAge: Scans the VS Code Marketplace API for extensions abandoned by their author for > 3 years.

    The results are formatted into Markdown, appended to the GitHub Actions Step Summary,
    and written to 'health_report.md' for Issue creation. The script only exits non-zero if an API or file system failure occurs.
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is required for CI/CD console logging')]
param()

$ErrorActionPreference = 'Stop'

$rootDir = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../../"))
$StatePath = Join-Path $rootDir "var/state/extensions.json"
$AutomaticDir = Join-Path $rootDir "automatic"
$reportPath = Join-Path $rootDir "health_report.md"

$anomalyFound = $false

$markdown = @("# 🏥 VS Code Extension Repository - Monthly Health Report`n`n")
$markdown += "*Generated on $(Get-Date -Format 'yyyy-MM-dd')*`n`n"

# -----------------------------------------------------------------------------
# 1. AUDIT: Local Scaffolds vs State Tracker
# -----------------------------------------------------------------------------
Write-Host "`n>>> [1/3] Auditing state configuration against local directory structures..." -ForegroundColor Cyan
$state = [System.Collections.Generic.List[string]]::new([string[]](Get-ChocoVSCodeExtensionState -StatePath $StatePath))
$directories = if (Test-Path $AutomaticDir) { (Get-ChildItem -Path $AutomaticDir -Directory).Name } else { @() }

$expectedDirs = [System.Collections.Generic.List[string]]::new()
foreach ($id in $state) {
    $pkgName = Get-ChocoVSCodePackageName $id
    if ($pkgName) { $expectedDirs.Add($pkgName) }
}

$orphans = [System.Collections.Generic.List[string]]::new()
foreach ($dir in $directories) {
    if (-not $expectedDirs.Contains($dir)) { $orphans.Add($dir) }
}

$missing = [System.Collections.Generic.List[string]]::new()
foreach ($exp in $expectedDirs) {
    if (-not ($directories -contains $exp)) { $missing.Add($exp) }
}

$markdown += "## 📂 1. Architecture Audit`n"
if ($orphans.Count -eq 0 -and $missing.Count -eq 0) {
    $markdown += "✅ State tracker is perfectly synchronized with the File System.`n`n"
}
else {
    if ($orphans.Count -gt 0) {
        $anomalyFound = $true
        $markdown += "### ⚠️ Orphaned Directories (Not Tracked in JSON)`n"
        $orphans | ForEach-Object { $markdown += "- $_\`n" }
        $markdown += "`n"
    }
    if ($missing.Count -gt 0) {
        $anomalyFound = $true
        $markdown += "### ⚠️ Missing Scaffolds (Tracked in JSON but no folder exists)`n"
        $missing | ForEach-Object { $markdown += "- $_\`n" }
        $markdown += "`n"
    }
}

# -----------------------------------------------------------------------------
# 2. CHECK STALE & OWNERSHIP: Chocolatey Community API Check
# -----------------------------------------------------------------------------
Write-Host "`n>>> [2/4] Scanning Chocolatey Community API for stale packages and ownership issues..." -ForegroundColor Cyan
$staleResults = [System.Collections.Generic.List[PSCustomObject]]::new()
$ownershipResults = [System.Collections.Generic.List[PSCustomObject]]::new()
$binaryLitter = [System.Collections.Generic.List[string]]::new()

$cutoffStale = (Get-Date).AddMonths(-3)

foreach ($pkg in $directories) {
    $pkgDir = Join-Path -Path $AutomaticDir -ChildPath $pkg

    # Check for Binary Litter (.nupkg files left behind)
    $nupkgs = Get-ChildItem -Path $pkgDir -Filter "*.nupkg" -ErrorAction SilentlyContinue
    if ($nupkgs) {
        $nupkgs | ForEach-Object { $binaryLitter.Add($_.FullName.Replace($rootDir, '')) }
    }

    $nuspecPath = Join-Path -Path $pkgDir -ChildPath "$pkg.nuspec"
    $localVersion = "Unknown"
    if (Test-Path $nuspecPath) {
        $xml = [System.Xml.XmlDocument]::new()
        $xml.Load($nuspecPath)
        $localVersion = $xml.package.metadata.version
    }

    $url = "https://community.chocolatey.org/api/v2/Packages()?`$filter=Id eq '$pkg' and IsLatestVersion eq true"
    try {
        $c = (Invoke-WebRequest -Uri $url -UserAgent $ua -UseBasicParsing).Content

        # Ownership Check
        if ($c -match '<d:Owners[^>]*>(.*?)</d:Owners>') {
            $owners = $matches[1]
            if ($owners -notmatch 'philippe\.ganz') {
                $ownershipResults.Add([PSCustomObject]@{
                        Package = $pkg
                        Owners  = $owners
                    })
            }
        }

        # Stale Check
        if ($c -match '<d:Version[^>]*>(.*?)</d:Version>') {
            $remoteVersion = $matches[1]
            if ($c -match '<d:Published[^>]*>(.*?)</d:Published>') {
                $published = [datetime]($matches[1])
                if ($published -lt $cutoffStale -and $remoteVersion -ne $localVersion) {
                    $staleResults.Add([PSCustomObject]@{
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
        Write-Verbose "Package verification failed: $_"
    }
}

$markdown += "## 📦 2. Stale Chocolatey Packages`n"
$markdown += "*Packages where the local repo and the live Community Feed disagree, and the feed hasn't moved in 3 months (likely moderation queue issues).*`n`n"
if ($staleResults.Count -gt 0) {
    $anomalyFound = $true
    $markdown += "| Package | Local Version | Remote Version | Months Stale |`n|---|---|---|---|`n"
    $staleResults | Sort-Object MonthsStale -Descending | ForEach-Object {
        $markdown += "| $($_.Package) | $($_.LocalVersion) | $($_.RemoteVersion) | $($_.MonthsStale) |`n"
    }
    $markdown += "`n"
}
else {
    $markdown += "✅ All packages are up to date and successfully traversing the Chocolatey Moderation Queue.`n`n"
}

$markdown += "## 🔑 3. Ownership Verification Issues`n"
$markdown += "*Packages you are tracking locally but do not have 'philippe.ganz' listed as an owner on Chocolatey.*`n`n"
if ($ownershipResults.Count -gt 0) {
    $anomalyFound = $true
    $markdown += "| Package | Current Chocolatey Owners |`n|---|---|`n"
    $ownershipResults | ForEach-Object {
        $markdown += "| $($_.Package) | $($_.Owners) |`n"
    }
    $markdown += "`n"
}
else {
    $markdown += "✅ You have maintainer rights to all tracked packages on the Chocolatey Community feed.`n`n"
}

$markdown += "## 🗑️ 4. Binary Repository Litter`n"
$markdown += "*Compiled .nupkg files that were accidentally left behind in the repository (should be gitignored/cleaned).*`n`n"
if ($binaryLitter.Count -gt 0) {
    $anomalyFound = $true
    $binaryLitter | ForEach-Object { $markdown += "- $_\`n" }
    $markdown += "`n"
}
else {
    $markdown += "✅ No `.nupkg` binaries found cluttering the repository.`n`n"
}

# -----------------------------------------------------------------------------
# 3. CHECK AGE: VS Code Marketplace API Check
# -----------------------------------------------------------------------------
Write-Host "`n>>> [3/3] Scanning VS Code Marketplace for abandoned extensions (> 3 years old)..." -ForegroundColor Cyan
$ageResults = [System.Collections.Generic.List[PSCustomObject]]::new()

$chunkSize = 50

$marketplaceBaseUrl = "https://marketplace.visualstudio.com"
$url = "$marketplaceBaseUrl/_apis/public/gallery/extensionquery"
$headers = @{
    "Accept"       = "application/json;api-version=3.0-preview.1"
    "Content-Type" = "application/json"
}

$chunkIndex = 0
$stateChunks = $state | Group-Object -Property { [math]::Floor($script:chunkIndex++ / $chunkSize) }

foreach ($chunkGroup in $stateChunks) {
    $chunk = $chunkGroup.Group
    $criteria = $chunk | ForEach-Object { @{ filterType = 7; value = $_ } }
    $bodyObj = @{ filters = @( @{ criteria = @($criteria) } ); flags = 914 }
    $bodyStr = $bodyObj | ConvertTo-Json -Depth 10 -Compress

    try {
        $response = Invoke-WithMarketplaceRetry -Action {
            Invoke-RestMethod -Method POST -Uri $url -Headers $headers -Body $bodyStr
        } -ErrorMessage "Failed to query Marketplace"

        if ($response.results -and $response.results[0].extensions) {
            foreach ($extData in $response.results[0].extensions) {
                $health = Measure-VsCodeExtensionHealth -Metadata $extData
                if ($health.IsAbandonware) {
                    $ageResults.Add([PSCustomObject]@{
                            Extension   = "$($extData.publisher.publisherName).$($extData.extensionName)"
                            DisplayName = $extData.displayName
                            LastUpdated = $health.LastUpdated.ToString("yyyy-MM-dd")
                            YearsOld    = $health.YearsOld
                        })
                }
            }
        }
    }
    catch {
        Write-Warning "Failed chunk processing: $_"
    }
}

$markdown += "## 🕸️ 3. Abandoned Marketplace Extensions`n"
$markdown += "*Extensions that haven't been updated by their original author in over 3 years.*`n`n"
if ($ageResults.Count -gt 0) {
    $anomalyFound = $true
    $markdown += "| Extension | Display Name | Last Updated | Years Old |`n|---|---|---|---|`n"
    $ageResults | Sort-Object YearsOld -Descending | ForEach-Object {
        $markdown += "| $($_.Extension) | $($_.DisplayName) | $($_.LastUpdated) | $($_.YearsOld) |`n"
    }
    $markdown += "`n"
}
else {
    $markdown += "✅ No severely abandoned extensions detected in the pool.`n`n"
}

# -----------------------------------------------------------------------------
# FINALIZATION
# -----------------------------------------------------------------------------
$markdown | Out-File $reportPath -Encoding UTF8 -Force
Write-Host "`n[SUCCESS] Health Report generated at $reportPath!" -ForegroundColor Green

if ($env:GITHUB_STEP_SUMMARY) {
    $markdown | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append -Encoding UTF8
}
if ($anomalyFound) {
    Write-Error 'Anomalies detected during the Health Check. Failing pipeline to trigger email notification.'
    exit 1
}
else {
    exit 0
}
