BeforeAll {
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeCore\ChocoVSCodeCore.psd1 -Force
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeExtensionManager\ChocoVSCodeExtensionManager.psd1 -Force
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
            Checkpoint-GitRepository -ExtensionId "ms-python.python" -CommitMessage "test commit" -StatePath "C:\fake\state.yaml" -AutomaticDir "C:\fake\automatic"

            # Assertion
            Should -Invoke -CommandName git -ModuleName ChocoVSCodeExtensionManager -Times 3
            Should -Invoke -CommandName Write-Success -ModuleName ChocoVSCodeExtensionManager -Times 1
        }
    }
}
