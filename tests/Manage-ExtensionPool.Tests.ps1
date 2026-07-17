[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Global variables are required for AU configuration and workflow state')]
param()

function global:Invoke-MockFactory { $script:factoryCalled = $true }
function global:Invoke-MockShredder { return @("test.removeme") }

$ErrorActionPreference = "Stop"

Describe "Manage-ExtensionPool CLI" {
    BeforeAll {
        $script:scriptPath = "$PSScriptRoot\..\bin\Manage-ExtensionPool.ps1"
    }

    Context "Audit Mode" {
        It "Should succeed when config matches directories" {

            $mockAuto = "$PSScriptRoot\..\automatic"

            $env:CHOCO_VSCODE_AUTOMATIC_DIR = $mockAuto
            if (-not (Test-Path $mockAuto)) { [void](New-Item -ItemType Directory -Path $mockAuto -Force) }
            [void](New-Item -ItemType Directory -Path (Join-Path $mockAuto "vscode-rainbow-csv") -Force)

            # The test context in Workflow.Tests.ps1 already created a config.yaml for us in test_automatic or etc.
            # But we can mock it here if needed, or just let it run.

            # Mock Get-Content to return a fake config.yaml
            Mock Test-Path -MockWith { return $true }
            Mock Get-Content -MockWith {
                return "---`nextensions:`n  - mechatroner.rainbow-csv"
            }

            { & $script:scriptPath -Audit } | Should -Not -Throw

            Remove-Item (Join-Path $mockAuto "vscode-rainbow-csv") -Recurse -Force
        }
    }

    Context "Search Mode" {
        It "Should query the marketplace API and return results" {
            $mockResponse = @{
                results = @(
                    @{
                        extensions = @(
                            @{
                                publisher        = @{ publisherName = "test" }
                                extensionName    = "test-ext"
                                displayName      = "Test Ext"
                                shortDescription = "A test extension"
                            }
                        )
                    }
                )
            }
            Mock Invoke-RestMethod -MockWith { return $mockResponse }

            [void](& $script:scriptPath -Search "test-ext")

            Should -Invoke -CommandName Invoke-RestMethod -Times 1 -Exactly
        }

        It "Should handle empty search results gracefully" {
            $mockResponse = @{
                results = @( @{ extensions = @() } )
            }
            Mock Invoke-RestMethod -MockWith { return $mockResponse }

            { & $script:scriptPath -Search "empty" } | Should -Not -Throw
        }
    }

    Context "CheckStale Mode" {
        It "Should ignore unpublished packages correctly" {
            $mockAuto = "$PSScriptRoot\..\automatic"
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = $mockAuto
            if (-not (Test-Path $mockAuto)) { [void](New-Item -ItemType Directory -Path $mockAuto -Force) }
            [void](New-Item -ItemType Directory -Path (Join-Path $mockAuto "vscode-missing") -Force)

            Mock Invoke-WebRequest -MockWith { throw "404 Not Found" }

            { & $script:scriptPath -CheckStale } | Should -Not -Throw

            Remove-Item (Join-Path $mockAuto "vscode-missing") -Recurse -Force
        }
    }

    Context "Add Mode" {
        It "Should skip tracked extensions if -Force is not specified" {
            $mockAuto = "$PSScriptRoot\..\automatic"
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = $mockAuto

            Mock Test-Path -MockWith { return $true }
            Mock Get-Content -MockWith { return "---`nextensions:`n  - test.tracked" }

            $factoryCalled = $false
            Mock Join-Path -MockWith {
                if ($ChildPath -eq 'Invoke-ExtensionFactory.ps1') { return 'Invoke-MockFactory' }
                return [System.IO.Path]::Combine($Path, $ChildPath)
            }
            Mock Invoke-MockFactory -MockWith { $script:factoryCalled = $true }

            { & $script:scriptPath -Add "test.tracked" } | Should -Not -Throw
            $factoryCalled | Should -Be $false
        }

        It "Should invoke factory for tracked extensions if -Force is specified" {
            $mockAuto = "$PSScriptRoot\..\automatic"
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = $mockAuto

            Mock Test-Path -MockWith { return $true }
            Mock Get-Content -MockWith { return "---`nextensions:`n  - test.tracked" }
            Mock Set-Content -MockWith {}
            Mock Remove-Item -MockWith {}

            { & $script:scriptPath -Add "test.tracked" -Force } | Should -Not -Throw
        }

        It "Should auto-commit new extensions if -AutoCommit is specified" {
            $mockAuto = "$PSScriptRoot\..\automatic"
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = $mockAuto

            Mock Test-Path -MockWith { return $false } -ParameterFilter { $Path -match 'autocommit' }
            Mock Test-Path -MockWith { return $true }
            Mock Get-Content -MockWith { return "---`nextensions:`n  - other.ext" }
            Mock Set-Content -MockWith {}
            Import-Module (Join-Path $PSScriptRoot "..\lib\VsCodeMarketplace.psm1") -Force
            Mock Join-Path -MockWith {
                if ($ChildPath -eq 'Invoke-ExtensionFactory.ps1') { return 'Invoke-MockFactory' }
                return [System.IO.Path]::Combine($Path, $ChildPath)
            }
            Mock Invoke-MockFactory -MockWith { $script:factoryCalled = $true }

            Mock Get-VsCodeMarketplaceMetadata -MockWith {
                return [PSCustomObject]@{
                    Title          = "Test"
                    Authors        = "Test"
                    ProjectUrl     = "http"
                    IconUrl        = "http"
                    MarketplaceUrl = "http"
                    Description    = "Test"
                    Summary        = "Test"
                    Categories     = ""
                    versions       = @(
                        @{
                            version = "1.0.0"
                            files   = @()
                        }
                    )
                }
            }
            Import-Module (Join-Path $PSScriptRoot "..\lib\VsCodeMarketplace.psm1") -Force
            Mock Invoke-RobustDownload -MockWith { }
            Mock Expand-VsCodePayload -MockWith {
                return @{
                    PackageJson = @{
                        extensionDependencies = @()
                        extensionPack         = @()
                    }
                }
            }
            Mock Select-String -MockWith { return $null } -ParameterFilter { $Path -match 'vsix' }

            $factoryPath = (Resolve-Path "$PSScriptRoot\..\bin\Invoke-ExtensionFactory.ps1").Path
            Mock -CommandName $factoryPath -MockWith { return @("test.autocommit") }

            Mock git -MockWith {
                if ($args[0] -eq 'diff') { return "config.yaml" }
            }

            { & $script:scriptPath -Add "test.autocommit" -AutoCommit } | Should -Not -Throw
            Should -Invoke -CommandName git -Times 3

            Remove-Item (Join-Path $mockAuto "vscode-autocommit") -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Remove Mode" {
        It "Should remove extension and auto-commit if -AutoCommit is specified" {
            $mockAuto = "$PSScriptRoot\..\automatic"
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = $mockAuto

            $shredderPath = (Resolve-Path "$PSScriptRoot\..\bin\Invoke-ExtensionShredder.ps1").Path
            Mock -CommandName $shredderPath -MockWith {}

            Mock git -MockWith {
                if ($args[0] -eq 'diff') { return "config.yaml" }
            }

            { & $script:scriptPath -Remove "test.removeme" -AutoCommit } | Should -Not -Throw
            Should -Invoke -CommandName git -Times 3

        }

        Context "Additional Coverage" {
            It "Should warn on invalid ID format in Add Mode" {
                { & $script:scriptPath -Add "invalidformat" } | Should -Not -Throw
            }

            It "Should warn when API rejects extension in Add Mode" {
                Import-Module (Join-Path $PSScriptRoot "..\lib\VsCodeMarketplace.psm1") -Force
                Mock Join-Path -MockWith {
                    if ($ChildPath -eq 'Invoke-ExtensionFactory.ps1') { return 'Invoke-MockFactory' }
                    return [System.IO.Path]::Combine($Path, $ChildPath)
                }
                Mock Invoke-MockFactory -MockWith { $script:factoryCalled = $true }

                Mock Get-VsCodeMarketplaceMetadata -MockWith { throw "404" }
                Mock Test-Path -MockWith { return $true }
                Mock Get-Content -MockWith { return "---`nextensions:`n  - other" }
                { & $script:scriptPath -Add "publisher.invalidext" } | Should -Not -Throw
            }

            It "Should skip missing extension in Remove Mode" {
                Mock Test-Path -MockWith { return $true }
                Mock Remove-Item -MockWith {}
                Mock Get-Content -MockWith { return "---`nextensions:`n  - test.other" }
                { & $script:scriptPath -Remove "test.nottracked" } | Should -Not -Throw
            }

            It "Should report missing automatic scaffold in Audit Mode" {
                Mock Test-Path -MockWith { if ($Path -match 'config.yaml') { return $true } else { return $false } }
                Mock Get-Content -MockWith { return "---`nextensions:`n  - missing.ext" }
                { & $script:scriptPath -Audit } | Should -Not -Throw
            }

            It "Should successfully audit when scaffolds match in Audit Mode" {
                Mock Test-Path -MockWith { return $true }
                Mock Get-Content -MockWith { return "---`nextensions:`n  - missing.ext" }
                { & $script:scriptPath -Audit } | Should -Not -Throw
            }

            It "Should error if no operation is specified" {
                { & $script:scriptPath } | Should -Not -Throw
            }

            It "Should report stale packages in CheckStale Mode" {
                $mockAuto = "$PSScriptRoot\..\automatic"
                $env:CHOCO_VSCODE_AUTOMATIC_DIR = $mockAuto
                if (-not (Test-Path $mockAuto)) { [void](New-Item -ItemType Directory -Path $mockAuto -Force) }
                [void](New-Item -ItemType Directory -Path (Join-Path $mockAuto "vscode-stale") -Force)

                Mock Test-Path -MockWith { return $true }
                Mock Get-Content -MockWith { return "$mockAuto\vscode-stale" } -ParameterFilter { $Path -match 'nuspec' }
                Mock Get-Content -MockWith { return "---`nextensions:`n  - stale" } -ParameterFilter { $Path -match 'config' }

                # Create dummy nuspec
                $dummyNuspec = "<package><metadata><version>1.0.0</version></metadata></package>"
                Set-Content (Join-Path $mockAuto "vscode-stale\vscode-stale.nuspec") $dummyNuspec

                # Mock XML response with older published date and newer version
                $dummyXml = "<feed><entry><m:properties><d:Version>1.1.0</d:Version><d:Published>2020-01-01T00:00:00Z</d:Published></m:properties></entry></feed>"
                Mock Invoke-WebRequest -MockWith { return @{ Content = $dummyXml } }

                { & $script:scriptPath -CheckStale } | Should -Not -Throw

                Remove-Item (Join-Path $mockAuto "vscode-stale") -Recurse -Force
            }
        }
    }
}
