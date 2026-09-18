#Requires -Version 7.0
#Requires -Module ChocoVSCodeCore
#Requires -Module ChocoVSCodeMarketplace
#Requires -Module ChocoVSCodeExtensionManager

<#
.SYNOPSIS
    The core Orchestrator for the VS Code Extension Pool.

.DESCRIPTION
    A state-aware CLI that acts as the single entry point for adding, removing, and
    auditing Chocolatey VS Code extensions in this repository. It natively manages
    the extensions.json file and delegates scaffolding logic to the backend Factory API.

    Features:
    - Add/Remove extensions with complete lifecycle and state management.
    - Search the VS Code Marketplace API directly from the terminal.
    - Issue Ops Integration (CI exit codes).

.PARAMETER Add
    An array of extension identifiers to generate or update in the pool.
    Example: 'ms-python.python'

.PARAMETER Remove
    An array of extension identifiers to cleanly remove from the pool.
    Deletes the local scaffolding directory and removes the entry from extensions.json.

.PARAMETER Search
    A string query to search the live VS Code Marketplace API directly from the terminal.
    Useful for finding the exact unique identifier before running -Add.

.PARAMETER Force
    If specified, aggressively overrides dependency protection mechanisms, or bypasses
    "Already Tracked" protections to forcefully regenerate an existing package.

.PARAMETER CI
    If specified, runs the script in Issue Ops Pipeline mode. Instead of gracefully
    skipping errors, the script will forcefully terminate the host process and bubble
    up strict Enum exit codes to the GitHub Actions runner.

.EXAMPLE
    .\Manage-ExtensionPool.ps1 -Search "ms-python.python"
    .\Manage-ExtensionPool.ps1 -Add "ms-vscode.cpptools"
    .\Manage-ExtensionPool.ps1 -Remove "formulahendry.code-runner" -Force

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
    [Parameter(Mandatory = $true, ParameterSetName = 'Add')]
    [string[]]
    $Add,

    [Parameter(Mandatory = $true, ParameterSetName = 'Remove')]
    [string[]]
    $Remove,

    [Parameter(Mandatory = $true, ParameterSetName = 'Search')]
    [string]
    $Search,

    [Parameter(ParameterSetName = 'Add', Mandatory = $false)]
    [Parameter(ParameterSetName = 'Remove', Mandatory = $false)]
    [switch]
    $Force,

    [Parameter(ParameterSetName = 'Add', Mandatory = $false)]
    [Parameter(ParameterSetName = 'Remove', Mandatory = $false)]
    [switch]
    $CI,

    [Parameter(ParameterSetName = 'Add', Mandatory = $false)]
    [Parameter(ParameterSetName = 'Remove', Mandatory = $false)]
    [switch]
    $AutoCommit
)

$ErrorActionPreference = 'Stop'

$StatePath = Join-Path $PSScriptRoot "..\var\state\extensions.json"
$AutomaticDir = Join-Path $PSScriptRoot "..\automatic"
$TemplatesDir = Join-Path $PSScriptRoot "..\etc\templates"

$ciOutputMap = @{}

