#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force
    Import-Module ChocoVSCodeExtensionManager -Force
    Import-Module AuExtensionHooks -Force
}

Describe "au_GetLatest" {
    BeforeEach {
        Set-Variable -Name "ExtensionPublisher" -Value "ms-python" -Scope Global
        Set-Variable -Name "ExtensionName" -Value "python" -Scope Global
        Set-Variable -Name "ExtensionVersion" -Value $null -Scope Global
    }

    Context "Normal Execution (Standard AU Polling)" {
        It "should successfully fetch the absolute latest version and construct the AU state object" {
            $fakeExtMeta = @{
                versions = @(
                    @{
                        version = "1.0.0"
                        files   = @( @{ assetType = "Microsoft.VisualStudio.Services.Icons.Default"; source = "http://icon" } )
                    }
                )
            }
            Mock Get-VsCodeMarketplaceMetadata -ModuleName AuExtensionHooks -MockWith { return $fakeExtMeta }
            Mock Get-VsCodeExtensionUrl -ModuleName AuExtensionHooks -MockWith { return "http://fake.url" }

            $result = au_GetLatest

            $result.Version | Should -Be "1.0.0"
            $result.URL64 | Should -Be "http://fake.url"
            $result.MarketplaceIconUrl | Should -Be "http://icon"

            Should -Invoke -CommandName Get-VsCodeMarketplaceMetadata -ModuleName AuExtensionHooks -Times 1
        }
    }

    Context "Moderation Repush Success" {
        It "should fetch all versions, locate the specific requested version, and lock the payload to it (Lines 30, 37-41)" {
            Set-Variable -Name "ExtensionVersion" -Value "0.9.0" -Scope Global

            $fakeExtMeta = @{
                versions = @(
                    @{ version = "1.0.0"; files = @( @{ assetType = "Microsoft.VisualStudio.Services.Icons.Default"; source = "http://icon1" } ) }
                    @{ version = "0.9.0"; files = @( @{ assetType = "Microsoft.VisualStudio.Services.Icons.Default"; source = "http://icon09" } ) }
                )
            }
            Mock Get-VsCodeMarketplaceMetadata -ModuleName AuExtensionHooks -MockWith { return $fakeExtMeta }
            Mock Get-VsCodeExtensionUrl -ModuleName AuExtensionHooks -MockWith { return "http://fake.url.09" }
            Mock Write-Info -ModuleName AuExtensionHooks {}

            $result = au_GetLatest

            $result.Version | Should -Be "0.9.0"
            $result.MarketplaceIconUrl | Should -Be "http://icon09"

            Should -Invoke -CommandName Get-VsCodeMarketplaceMetadata -ModuleName AuExtensionHooks -Times 1
            Should -Invoke -CommandName Write-Info -ModuleName AuExtensionHooks -Times 1 -ParameterFilter { $Message -match "Moderation Override" }
        }
    }

    Context "Moderation Repush Failure" {
        It "should warn if the requested override version is not found in the payload graph (Lines 42-43)" {
            Set-Variable -Name "ExtensionVersion" -Value "9.9.9" -Scope Global

            $fakeExtMeta = @{
                versions = @(
                    @{ version = "1.0.0"; files = @( @{ assetType = "Microsoft.VisualStudio.Services.Icons.Default"; source = "http://icon1" } ) }
                )
            }
            Mock Get-VsCodeMarketplaceMetadata -ModuleName AuExtensionHooks -MockWith { return $fakeExtMeta }
            Mock Get-VsCodeExtensionUrl -ModuleName AuExtensionHooks -MockWith { return "http://fake.url" }
            Mock Write-Warn -ModuleName AuExtensionHooks {}

            $result = au_GetLatest

            $result.Version | Should -Be "1.0.0"
            Should -Invoke -CommandName Write-Warn -ModuleName AuExtensionHooks -Times 1 -ParameterFilter { $Message -match "not found on Marketplace" }
        }
    }
}
