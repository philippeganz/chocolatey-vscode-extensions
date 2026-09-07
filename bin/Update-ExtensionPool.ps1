#Requires -Version 7.0

<#
.SYNOPSIS
    The core Orchestrator for the Chocolatey Automatic Updater (AU) Engine.

.DESCRIPTION
    This script is executed by the GitHub Actions CI/CD pipeline on a cron schedule
    (or manually via Workflow Dispatch). It acts as a switchboard to delegate operations
    between three distinct execution modes:

    1. Standard Cron Run:
       (Default) Scans all packages in the pool. AU natively compares upstream VS Code
       Marketplace versions against local Chocolatey state and pushes updates.

    2. Forced Run (-ForcedPackages):
       Forces AU to evaluate and build specific packages by overriding the AU Force flag,
       useful for emergency hotfixes or local testing.

    3. Moderation Repush (-ModerationRepush):
       Circumvents native AU logic by forcefully rewriting the local .nuspec version
       to 0.0.0. This generates a pristine payload that is force-pushed to the
       Chocolatey Moderation Queue to resolve reviewer rejections.

.PARAMETER ForcedPackages
    An array of package names to force-update, bypassing the native version-matching
    math. Supports wildcard resolution (e.g. "vscode-py*").

.PARAMETER ModerationRepush
    An array of package names (or '*' for all) to rebuild and push without
    running the standard AU pipeline. Supports wildcard resolution (e.g. "vscode-py*").

.PARAMETER PushUrl
    Overrides the default Chocolatey Community push endpoint with a custom NuGet
    repository URL (e.g. an internal Nexus v2 repository).

.PARAMETER AutomaticDir
    Absolute path to the automatic packages directory.

.EXAMPLE
    # 1. Standard run across all packages
    .\Invoke-AuUpdater.ps1

.EXAMPLE
    # 2. Force a run for specific packages with wildcards
    .\Invoke-AuUpdater.ps1 -ForcedPackages "vscode-python", "vscode-docker*"

.EXAMPLE
    # 3. Moderation repush to a custom internal Nexus endpoint
    .\Invoke-AuUpdater.ps1 -ModerationRepush "vscode-abc" -PushUrl "https://nexus.local/choco"
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Global variables are required for AU configuration and workflow state')]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string[]]$ForcedPackages,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string[]]$ModerationRepush,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrWhitespace()]
    [string]$PushUrl,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrWhitespace()]
    [string]$AutomaticDir = ($env:CHOCO_VSCODE_AUTOMATIC_DIR ?? "$PSScriptRoot\..\automatic")
)

# WARNING: The Chocolatey AU module relies on legacy PowerShell 5.1 native command argument parsing.
$global:PSNativeCommandArgumentPassing = 'Legacy'

# =============================================================================
# Import Modules
# =============================================================================
$env:PSModulePath = "$PSScriptRoot\..\lib;$env:PSModulePath"
Import-Module ChocoVSCodeCore
Import-Module ChocoVSCodeMarketplace
Import-Module au


# =============================================================================
# Environment / AU Pipeline Setup
# =============================================================================
if ($PushUrl) {
    $env:au_PushUrl = $PushUrl
    Write-Info "Retargeting AU Push to Internal Repository: $PushUrl"
}

$opts = @{
    NoCheckChocoVersion = $true
}

# =============================================================================
# Execution
# =============================================================================
if (-not (Test-Path $AutomaticDir)) { throw "Automatic directory not found: $AutomaticDir" }
Push-Location $AutomaticDir

