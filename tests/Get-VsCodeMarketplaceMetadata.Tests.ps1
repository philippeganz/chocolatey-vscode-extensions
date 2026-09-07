BeforeAll {
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeCore\ChocoVSCodeCore.psd1 -Force
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeMarketplace\ChocoVSCodeMarketplace.psd1 -Force
}

Describe "Get-VsCodeMarketplaceMetadata" {
    Context "Successful Route" {
        It "should execute the joyful output by returning the parsed extension block" {
            $fakeResponse = @{
                results = @(
                    @{
                        extensions = @(
                            @{ extensionName = "python"; publisher = @{ publisherName = "ms-python" } }
                        )
                    }
                )
            }
            Mock Invoke-WithMarketplaceRetry -ModuleName ChocoVSCodeMarketplace -MockWith { return $fakeResponse }

            $ext = Get-VsCodeMarketplaceMetadata -Publisher "ms-python" -ExtensionName "python"

            $ext.extensionName | Should -Be "python"
            Should -Invoke -CommandName Invoke-WithMarketplaceRetry -ModuleName ChocoVSCodeMarketplace -Times 1
        }
    }
}
