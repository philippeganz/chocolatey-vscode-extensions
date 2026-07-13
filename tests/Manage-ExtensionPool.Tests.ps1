[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

$ErrorActionPreference = "Stop"

Describe "Manage-ExtensionPool CLI" {
    BeforeAll {
        $script:scriptPath = "$PSScriptRoot\..\bin\Manage-ExtensionPool.ps1"
    }

    Context "Audit Mode" {
        It "Should succeed when config matches directories" {

            $mockAuto = "$PSScriptRoot\..\automatic"

            $env:CHOCO_VSCODE_AUTOMATIC_DIR = $mockAuto
            if (-not (Test-Path $mockAuto)) { New-Item -ItemType Directory -Path $mockAuto -Force | Out-Null }
            New-Item -ItemType Directory -Path (Join-Path $mockAuto "vscode-rainbow-csv") -Force | Out-Null

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

            & $script:scriptPath -Search "test-ext" | Out-Null

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
            if (-not (Test-Path $mockAuto)) { New-Item -ItemType Directory -Path $mockAuto -Force | Out-Null }
            New-Item -ItemType Directory -Path (Join-Path $mockAuto "vscode-missing") -Force | Out-Null

            Mock Invoke-WebRequest -MockWith { throw "404 Not Found" }

            { & $script:scriptPath -CheckStale } | Should -Not -Throw

            Remove-Item (Join-Path $mockAuto "vscode-missing") -Recurse -Force
        }
    }
}

