BeforeAll {
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeCore\ChocoVSCodeCore.psd1 -Force
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeMarketplace\ChocoVSCodeMarketplace.psd1 -Force
}

Describe "Invoke-RobustDownload" {
    Context "Successful Route" {
        It "should execute the joyful output by deferring the download block to the retry wrapper" {
            Mock Invoke-WithMarketplaceRetry -ModuleName ChocoVSCodeMarketplace {}

            Invoke-RobustDownload -Url "https://fake.url/file.vsix" -OutFile "$TestDrive\out.vsix"

            Should -Invoke -CommandName Invoke-WithMarketplaceRetry -ModuleName ChocoVSCodeMarketplace -Times 1
        }
    }
}
