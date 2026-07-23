#Requires -Version 7.0
#Requires -Module @{ModuleName='Pester'; ModuleVersion='6.0.0'}
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Describe "Update-Documentation.ps1" -Tag "Integration", 'Update-Documentation' {
    It "Should successfully execute and generate Markdown files" {
        $scriptPath = "$PSScriptRoot\..\bin\Update-Documentation.ps1"
        $docsDir = "$PSScriptRoot\..\docs\reference"

        # We don't want to pollute real docs during test if it's CI, but for coverage it's fine.
        # Actually it's idempotent, so it's perfectly safe to run.
        & $scriptPath

        Test-Path $docsDir | Should -Be $true
        $mdFiles = Get-ChildItem $docsDir -Filter "*.md"
        $mdFiles.Count | Should -BeGreaterThan 0
    }
}