try {
    # -------------------------------------------------------------------------
    # MODE 3: Moderation Repush
    # -------------------------------------------------------------------------
    if ($ModerationRepush) {
        $opts.Push = $false

        $raw = $ModerationRepush -join ',' -split ',' | ForEach-Object Trim | Where-Object { $_ -ne '' }
        $targetPackages = @(Get-Item -Path $raw -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer } | Select-Object -ExpandProperty Name)

        Write-StyledMessage -Color Cyan -Message "
>>> Handing off to native AU Engine..."

        foreach ($pkg in $targetPackages) {
            Write-StyledMessage -Color Cyan -Message "
Processing $pkg" -Indent 1

            $pkgDir = Join-Path $AutomaticDir $pkg
            if (-not (Test-Path $pkgDir)) { Write-Err "Not found: $pkg" -Indent 1; continue }

            Write-Info "Resetting .nuspec to 0.0.0 bypass..."
            $nuspecPath = Join-Path $pkgDir "$pkg.nuspec"
            if (Test-Path $nuspecPath) {
                $nuspec = [xml](Get-Content $nuspecPath -Encoding UTF8)
                $nuspec.package.metadata.version = '0.0.0'
                Save-NuspecXml -NuspecXml $nuspec -NuspecPath $nuspecPath
            }

            $infoPath = Join-Path $pkgDir "update_info.xml"
            if (Test-Path $infoPath) {
                Remove-Item $infoPath -Force
            }

            Write-Info "Compiling Package..."
            Update-AUPackages -Name $pkg -Options $opts

            Write-Info "Pushing Moderation Payload..." -Indent 2
            $nupkg = Get-ChildItem -Path $pkgDir -Filter "*.nupkg" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($nupkg) {
                if ($env:api_key) {
                    Write-Info "Force Pushing $($nupkg.Name)..." -Indent 2
                    $maxRetries = 3
                    $retryWait = 20
                    $pushSuccess = $false
                    $sourceUrl = if ($env:au_PushUrl) { $env:au_PushUrl } else { 'https://push.chocolatey.org' }

                    for ($i = 1; $i -le $maxRetries; $i++) {
                        $pushOutput = choco push $nupkg.FullName --source $sourceUrl --key $env:api_key --force 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            Write-Success "Push successful on attempt $i!" -Indent 2
                            $pushSuccess = $true
                            break
                        }

                        if ($pushOutput -match 'already exists|409') {
                            Write-Warn "Package is already approved (or version consumed) and cannot be overwritten. Proceeding..." -Indent 2
                            $pushSuccess = $true
                            break
                        }

                        Write-Warn "Push attempt $i failed for $($nupkg.Name): $pushOutput" -Indent 2
                        if ($i -lt $maxRetries) {
                            Write-Info "Waiting $retryWait seconds before retrying..." -Indent 2
                            Start-Sleep -Seconds $retryWait
                        }
                    }

                    if (-not $pushSuccess) {
                        throw "All $maxRetries push attempts failed for $($nupkg.Name)."
                    }
                }
                else {
                    Write-Warn "No api_key found. Skipping push for $($nupkg.Name)." -Indent 2
                }
            }
            else {
                Write-Err "No .nupkg was generated for $pkg!" -Indent 2
            }
        }
    }
    else {
        # ---------------------------------------------------------------------
        # MODE 2: Forced Run
        # ---------------------------------------------------------------------
        if ($ForcedPackages) {
            $opts.Force = $true

            $raw = $ForcedPackages -join ',' -split ',' | ForEach-Object Trim | Where-Object { $_ -ne '' }
            $targetPackages = @(Get-Item -Path $raw -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer } | Select-Object -ExpandProperty Name)
        }
        # ---------------------------------------------------------------------
        # MODE 1: Standard Cron Run
        # ---------------------------------------------------------------------
        else {
            $targetPackages = @(Get-ChildItem . -Directory | Select-Object -ExpandProperty Name)
        }

        Update-AUPackages -Name $targetPackages -Options $opts
    }
}
finally {

    Write-StyledMessage -Color Cyan -Message "`n>>> Restoring hidden README files..."
    $baks = Get-ChildItem -Path $AutomaticDir -Filter "README.md.bak" -Recurse -ErrorAction SilentlyContinue
    if ($baks) {
        foreach ($bak in $baks) {
            $md = Join-Path $bak.DirectoryName "README.md"
            Move-Item $bak.FullName $md -Force
        }
        Write-Success "Restored $($baks.Count) README.md files." -Indent 1
    }

    Pop-Location
}
