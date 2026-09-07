BeforeAll {
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeCore\ChocoVSCodeCore.psd1 -Force
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeMarketplace\ChocoVSCodeMarketplace.psd1 -Force
}
Describe "Get-VsCodeExtensionUrl" {
    Context "Successful Route" {
        It "should execute the joyful output by returning the source URL for the specified asset type" {
            $fakeExtMeta = @{
                versions = @(
                    @{ version = "1.0.0" }
                )
            }
            $url = Get-VsCodeExtensionUrl -Publisher "ms-python" -ExtensionName "python" -Version "1.0.0" -ExtMeta $fakeExtMeta
            $url | Should -Match "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-python/vsextensions/python/1.0.0/vspackage"
        }
    }
}
