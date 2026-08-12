#Requires -Version 7.0

<#
.SYNOPSIS
    Core utility functions and helpers used across the repository.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is required for cross-platform ANSI colored output in orchestration')]
param()

# =============================================================================
# Global Error Handling
# =============================================================================
# Enforce strict fail-fast behavior across this entire script/module.
# Any cmdlet or module import failure will immediately throw a terminating error.
# Override locally with `-ErrorAction SilentlyContinue` when needed.
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
A cross-platform helper for rendering colorized, structured console messages using PS7 ANSI strings.

.EXAMPLE
    Write-StyledMessage -Message "Deploying" -Color Green -Prefix "[OK]"
#>
function Write-StyledMessage {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][ConsoleColor]$Color,
        [string]$Prefix = ""
    )

    $colorName = $Color.ToString()
    $ansiColor = $PSStyle.Foreground.$colorName

    if ($Prefix) {
        Write-Host "${ansiColor}${Prefix}$($PSStyle.Reset) $Message"
    }
    else {
        Write-Host "${ansiColor}${Message}$($PSStyle.Reset)"
    }
}

# =============================================================================
# Semantic Logging Wrappers
# =============================================================================

<#
.SYNOPSIS
Writes a green success message to the console.

.EXAMPLE
    Write-Success "Operation complete"
#>
function Write-Success ([string]$msg) { Write-StyledMessage -Prefix "[SUCCESS]" -Message $msg -Color Green }

<#
.SYNOPSIS
Writes a cyan info message to the console.

.EXAMPLE
    Write-Info "Operation complete"
#>
function Write-Info    ([string]$msg) { Write-StyledMessage -Prefix "[INFO]"    -Message $msg -Color Cyan }

<#
.SYNOPSIS
Writes a yellow skip message to the console.

.EXAMPLE
    Write-Skip "Operation complete"
#>
function Write-Skip    ([string]$msg) { Write-StyledMessage -Prefix "[SKIP]"    -Message $msg -Color Yellow }

<#
.SYNOPSIS
Writes a red error message to the console.

.EXAMPLE
    Write-Err "Operation complete"
#>
function Write-Err     ([string]$msg) { Write-StyledMessage -Prefix "[ERROR]"   -Message $msg -Color Red }


# =============================================================================
# Generic Color Wrappers
# =============================================================================

<#
.SYNOPSIS
Writes a raw red message to the console without a semantic prefix.

.EXAMPLE
    Write-Red "Operation complete"
#>
function Write-Red     ([string]$msg) { Write-StyledMessage -Message $msg -Color Red }

<#
.SYNOPSIS
Writes a raw cyan message to the console without a semantic prefix.

.EXAMPLE
    Write-Cyan "Operation complete"
#>
function Write-Cyan    ([string]$msg) { Write-StyledMessage -Message $msg -Color Cyan }

<#
.SYNOPSIS
Writes a raw yellow message to the console without a semantic prefix.

.EXAMPLE
    Write-Yellow "Operation complete"
#>
function Write-Yellow  ([string]$msg) { Write-StyledMessage -Message $msg -Color Yellow }

<#
.SYNOPSIS
Writes a raw green message to the console without a semantic prefix.

.EXAMPLE
    Write-Green "Operation complete"
#>
function Write-Green   ([string]$msg) { Write-StyledMessage -Message $msg -Color Green }

<#
.SYNOPSIS
Writes a raw gray message to the console without a semantic prefix.

.EXAMPLE
    Write-Gray "Operation complete"
#>
function Write-Gray    ([string]$msg) { Write-StyledMessage -Message $msg -Color Gray }

<#
.SYNOPSIS
Writes a raw magenta message to the console without a semantic prefix.

.EXAMPLE
    Write-Magenta "Operation complete"
#>
function Write-Magenta ([string]$msg) { Write-StyledMessage -Message $msg -Color Magenta }

<#
.SYNOPSIS
Writes a raw white message to the console without a semantic prefix.

.EXAMPLE
    Write-White "Operation complete"
#>
function Write-White   ([string]$msg) { Write-StyledMessage -Message $msg -Color White }


Export-ModuleMember -Function Write-StyledMessage, Write-Success, Write-Info, Write-Skip, Write-Err, Write-Red, Write-Cyan, Write-Yellow, Write-Green, Write-Gray, Write-Magenta, Write-White

<#
.SYNOPSIS
Evaluates the git state for the given extension and performs an auto-commit if changes exist.

.DESCRIPTION
This helper consolidates the git operations for both adding and removing extensions.
It automatically stages changes to the `var/state/config.yaml` state file and the specific
package directory inside the `automatic` folder. It uses `git diff --cached` to evaluate
if any actual modifications occurred, cleanly skipping the commit if no changes are detected.

.PARAMETER ExtensionId
The raw publisher.extension identifier (e.g. 'mechatroner.rainbow-csv').

.PARAMETER CommitMessage
The message to use for the automated commit.

.EXAMPLE
    Invoke-GitAutoCommit -ExtensionId "mechatroner.rainbow-csv" -CommitMessage "Update package"
#>
function Invoke-GitAutoCommit {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ExtensionId,

        [Parameter(Mandatory = $true)]
        [string]$CommitMessage
    )

    Write-Info "Evaluating git state for auto-commit of $ExtensionId..."
    git add "var/state/config.yaml"
    $baseAuto = Get-AutomaticDirectory
    $pkgName = Get-ChocoPackageName $ExtensionId

    if ($pkgName) {
        # Using --all gracefully handles both added and deleted files/directories
        git add --all (Join-Path $baseAuto $pkgName) 2>$null
    }

    $staged = git diff --name-only --cached
    if (-not $staged) {
        Write-Skip "No git changes detected for $ExtensionId. Skipping auto-commit."
    }
    else {
        [void](git commit -m $CommitMessage)
        Write-Success "Auto-Committed: '$CommitMessage'"
    }
}
Export-ModuleMember -Function Invoke-GitAutoCommit
