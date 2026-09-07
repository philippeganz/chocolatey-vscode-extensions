<#
.SYNOPSIS
    The Cleanup hook for Chocolatey AU.

.DESCRIPTION
    Executes after the package update has been processed. It restores the `README.md`
    file from its hidden backup. This ensures the raw README is preserved in the package
    folder for local review, while preventing AU from overriding the truncated
    `<description>` CDATA block inside the `.nuspec` file.

.PARAMETER package
    The AU package object representing the current context.

.EXAMPLE
    # This function is not meant to be called directly. It is invoked natively by AU.

.INPUTS
    [System.Management.Automation.PSCustomObject]

.OUTPUTS
    None
#>
function global:au_AfterUpdate {
    param($package)
    # Restore the README.md after AU has safely finished generating the .nuspec
    $readmePath = Join-Path $package.Path "README.md"
    $hiddenReadmePath = Join-Path $package.Path "README.md.bak"
    if (Test-Path $hiddenReadmePath) {
        Move-Item $hiddenReadmePath $readmePath -Force
    }
}
