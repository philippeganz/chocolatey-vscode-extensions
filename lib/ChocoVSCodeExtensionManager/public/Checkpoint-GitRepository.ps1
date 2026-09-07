<#
.SYNOPSIS
    Evaluates the repository state for a specific extension and performs an atomic auto-commit if changes exist.

.DESCRIPTION
    A highly robust Git orchestration helper that consolidates index operations for both adding and
    removing extensions from the Chocolatey ecosystem. It automatically stages targeted changes
    to the `extensions.yaml` state file and the specific package directory inside the automatic folder.

    [Smart Evaluation]
    Instead of blindly committing, it uses `git diff --cached` to evaluate if any actual modifications
    occurred to the index. If no changes are detected (e.g., scaffolding an extension that was already
    up to date), it cleanly aborts the commit to prevent empty or dirty history.

.PARAMETER ExtensionId
    The exact unique identifier of the extension from the VS Code Marketplace (e.g., 'mechatroner.rainbow-csv').

.PARAMETER CommitMessage
    The exact message string to use for the automated git commit.

.PARAMETER StatePath
    The absolute path to the main `extensions.yaml` state file to stage.

.PARAMETER AutomaticDir
    The absolute path to the automatic directory where the extension packages reside.

.EXAMPLE
    Checkpoint-GitRepository -ExtensionId "ms-python.python" -CommitMessage "chore: auto-update ms-python.python" -StatePath "C:\var\state\extensions.yaml" -AutomaticDir "C:\git\automatic"

.INPUTS
    None

.OUTPUTS
    None
#>
function Checkpoint-GitRepository {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $ExtensionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $CommitMessage,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $StatePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $AutomaticDir
    )

    Write-Info "Evaluating git state for auto-commit of $ExtensionId..."

    if (-not $PSCmdlet.ShouldProcess("Git Repository for $ExtensionId", "Auto-Commit Changes")) { return }

    git add $StatePath

    $pkgName = Get-ChocoVSCodePackageName -ExtensionId $ExtensionId

    if ($pkgName) {
        $pkgPath = Join-Path $AutomaticDir $pkgName
        git add --all $pkgPath 2>$null
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
