[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

BeforeAll {
    $script:originalPSModulePath = $env:PSModulePath
    $libPath = Resolve-Path (Join-Path $PSScriptRoot "..\lib")
    $env:PSModulePath = "$libPath;$env:PSModulePath"
    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force
    Import-Module AuExtensionHooks -Force
}

AfterAll {
    $env:PSModulePath = $script:originalPSModulePath
}

Describe "AuExtensionHooks Module" {
    Context "Successful Route" {
        It "should execute au_SearchReplace and yield regex replacement mappings" {
            InModuleScope AuExtensionHooks {
                $global:Latest = @{ Version = "1.0.0"; MarketplaceIconUrl = "https://icon.url" }
                $global:ExtensionName = "my-extension"
                $global:ExtensionPublisher = "my-publisher"

                $result = au_SearchReplace
                $result.Keys | Should -Contain "*.nuspec"
                $result.Keys | Should -Contain "tools\chocolateyInstall.ps1"
            }
        }

        It "should successfully route au_BeforeUpdate to the Nuspec generation pipeline" {
            InModuleScope AuExtensionHooks {
                Mock Invoke-RobustDownload {}
                Mock Expand-VsCodePayload { return @{ PackageJson = @{}; CDataSafeReadme = "test" } }
                Mock Get-VsCodeNuspecMetadata { return @{ Title = "Test"; Summary = "Test" } }
                Mock Update-VsCodeNuspecMetadata { return "<xml></xml>" }
                Mock Update-NuspecCDataDescription {}
                Mock Update-NuspecDependency { return @() }
                Mock Save-NuspecXml {}
                Mock New-VerificationFile {}
                Mock Save-VsCodeIcon {}

                $fakePkgDir = Join-Path $TestDrive "pkg"
                [void](New-Item -ItemType Directory -Path $fakePkgDir -Force)
                $fakeNuspec = Join-Path $fakePkgDir "vscode-test.nuspec"
                Set-Content -Path $fakeNuspec -Value "<?xml version='1.0'?><package></package>" -Encoding UTF8

                $global:Latest = @{ URL64 = "https://url"; MarketplaceIconUrl = "https://icon.url"; Version = "1.0.0"; RawMeta = @{ versions = @(); shortDescription = "Test" } }
                $global:ExtensionPublisher = "test"
                $global:ExtensionName = "test"

                $fakePackage = @{ Name = "vscode-test"; Path = $fakePkgDir; NuspecXml = [xml]"<?xml version='1.0'?><package></package>" }

                Push-Location $fakePkgDir
                try {
                    au_BeforeUpdate -package $fakePackage
                }
                finally {
                    Pop-Location
                }

                Should -Invoke -CommandName Expand-VsCodePayload -Times 1
                Should -Invoke -CommandName Get-VsCodeNuspecMetadata -Times 1
                Should -Invoke -CommandName Save-VsCodeIcon -Times 1
                Should -Invoke -CommandName Invoke-RobustDownload -Times 1
            }
        }
    }
}
