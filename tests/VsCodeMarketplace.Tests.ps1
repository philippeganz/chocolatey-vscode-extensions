[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

$ErrorActionPreference = "Stop"

$script:modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) "bin\VsCodeMarketplace.psm1"
Import-Module $script:modulePath -Force

Describe "VsCodeMarketplace API Wrapper" {

    Context "Get-VsCodeNuspecMetadata" {
        It "Should correctly map JSON properties to Nuspec properties" {
            $mockMeta = '{
                "displayName": "Rainbow CSV",
                "shortDescription": "Highlight CSV and TSV files",
                "publisher": { "publisherName": "mechatroner" },
                "statistics": [ { "statisticName": "install", "value": 1000000 } ],
                "tags": ["csv", "tsv", "highlight"],
                "versions": [ { "properties": [ { "key": "Microsoft.VisualStudio.Services.Links.Source", "value": "https://github.com/mechatroner/vscode_rainbow_csv" } ], "files": [] } ]
            }' | ConvertFrom-Json

            $result = Get-VsCodeNuspecMetadata -ExtMeta $mockMeta -ExtensionPublisher "mechatroner" -ExtensionName "rainbow-csv"

            $result.Title | Should -Be "Visual Studio Code Extension - Rainbow CSV"
            $result.Summary | Should -Be "Highlight CSV and TSV files"
            $result.Authors | Should -Be "mechatroner"
            $result.ProjectUrl | Should -Be "https://github.com/mechatroner/vscode_rainbow_csv"
        }

        It "Should safely escape XML characters in description and title" {
            $mockMeta = '{
                "displayName": "Cool <XML> & \"Stuff\"",
                "shortDescription": "A > B & C < D",
                "publisher": { "publisherName": "author" },
                "statistics": [],
                "tags": [],
                "versions": [ { "properties": [], "files": [] } ]
            }' | ConvertFrom-Json
            $result = Get-VsCodeNuspecMetadata -ExtMeta $mockMeta -ExtensionPublisher "author" -ExtensionName "ext"

            $result.Title | Should -Not -Match "<XML>"
            $result.Title | Should -Match "&lt;XML&gt;"
            $result.Summary | Should -Match "A &gt; B &amp; C &lt; D"
        }
    }

    Context "Get-VsCodeExtensionUrl" {
        It "Should extract the win32-x64 target platform if it exists" {
            $mockMeta = '{
                "versions": [
                    { "version": "1.0.0", "targetPlatform": "win32-x64", "files": [ { "assetType": "Microsoft.VisualStudio.Services.VSIXPackage", "source": "https://win32-x64.vsix" } ] },
                    { "version": "1.0.0", "targetPlatform": "darwin-x64", "files": [ { "assetType": "Microsoft.VisualStudio.Services.VSIXPackage", "source": "https://darwin.vsix" } ] }
                ]
            }' | ConvertFrom-Json
            $url = Get-VsCodeExtensionUrl -Publisher "author" -ExtensionName "ext" -Version "1.0.0" -ExtMeta $mockMeta
            $url | Should -Be "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/author/vsextensions/ext/1.0.0/vspackage?targetPlatform=win32-x64"
        }

        It "Should fallback to the universal platform if win32-x64 is missing" {
            $mockMeta = '{
                "versions": [
                    { "version": "1.0.0", "files": [ { "assetType": "Microsoft.VisualStudio.Services.VSIXPackage", "source": "https://universal.vsix" } ] }
                ]
            }' | ConvertFrom-Json
            $url = Get-VsCodeExtensionUrl -Publisher "author" -ExtensionName "ext" -Version "1.0.0" -ExtMeta $mockMeta
            $url | Should -Be "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/author/vsextensions/ext/1.0.0/vspackage"
        }
    }

    Context "Invoke-RobustDownload (Mocked)" {
        It "Should successfully retry on transient failures" {
            # Mock Invoke-WebRequest to fail twice then succeed
            $script:failCount = 0
            Mock Invoke-WebRequest -ModuleName VsCodeMarketplace -MockWith {
                $script:failCount++
                if ($script:failCount -lt 3) {
                    throw "Transient Network Error"
                }
                return $true
            }

            # We don't want to actually sleep during tests
            Mock Start-Sleep -ModuleName VsCodeMarketplace -MockWith { return }

            Invoke-RobustDownload -Url "https://fake.url" -OutFile "fake.vsix" | Out-Null

            $script:failCount | Should -Be 3
            Should -Invoke -CommandName Invoke-WebRequest -ModuleName VsCodeMarketplace -Times 3 -Exactly
        }
    }
}
