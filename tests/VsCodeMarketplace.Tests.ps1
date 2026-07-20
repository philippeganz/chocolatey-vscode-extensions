[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Global variables are required for AU configuration and workflow state')]
param()

$ErrorActionPreference = "Stop"

$script:modulePath = "$PSScriptRoot\..\lib\VsCodeMarketplace.psm1"
Import-Module $script:modulePath -Force

Describe "VsCodeMarketplace API Wrapper" -Tag "Unit", 'VsCodeMarketplace' {

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

    Context "Get-VsCodeMarketplaceMetadata" {
        It "Should correctly query the marketplace and return JSON metadata" {
            $mockResponse = @{
                results = @(
                    @{
                        extensions = @(
                            @{
                                extensionName = "rainbow-csv"
                                displayName   = "Rainbow CSV"
                                publisher     = @{ publisherName = "mechatroner" }
                                versions      = @( @{ version = "3.24.1" } )
                            }
                        )
                    }
                )
            }
            Mock Invoke-RestMethod -ModuleName VsCodeMarketplace -MockWith { return $mockResponse }

            $result = Get-VsCodeMarketplaceMetadata -Publisher "mechatroner" -ExtensionName "rainbow-csv"

            $result.extensionName | Should -Be "rainbow-csv"
            $result.displayName | Should -Be "Rainbow CSV"
            $result.versions[0].version | Should -Be "3.24.1"
            Should -Invoke -CommandName Invoke-RestMethod -ModuleName VsCodeMarketplace -Times 1 -Exactly
        }

        It "Should throw an error if the extension is not found" {
            $mockResponse = @{
                results = @( @{ extensions = @() } )
            }
            Mock Invoke-RestMethod -ModuleName VsCodeMarketplace -MockWith { return $mockResponse }

            { Get-VsCodeMarketplaceMetadata -Publisher "mechatroner" -ExtensionName "missing" } | Should -Throw "Extension not found on Marketplace: mechatroner.missing"
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

            [void](Invoke-RobustDownload -Url "https://fake.url" -OutFile "fake.vsix")

            $script:failCount | Should -Be 3
            Should -Invoke -CommandName Invoke-WebRequest -ModuleName VsCodeMarketplace -Times 3 -Exactly
        }
    }

    Context "Update-NuspecDependency" {
        It "Should inject extensionDependencies as chocolatey dependencies and map aliases" {
            $mockNuspec = [xml]@"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>vscode-test</id>
  </metadata>
</package>
"@
            $mockPkgJson = @{
                extensionDependencies = @("donjayamanne.python", "unknown.extension")
            }

            # Create a mock config.yaml
            $mockConfig = Join-Path $PSScriptRoot "mock_config.yaml"
            "---`nextensions:`n  - ms-python.python`n" | Set-Content $mockConfig

            # Prevent pollution of the real automatic directory and ignore expected CLI errors
            $tempAuto = Join-Path $PSScriptRoot "temp_auto"
            [void](New-Item -ItemType Directory -Path $tempAuto -Force)
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = $tempAuto

            try {
                Update-NuspecDependency -NuspecXml $mockNuspec -PackageJson $mockPkgJson -ConfigPath $mockConfig -ErrorAction SilentlyContinue
            }
            catch { Write-Verbose "Expected failure from Update-NuspecDependency missing config dependencies: $_" }

            $deps = $mockNuspec.package.metadata.dependencies.dependency
            $deps.Count | Should -Be 3
            $deps[0].id | Should -Be "chocolatey-vscode.extension"
            $deps[1].id | Should -Be "vscode-python"
            $deps[2].id | Should -Be "vscode-extension" # The fallback naming for unknown

            Remove-Item $mockConfig -Force
            Remove-Item $tempAuto -Recurse -Force
            Remove-Item Env:\CHOCO_VSCODE_AUTOMATIC_DIR -ErrorAction SilentlyContinue
        }

        It "Should process extensionPack arrays correctly" {
            $mockNuspec = [xml]@"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>vscode-pack</id>
  </metadata>
</package>
"@
            $mockPkgJson = @{
                extensionPack = @("lukehoban.Go")
            }
            $mockConfig = Join-Path $PSScriptRoot "mock_config.yaml"
            "---`nextensions:`n  - ms-python.python`n" | Set-Content $mockConfig

            try {
                Update-NuspecDependency -NuspecXml $mockNuspec -PackageJson $mockPkgJson -ConfigPath $mockConfig -ErrorAction SilentlyContinue
            }
            catch { Write-Verbose "Expected failure from Update-NuspecDependency missing config dependencies: $_" }

            $deps = $mockNuspec.package.metadata.dependencies.dependency
            $deps.Count | Should -Be 2
            $deps[0].id | Should -Be "chocolatey-vscode.extension"
            $deps[1].id | Should -Be "vscode-go"

            Remove-Item $mockConfig -Force
        }
    }

    Context "Expand-VsCodePayload" {
        It "Should extract package.json and cleanly scrub emails from README.md" {
            $tempDir = Join-Path $PSScriptRoot "temp_vsix"
            $extractDir = Join-Path $PSScriptRoot "temp_extract"
            $vsixPath = Join-Path $PSScriptRoot "fake.vsix"

            [void](New-Item -ItemType Directory -Path $tempDir -Force)
            [void](New-Item -ItemType Directory -Path (Join-Path $tempDir "extension") -Force)

            # Create a mock package.json
            '{ "name": "fake", "publisher": "test" }' | Set-Content (Join-Path $tempDir "extension\package.json")

            # Create a mock README.md with emails
            $readmeContent = @"
# Hello World
Contact me at test@example.com!
"@
            $readmeContent | Set-Content (Join-Path $tempDir "extension\README.md")

            # Zip it up as fake.vsix
            Compress-Archive -Path (Join-Path $tempDir "*") -DestinationPath $vsixPath -Force

            # Expand-VsCodePayload expects the tools directory to exist
            [void](New-Item -ItemType Directory -Path (Join-Path $extractDir "tools") -Force)

            # Run the extraction
            $result = Expand-VsCodePayload -VsixPath $vsixPath -DestinationDir $extractDir

            $result.PackageJson.name | Should -Be "fake"

            # Verify the email scrubbing
            $strippedReadme = Get-Content (Join-Path $extractDir "tools\README.md") -Raw
            $strippedReadme | Should -Not -Match "test@example.com"
            $strippedReadme | Should -Match "\[email removed\]"

            # Clean up
            Remove-Item $tempDir -Recurse -Force
            Remove-Item $extractDir -Recurse -Force
            Remove-Item $vsixPath -Force
        }
    }
}
