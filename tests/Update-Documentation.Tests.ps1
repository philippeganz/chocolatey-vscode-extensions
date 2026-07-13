[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Describe "Update-Documentation.ps1" {
    It "Should successfully execute and generate Markdown files" {
        $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) "bin\Update-Documentation.ps1"
        $docsDir = Join-Path (Split-Path $PSScriptRoot -Parent) "docs\reference"

        # We don't want to pollute real docs during test if it's CI, but for coverage it's fine.
        # Actually it's idempotent, so it's perfectly safe to run.
        & $scriptPath

        Test-Path $docsDir | Should -Be $true
        $mdFiles = Get-ChildItem $docsDir -Filter "*.md"
        $mdFiles.Count | Should -BeGreaterThan 0
    }
}
