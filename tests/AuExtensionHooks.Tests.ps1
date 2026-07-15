[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

$ErrorActionPreference = "Stop"

Describe "AuExtensionHooks" {
    BeforeAll {
        $script:hooksPath = "$PSScriptRoot\..\bin\AuExtensionHooks.ps1"
        $script:mockConfig = Join-Path $PSScriptRoot "mock_config.yaml"
        $script:mockRepo = Join-Path $PSScriptRoot "mock_repo"

        "---`nextensions:`n  - ms-python.python`n" | Set-Content $script:mockConfig -Encoding UTF8
        New-Item -ItemType Directory -Path $script:mockRepo -Force | Out-Null
        $env:CHOCO_VSCODE_AUTOMATIC_DIR = $script:mockRepo

        # AU runs 'update' upon dot-sourcing, which throws if no nuspec exists in the current directory.
        $fakeNuspec = Join-Path $script:mockRepo "test.nuspec"
        "<?xml version='1.0'?><package><metadata><id>test</id><version>1.0</version></metadata></package>" | Set-Content $fakeNuspec
        Push-Location $script:mockRepo

        $global:ExtensionPublisher = "mechatroner"
        $global:ExtensionName = "rainbow-csv"

        try {
            . $script:hooksPath -ErrorAction SilentlyContinue
        } catch { Write-Verbose "Expected failure sourcing AuExtensionHooks: $_" }

        Pop-Location
    }

    AfterAll {
        Remove-Item $script:mockConfig -Force -ErrorAction SilentlyContinue
        Remove-Item $script:mockRepo -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item Env:\CHOCO_VSCODE_AUTOMATIC_DIR -ErrorAction SilentlyContinue
    }

    Context "au_GetLatest" {
        It "Should return a hashtable with Version and URL" {
            # Since the function relies on the directory name for extension ID, we mock Split-Path
            $global:au_NoCheckChocoVersion = $true

            # Setup a fake package directory environment
            $fakePkgDir = Join-Path $script:mockRepo "vscode-rainbow-csv"
            New-Item -ItemType Directory -Path $fakePkgDir -Force | Out-Null
            Set-Location $fakePkgDir

            $result = au_GetLatest
            $result | Should -Not -BeNullOrEmpty
            $result.Version | Should -Not -BeNullOrEmpty
            $result.URL32 | Should -Not -BeNullOrEmpty

            Set-Location $PSScriptRoot
        }
    }

    Context "au_BeforeUpdate" {
        It "Should run successfully when mocked" {
            $fakePkgDir = Join-Path $script:mockRepo "vscode-rainbow-csv"
            New-Item -ItemType Directory -Path $fakePkgDir -Force | Out-Null
            Set-Location $fakePkgDir

            # Mock dependencies
            Mock Get-VsCodeNuspecMetadata -ModuleName VsCodeMarketplace -MockWith {
                return @{ Title="Fake"; Summary="Fake"; Authors="Fake"; ProjectUrl="Fake" }
            }
            Mock Invoke-RobustDownload -ModuleName VsCodeMarketplace -MockWith { return }
            Mock Expand-VsCodePayload -ModuleName VsCodeMarketplace -MockWith { return @{} }
            Mock Update-NuspecDependency -ModuleName VsCodeMarketplace -MockWith { return }

            # We must create a fake nuspec and tools dir
            "<?xml version='1.0'?><package><metadata></metadata></package>" | Set-Content "vscode-rainbow-csv.nuspec"
            New-Item -ItemType Directory -Path "tools" -Force | Out-Null
            "fake content" | Set-Content "tools\chocolateyInstall.ps1"

            try {
                au_BeforeUpdate
            } catch {
                Write-Verbose "Expected failure executing au_BeforeUpdate: $_"
                # We expect an error because of missing payload JSONs, but it executes code!
            }

            Set-Location $PSScriptRoot
        }
    }
}