# =============================================================================
# Orchestrator Execution Logic
# =============================================================================
if ($PSCmdlet.ParameterSetName -eq 'Add') {
    Write-Info "Executing Pre-flight Checks for Add Operation..."
    $stateResult = Get-ChocoVSCodeExtensionState -StatePath $StatePath
    $state = [System.Collections.Generic.List[string]]::new()
    if ($null -ne $stateResult) { $state.AddRange([string[]]$stateResult) }

    [string[]]$uniqueAdd = $Add | Select-Object -Unique
    $addList = [System.Collections.Generic.List[string]]::new($uniqueAdd)

    for ($i = 0; $i -lt $addList.Count; $i++) {
        $id = $addList[$i]
        $cleanId = $id.ToLower()

        Write-StyledMessage -Color Cyan -Message "`n================================================================================"
        Write-StyledMessage -Color Cyan -Message " QUEUED: $cleanId"
        Write-StyledMessage -Color Cyan -Message "================================================================================"

        $eligibility = Measure-VsCodeExtensionEligibility -ExtensionId $cleanId -CurrentState $state

        $ciOutputMap[$cleanId] = @{
            ReturnCode = [int]$eligibility.State
            Message    = $eligibility.Message
        }

        if ($eligibility.State -eq [ExtensionEligibilityState]::AlreadyTracked -and $Force) {
            Write-Info "Extension '$cleanId' is already tracked, but -Force was requested. Regenerating..."
        }
        elseif ($eligibility.State -ne [ExtensionEligibilityState]::Eligible) {
            Write-Skip "[$([int]$eligibility.State)] Request Denied for '$cleanId': $($eligibility.Message)"
            if ($CI) { exit ([int]$eligibility.State) }
            continue
        }

        try {
            Write-Info "Invoking Factory API for scaffolding $cleanId..."
            $factoryParams = @{
                ExtensionId  = $cleanId
                StatePath    = $StatePath
                AutomaticDir = $AutomaticDir
                TemplatesDir = $TemplatesDir
                Force        = $Force
            }
            $newDeps = Add-VSCodeExtension @factoryParams
            if ($newDeps) {
                foreach ($dep in $newDeps) {
                    $depLower = $dep.ToLower()
                    if (-not $addList.Contains($depLower)) {
                        Write-StyledMessage -Color Magenta -Message "`n    [POOL] Discovered untracked dependency '$depLower'. Queueing..."
                        $addList.Add($depLower)
                    }
                }
            }

            if ($AutoCommit) {
                Checkpoint-GitRepository -ExtensionId $cleanId -CommitMessage "Add new $cleanId extension" -StatePath $StatePath -AutomaticDir $AutomaticDir
            }

            $ciOutputMap[$cleanId].Message = "Successfully scaffolded."
        }
        catch {
            $ciOutputMap[$cleanId].ReturnCode = [int][ExtensionEligibilityState]::DependencyFailure
            $ciOutputMap[$cleanId].Message = "Factory Pipeline Crash: $_"
            Write-Err "Factory Crash for '$cleanId': $_"
            throw $_
        }
    }

    if ($env:GITHUB_OUTPUT) {
        $jsonMap = $ciOutputMap | ConvertTo-Json -Compress -Depth 5
        "CI_PAYLOAD=$jsonMap" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding UTF8
    }
}
elseif ($PSCmdlet.ParameterSetName -eq 'Remove') {
    Write-Info "Executing Remove Operation..."
    $stateResult = Get-ChocoVSCodeExtensionState -StatePath $StatePath
    $stateList = [System.Collections.Generic.List[string]]::new()
    if ($null -ne $stateResult) { $stateList.AddRange([string[]]$stateResult) }

    foreach ($id in $Remove) {
        $cleanId = $id.ToLower()
        if (-not $stateList.Contains($cleanId)) {
            if ($CI) {
                Write-Skip "[30] Request Denied for '$cleanId': Not tracked in state file."
                exit 30
            }
        }
        Write-StyledMessage -Color Magenta -Message "`n================================================================================"
        Write-StyledMessage -Color Magenta -Message " REMOVING: $cleanId"
        Write-StyledMessage -Color Magenta -Message "================================================================================"

        $shredderParams = @{
            ExtensionId  = $cleanId
            StatePath    = $StatePath
            AutomaticDir = $AutomaticDir
        }
        Remove-VSCodeExtension @shredderParams

        if ($AutoCommit) {
            Checkpoint-GitRepository -ExtensionId $cleanId -CommitMessage "Remove $cleanId extension" -StatePath $StatePath -AutomaticDir $AutomaticDir
        }
    }
}
elseif ($PSCmdlet.ParameterSetName -eq 'Search') {
    Write-Info "Querying VS Code Marketplace for: '$Search'"

    $results = Search-VsCodeMarketplace -Query $Search

    if ($results.Count -gt 0) {
        $results | Format-Table -AutoSize
    }
    else {
        Write-Skip "No extensions found matching that query."
    }
}
else {
    Write-Err "Please specify a valid operation: -Add, -Remove, or -Search"
}
