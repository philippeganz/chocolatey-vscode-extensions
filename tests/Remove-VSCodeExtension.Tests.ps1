BeforeAll {
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeCore\ChocoVSCodeCore.psd1 -Force
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeExtensionManager\ChocoVSCodeExtensionManager.psd1 -Force
}

Describe "Remove-VSCodeExtension" {
    Context "Successful Route" {
        It "should execute the joyful output and save the updated state" {
            Mock Get-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager -MockWith { return [string[]]@("ms-python.python") }
            Mock Save-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Info -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Success -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Warn -ModuleName ChocoVSCodeExtensionManager {}

            $fakeAutomaticDir = Join-Path $TestDrive "automatic"
            New-Item -ItemType Directory -Path $fakeAutomaticDir | Out-Null
            $fakePkgDir = Join-Path $fakeAutomaticDir "vscode-python"
            New-Item -ItemType Directory -Path $fakePkgDir | Out-Null
            $fakeStatePath = Join-Path $TestDrive "state.yaml"

            Remove-VSCodeExtension -ExtensionId "ms-python.python" -StatePath $fakeStatePath -AutomaticDir $fakeAutomaticDir

            Should -Invoke -CommandName Save-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager -Times 1
        }
    }
}
