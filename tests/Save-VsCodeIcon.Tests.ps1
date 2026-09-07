BeforeAll {
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeCore\ChocoVSCodeCore.psd1 -Force
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeMarketplace\ChocoVSCodeMarketplace.psd1 -Force
}
Describe "Save-VsCodeIcon" {
    Context "Successful Route" {
        It "should execute the joyful output by retrieving the icon url and downloading it" {
            Mock Invoke-RobustDownload -ModuleName ChocoVSCodeMarketplace {}
            $fakePkgDir = Join-Path $TestDrive "pkg"
            New-Item -ItemType Directory -Path $fakePkgDir -Force | Out-Null
            Save-VsCodeIcon -IconUrl "https://icon.url/icon.png" -PackageDir $fakePkgDir -PackageName "vscode-bar"
            Should -Invoke -CommandName Invoke-RobustDownload -ModuleName ChocoVSCodeMarketplace -Times 1
        }
    }
}
