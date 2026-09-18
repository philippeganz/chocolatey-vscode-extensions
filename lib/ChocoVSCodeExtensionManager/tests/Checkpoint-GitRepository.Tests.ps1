#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeExtensionManager -Force
}

Describe "Checkpoint-GitRepository" {
    Context "Successful Route" {
        It "should execute the joyful output by staging and committing" {
            # Setup
            Mock Write-Info -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Success -ModuleName ChocoVSCodeExtensionManager {}

            # We mock the external git executable by declaring a dummy function inside the module scope,
            # or we can mock it directly since PowerShell command resolution prefers functions over executables.
            Mock git -ModuleName ChocoVSCodeExtensionManager -MockWith {
                if ($args -contains "diff") { return "some/file/changed.txt" }
            }

            # Execution
            Checkpoint-GitRepository -ExtensionId "ms-python.python" -CommitMessage "test commit" -StatePath "$TestDrive\state.json" -AutomaticDir "$TestDrive\automatic"

            # Assertion
            Should -Invoke -CommandName git -ModuleName ChocoVSCodeExtensionManager -Times 3
            Should -Invoke -CommandName Write-Success -ModuleName ChocoVSCodeExtensionManager -Times 1
        }
    }
    Context "Abort Sequence" {
        It "should safely abort the auto-commit if the git index detects no changes (Line 77)" {
            Mock Write-Info -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Skip -ModuleName ChocoVSCodeExtensionManager {}
            Mock git -ModuleName ChocoVSCodeExtensionManager -MockWith {
                if ($args -contains "diff") { return $null }
            }
            Checkpoint-GitRepository -ExtensionId "ms-python.python" -CommitMessage "test commit" -StatePath "$TestDrive\state.json" -AutomaticDir "$TestDrive\automatic"
            Should -Invoke -CommandName Write-Skip -ModuleName ChocoVSCodeExtensionManager -Times 1
            Should -Invoke -CommandName git -ModuleName ChocoVSCodeExtensionManager -Times 2
        }
    }
}
