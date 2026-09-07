BeforeAll {
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeCore\ChocoVSCodeCore.psd1 -Force
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeMarketplace\ChocoVSCodeMarketplace.psd1 -Force
}
Describe "Get-VsCodeNuspecMetadata" {
    Context "Successful Route" {
        It "should execute the joyful output by mapping the marketplace JSON structure into a flattened metadata hashtable" {
            $fakeExtMeta = @{
                displayName      = "My Extension"
                shortDescription = "A test extension"
                publisher        = @{ displayName = "Test Publisher" }
            }
            $meta = Get-VsCodeNuspecMetadata -ExtMeta $fakeExtMeta -ExtensionPublisher "test-pub" -ExtensionName "my-ext"
            $meta.Title | Should -Match "My Extension"
            $meta.Authors | Should -Be "test-pub"
        }
    }
}
