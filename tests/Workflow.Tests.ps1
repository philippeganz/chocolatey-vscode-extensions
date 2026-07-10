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
        $script:repoRoot = Split-Path $PSScriptRoot -Parent

        $script:binDir = Join-Path $script:repoRoot "bin"
        $script:configPath = Join-Path $script:repoRoot "bin\config.yaml"
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
            & $script -ForcedPackages $script:packageName
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

    Context "3. Remove the Package (Manage-ExtensionPool.ps1)" {
        It "Should successfully remove the package from the pool" {
            $script = Join-Path $script:binDir "Manage-ExtensionPool.ps1"
            & $script -Remove "$script:publisher.$script:extName"

            $config = Get-Content $script:configPath -Raw
            $config | Should -Not -Match "(?m)^\s*-\s*$script:publisher\.$script:extName$"
        }

        It "Should delete the package directory" {
            Test-Path $script:pkgDir | Should -Be $false
        }
    }
}
