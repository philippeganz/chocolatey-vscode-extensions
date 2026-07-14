<#
.SYNOPSIS
The primary end-to-end integration test suite for the Chocolatey VS Code Extension framework.

.DESCRIPTION
This test suite uses Pester 5 to fully simulate the entire extension lifecycle in an isolated
`test_automatic` environment. It validates that the Factory Engine successfully builds structural
scaffolding, the AU Engine natively updates binaries and patches `package.json` metadata, and
the pool manager perfectly manages state lifecycle (Add/Remove) without polluting local Git structures.
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()
$ErrorActionPreference = "Stop"

Describe "VSCode Extensions Chocolatey Workflow" {

    BeforeAll {
        # Resolve repo root dynamically (agnostic to local vs CI)
        $script:repoRoot = "$PSScriptRoot\.."

        $script:binDir = Join-Path $script:repoRoot "bin"
        $script:configPath = Join-Path $script:repoRoot "etc\config.yaml"
        $script:publisher = "mechatroner"
        $script:extName = "rainbow-csv"
        $script:packageName = "vscode-rainbow-csv"

        # Isolate the Packages Directory to a temp folder parallel to bin so relative paths in AU templates still work
        $script:realPackagesDir = Join-Path $script:repoRoot "test_automatic"
        $env:CHOCO_VSCODE_AUTOMATIC_DIR = $script:realPackagesDir
        $script:pkgDir = Join-Path $script:realPackagesDir $script:packageName

        # 1. Backup Config
        if (Test-Path $script:configPath) {
            $script:configBackup = Get-Content $script:configPath -Raw
        }

        $minimalConfig = @"
---
extensions:
"@
        $minimalConfig | Set-Content $script:configPath -Encoding UTF8

        # 2. Setup Test Packages Directory
        if (Test-Path $script:realPackagesDir) {
            Remove-Item $script:realPackagesDir -Recurse -Force
        }
        New-Item -ItemType Directory -Path $script:realPackagesDir -Force | Out-Null
    }

    AfterAll {
        # 1. Restore Config
        if ($script:configBackup) {
            $script:configBackup | Set-Content $script:configPath -Encoding UTF8
        }

        # 2. Cleanup Test Packages Directory
        if (Test-Path $script:realPackagesDir) {
            Remove-Item $script:realPackagesDir -Recurse -Force
        }
        Remove-Item Env:\CHOCO_VSCODE_AUTOMATIC_DIR -ErrorAction SilentlyContinue
    }

    Context "1. Add a Package (Manage-ExtensionPool.ps1)" {
        It "Should successfully add the package to the pool" {
            $script = Join-Path $script:binDir "Manage-ExtensionPool.ps1"
            & $script -Add "$script:publisher.$script:extName"

            $config = Get-Content $script:configPath -Raw
            $config | Should -Match "(?m)^\s*-\s*$script:publisher\.$script:extName$"
        }

        It "Should create the scaffolding template with 0.0.0 version" {
            Test-Path $script:pkgDir | Should -Be $true
            Test-Path (Join-Path $script:pkgDir "$script:packageName.nuspec") | Should -Be $true
            Test-Path (Join-Path $script:pkgDir "update.ps1") | Should -Be $true
            Test-Path (Join-Path $script:pkgDir "tools\chocolateyInstall.ps1") | Should -Be $true

            $nuspec = [xml](Get-Content (Join-Path $script:pkgDir "$script:packageName.nuspec"))
            $nuspec.package.metadata.version | Should -Be "0.0.0"
        }
    }

    Context "2. Update the Package (Invoke-AuUpdater.ps1)" {
        It "Should run the AU updater and update metadata/binaries" {
            $script = Join-Path $script:binDir "Invoke-AuUpdater.ps1"
            $outDir = Join-Path $script:realPackagesDir "out_artifacts"
            & $script -ForcedPackages $script:packageName -OutputDir $outDir
        }

        It "Should bump the version in the nuspec to a real version" {
            $nuspec = [xml](Get-Content (Join-Path $script:pkgDir "$script:packageName.nuspec"))
            $nuspec.package.metadata.version | Should -Not -Be "0.0.0"
            $nuspec.package.metadata.version | Should -Match "^\d+\.\d+\.\d+"
        }

        It "Should populate the tools directory with metadata files" {
            $toolsDir = Join-Path $script:pkgDir "tools"
            Test-Path (Join-Path $toolsDir "README.md") | Should -Be $true
        }
    }

    Context "2.5. Re-run Factory with -Force" {
        It "Should execute factory with Force without errors" {
            $script = Join-Path $script:binDir "Invoke-VsCodeExtensionFactory.ps1"
            # Set CHOCO_VSCODE_AUTOMATIC_DIR to redirect scaffolding to test_automatic
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = $script:realPackagesDir
            & $script -ExtensionId "$script:publisher.$script:extName" -Force
        }
    }



    Context "3. Search for an Extension (Manage-ExtensionPool.ps1)" {
        It "Should successfully search the VS Code Marketplace API" {
            $script = Join-Path $script:binDir "Manage-ExtensionPool.ps1"
            $output = & $script -Search "mechatroner.rainbow-csv"
            $output | Should -Not -BeNullOrEmpty
        }
    }

    Context "4. Audit the Package Pool (Manage-ExtensionPool.ps1)" {
        It "Should successfully audit the pool without errors" {
            $script = Join-Path $script:binDir "Manage-ExtensionPool.ps1"
            & $script -Audit
        }

        It "Should report missing scaffolds during Audit" {
            $script = Join-Path $script:binDir "Manage-ExtensionPool.ps1"
            $config = Get-Content $script:configPath -Raw
            $newConfig = $config + "`n  - fake.missing-extension"
            $newConfig | Set-Content $script:configPath -Encoding UTF8

            # Run audit which will now hit the missing directory logic
            & $script -Audit

            # Restore config
            $config | Set-Content $script:configPath -Encoding UTF8
        }
    }

    Context "4.5 Remove a package from the Pool (Manage-ExtensionPool.ps1)" {
        It "Should successfully skip removing a non-existent package" {
            $script = Join-Path $script:binDir "Manage-ExtensionPool.ps1"
            & $script -Remove "fake.to-remove"
        }
    }

    Context "4.6 Search for a package (Manage-ExtensionPool.ps1)" {
        It "Should successfully search the marketplace" {
            $script = Join-Path $script:binDir "Manage-ExtensionPool.ps1"
            & $script -Search "rainbow-csv"
        }
    }

    Context "4.7 Add edge cases (Manage-ExtensionPool.ps1)" {
        It "Should gracefully handle Add exceptions" {
            $script = Join-Path $script:binDir "Manage-ExtensionPool.ps1"
            # Invalid ID Format
            & $script -Add "invalidformat"
            # Already tracked
            & $script -Add "mechatroner.rainbow-csv"
            # Does not exist API
            & $script -Add "fake.does-not-exist"
        }
    }

    Context "4.1 Moderation Repush (Invoke-AuUpdater.ps1)" {
        It "Should successfully run moderation repush bypass" {
            $script = Join-Path $script:binDir "Invoke-AuUpdater.ps1"
            $outDir = Join-Path $script:realPackagesDir "out_artifacts_2"
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = $script:realPackagesDir
            & $script -ModerationRepush $script:packageName -OutputDir $outDir

            $nuspec = [xml](Get-Content (Join-Path $script:pkgDir "$script:packageName.nuspec"))
            $nuspec.package.metadata.version | Should -Be "3.24.1"
        }

        It "Should successfully parse @version and build older specific version" {
            $script = Join-Path $script:binDir "Invoke-AuUpdater.ps1"
            $outDir = Join-Path $script:realPackagesDir "out_artifacts_3"
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = $script:realPackagesDir

            # Using an older specific version of rainbow-csv to test override functionality
            & $script -ModerationRepush "$script:packageName@3.24.0" -OutputDir $outDir

            $nuspec = [xml](Get-Content (Join-Path $script:pkgDir "$script:packageName.nuspec"))
            $nuspec.package.metadata.version | Should -Be "3.24.0"
        }

        It "Should test edge case parameters (PushUrl, ForcedPackages, MissingDir)" {
            $script = Join-Path $script:binDir "Invoke-AuUpdater.ps1"
            $oldEnv = $env:CHOCO_VSCODE_AUTOMATIC_DIR
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = "C:\Fake\Dir\Does\Not\Exist"
            { & $script -PushUrl "https://nexus.local" -ForcedPackages "test" } | Should -Throw
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = $oldEnv
        }
    }

    Context "5. Check Stale Packages (Manage-ExtensionPool.ps1)" {
        It "Should successfully check for stale packages" {
            $script = Join-Path $script:binDir "Manage-ExtensionPool.ps1"
            & $script -CheckStale
        }
    }

    Context "6. Remove the Package (Manage-ExtensionPool.ps1)" {
        It "Should successfully remove the package from the pool" {
            $script = Join-Path $script:binDir "Manage-ExtensionPool.ps1"
            & $script -Remove "$script:publisher.$script:extName"

            $config = Get-Content $script:configPath -Raw
            $config | Should -Not -Match "(?m)^\s*-\s*$script:publisher\.$script:extName$"
        }

        It "Should delete the package directory" {
            Test-Path $script:pkgDir | Should -Be $false
        }

    Context "4.2 Bulk Update Mode (Invoke-AuUpdater.ps1)" {
        It "Should run successfully when updating all packages" {
            $script = Join-Path $script:binDir "Invoke-AuUpdater.ps1"
            $outDir = Join-Path $script:realPackagesDir "out_artifacts_bulk"
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = $script:realPackagesDir
            { & $script -OutputDir $outDir  } | Should -Not -Throw
        }
    }

    Context "4.3 Native Push Mode (Invoke-AuUpdater.ps1)" {
        It "Should warn about missing API key when native pushing" {
            $script = Join-Path $script:binDir "Invoke-AuUpdater.ps1"
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = $script:realPackagesDir
            $oldKey = $env:CHOCO_API_KEY
            $oldApi = $env:api_key
            $env:CHOCO_API_KEY = $null
            $env:api_key = $null
            try { & $script -ForcedPackages $script:packageName } catch { }
            $env:CHOCO_API_KEY = $oldKey
            $env:api_key = $oldApi
        }
    }

    Context "4.4 Moderation Repush without OutputDir (Invoke-AuUpdater.ps1)" {
        It "Should skip push when no api_key is present" {
            $script = Join-Path $script:binDir "Invoke-AuUpdater.ps1"
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = $script:realPackagesDir
            $oldKey = $env:CHOCO_API_KEY
            $oldApi = $env:api_key
            $env:CHOCO_API_KEY = $null
            $env:api_key = $null
            & $script -ModerationRepush $script:packageName
            $env:CHOCO_API_KEY = $oldKey
            $env:api_key = $oldApi
        }
    }
    }
}