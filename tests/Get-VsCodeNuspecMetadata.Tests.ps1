#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\lib"))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force
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
