#Requires -Version 7.0
BeforeAll {
    $script:originalPSModulePath = $env:PSModulePath
    $libPath = Resolve-Path (Join-Path $PSScriptRoot "..\..")
    $env:PSModulePath = "$libPath;$env:PSModulePath"
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }
    Import-Module ChocoVSCodeMarketplace -Force
}
AfterAll {
    $env:PSModulePath = $script:originalPSModulePath
}

Describe "Search-VsCodeMarketplace" {
    Context "Successful HTTP Route" {
        It "should cleanly query and truncate long descriptions" {
            Mock Invoke-WithMarketplaceRetry {
                return [PSCustomObject]@{
                    results = @(
                        [PSCustomObject]@{
                            extensions = @(
                                [PSCustomObject]@{
                                    publisher        = [PSCustomObject]@{ publisherName = "test-pub" }
                                    extensionName    = "test-ext"
                                    displayName      = "Test Ext"
                                    shortDescription = "This is a very long description that exceeds fifty characters by a lot so it should truncate."
                                },
                                [PSCustomObject]@{
                                    publisher        = [PSCustomObject]@{ publisherName = "short-pub" }
                                    extensionName    = "short-ext"
                                    displayName      = "Short Ext"
                                    shortDescription = "Short."
                                }
                            )
                        }
                    )
                }
            } -ModuleName ChocoVSCodeMarketplace

            $results = Search-VsCodeMarketplace -Query "test"
            $results.Count | Should -Be 2
            $results[0].Id | Should -Be "test-pub.test-ext"
            $results[0].Description.EndsWith("...") | Should -Be $true
            $results[1].Description | Should -Be "Short."
            Should -Invoke -CommandName Invoke-WithMarketplaceRetry -Times 1 -ModuleName ChocoVSCodeMarketplace
        }

        It "should handle empty response payloads gracefully" {
            Mock Invoke-WithMarketplaceRetry {
                return [PSCustomObject]@{
                    results = @( [PSCustomObject]@{ extensions = $null } )
                }
            } -ModuleName ChocoVSCodeMarketplace
            $results = Search-VsCodeMarketplace -Query "empty"
            $results.Count | Should -Be 0
        }
    }
}
