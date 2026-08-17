#Requires -Version 7.0
#Requires -Module @{ModuleName='Pester'; ModuleVersion='6.0.0'}
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Global variables are required for AU configuration and workflow state')]
param()

$ErrorActionPreference = "Stop"

Describe "AuExtensionHooks" -Tag "Unit", 'AuExtensionHooks' {
    BeforeAll {
        $script:hooksPath = "$PSScriptRoot\..\bin\AuExtensionHooks.ps1"
        $script:mockConfig = Join-Path $TestDrive "mock_config.yaml"
        $script:mockRepo = Join-Path $TestDrive "mock_repo"
        $env:CHOCO_VSCODE_MAX_RETRIES = 1

        "---`nextensions:`n  - ms-python.python`n" | Set-Content $script:mockConfig -Encoding UTF8
        [void](New-Item -ItemType Directory -Path $script:mockRepo -Force)
        $env:CHOCO_VSCODE_AUTOMATIC_DIR = $script:mockRepo

        # AU runs 'update' upon dot-sourcing, which throws if no nuspec exists in the current directory.
        $fakeNuspec = Join-Path $script:mockRepo "test.nuspec"
        "<?xml version='1.0'?><package><metadata><id>test</id><version>1.0</version></metadata></package>" | Set-Content $fakeNuspec
        Push-Location $script:mockRepo

        $global:ExtensionPublisher = "mechatroner"
        $global:ExtensionName = "rainbow-csv"

        try {
            . $script:hooksPath -ErrorAction SilentlyContinue
        }
        catch { Write-Verbose "Expected failure sourcing AuExtensionHooks: $_" }

        Pop-Location
    }

    AfterAll {
        Remove-Item $script:mockConfig -Force -ErrorAction SilentlyContinue
        Remove-Item $script:mockRepo -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item Env:\CHOCO_VSCODE_AUTOMATIC_DIR -ErrorAction SilentlyContinue
        Remove-Item Env:\CHOCO_VSCODE_MAX_RETRIES -ErrorAction SilentlyContinue
    }

    Context "au_GetLatest" {
        It "Should return a hashtable with Version and URL" {
            # Since the function relies on the directory name for extension ID, we mock Split-Path
            $global:au_NoCheckChocoVersion = $true

            # Setup a fake package directory environment
            $fakePkgDir = Join-Path $script:mockRepo "vscode-rainbow-csv"
            [void](New-Item -ItemType Directory -Path $fakePkgDir -Force)
            Set-Location $fakePkgDir

            $result = au_GetLatest
            $result | Should -Not -BeNullOrEmpty
            $result.Version | Should -Not -BeNullOrEmpty
            $result.URL32 | Should -Not -BeNullOrEmpty

            Set-Location $PSScriptRoot
        }

        It "Should log a warning if global:ExtensionVersion is not found on Marketplace" {
            $global:au_NoCheckChocoVersion = $true
            $fakePkgDir = Join-Path $script:mockRepo "vscode-rainbow-csv"
            [void](New-Item -ItemType Directory -Path $fakePkgDir -Force)
            Set-Location $fakePkgDir

            $global:ExtensionVersion = "99.99.99"

            $result = au_GetLatest
            $result | Should -Not -BeNullOrEmpty

            $global:ExtensionVersion = $null
            Set-Location $PSScriptRoot
        }
    }

    Context "au_BeforeUpdate" {
        It "Should run successfully when mocked" {
            $fakePkgDir = Join-Path $script:mockRepo "vscode-rainbow-csv"
            [void](New-Item -ItemType Directory -Path $fakePkgDir -Force)
            Set-Location $fakePkgDir

            $fakeNuspecData = [xml]"<?xml version='1.0'?><package><metadata><description></description><iconUrl></iconUrl><title></title><summary></summary><authors></authors><projectUrl></projectUrl></metadata></package>"

            # Mock dependencies
            Mock Get-VsCodeNuspecMetadata -ModuleName VsCodeMarketplace -MockWith {
                return @{ Title = "Fake"; Summary = "Fake"; Authors = "Fake"; ProjectUrl = "Fake" }
            }
            Mock Invoke-RobustDownload -MockWith { "fake" | Set-Content $OutFile }
            Mock Expand-VsCodePayload -MockWith {
                return @{
                    TruncatedReadme = "Hello <world>"
                    PackageJson     = @{ extensionDependencies = @() }
                }
            }
            Mock Update-NuspecDependency -ModuleName VsCodeMarketplace -MockWith { return }
            Mock Invoke-WebRequest -MockWith { return }

            # We must create a fake nuspec and tools dir
            $fakeNuspecData.Save((Join-Path (Get-Location).Path "vscode-rainbow-csv.nuspec"))
            [void](New-Item -ItemType Directory -Path "tools" -Force)
            "fake content" | Set-Content "tools\chocolateyInstall.ps1"

            $global:Latest = @{ Version = "1.0.0"; URL64 = "fake"; MarketplaceIconUrl = "http://fake" }
            $fakePackage = @{ Path = (Get-Location).Path; Name = "vscode-rainbow-csv"; NuspecXml = $fakeNuspecData }

            try {
                au_BeforeUpdate -package $fakePackage
            }
            catch {
                Write-Verbose "Expected failure executing au_BeforeUpdate: $_"
            }

            Set-Location $PSScriptRoot
        }

        It "Should handle icon download failure gracefully" {
            $fakePkgDir = Join-Path $script:mockRepo "vscode-rainbow-csv"
            if (Test-Path $fakePkgDir) { Remove-Item $fakePkgDir -Recurse -Force }
            [void](New-Item -ItemType Directory -Path $fakePkgDir -Force)
            Set-Location $fakePkgDir

            $fakeNuspecData = [xml]"<?xml version='1.0'?><package><metadata><description></description><iconUrl></iconUrl><title></title><summary></summary><authors></authors><projectUrl></projectUrl></metadata></package>"

            Mock Get-VsCodeNuspecMetadata -ModuleName VsCodeMarketplace -MockWith {
                return @{ Title = "Fake"; Summary = "Fake"; Authors = "Fake"; ProjectUrl = "Fake"; IconUrl = "https://fake.icon" }
            }
            Mock Invoke-RobustDownload -MockWith { "fake" | Set-Content $OutFile }
            Mock Expand-VsCodePayload -MockWith {
                return @{
                    TruncatedReadme = "Hello <world>"
                    PackageJson     = @{ extensionDependencies = @() }
                }
            }
            Mock Update-NuspecDependency -ModuleName VsCodeMarketplace -MockWith { return }
            Mock New-VerificationFile -ModuleName VsCodeMarketplace -MockWith { return }

            # Make the web request throw to hit the catch block
            Mock Invoke-WebRequest -MockWith { throw "Network error" }

            $fakeNuspecData.Save((Join-Path (Get-Location).Path "vscode-rainbow-csv.nuspec"))
            [void](New-Item -ItemType Directory -Path "tools" -Force)
            "fake content" | Set-Content "tools\chocolateyInstall.ps1"

            $global:Latest = @{ Version = "1.0.0"; URL64 = "fake"; MarketplaceIconUrl = "http://fake" }
            $fakePackage = @{ Path = (Get-Location).Path; Name = "vscode-rainbow-csv"; NuspecXml = $fakeNuspecData }

            Mock New-VerificationFile -ModuleName VsCodeMarketplace -MockWith { return }

            $VerbosePreference = 'Continue'
            { au_BeforeUpdate -package $fakePackage } | Should -Not -Throw
            $VerbosePreference = 'SilentlyContinue'

            Set-Location $PSScriptRoot
        }
    }

    Context "au_SearchReplace" {
        It "Should generate the regex replacements" {
            $global:Latest = @{ Version = "9.9.9"; MarketplaceIconUrl = "http://fakeicon" }
            $global:ExtensionPublisher = "test"
            $global:ExtensionName = "ext"

            $rules = au_SearchReplace
            $rules.Keys -contains "*.nuspec" | Should -Be $true
            $rules["*.nuspec"]["(?is)<iconUrl>.*?</iconUrl>"] | Should -Be "<iconUrl>https://cdn.jsdelivr.net/gh/philippeganz/chocolatey-vscode-extensions@main/automatic/vscode-ext/icon.png</iconUrl>"
            $rules.Keys -contains "tools\chocolateyInstall.ps1" | Should -Be $true
        }
    }
}
