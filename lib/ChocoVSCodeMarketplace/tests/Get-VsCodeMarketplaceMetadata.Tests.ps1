#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force
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
