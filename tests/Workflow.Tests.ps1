[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()
$ErrorActionPreference = "Stop"

$script:repoRoot = "C:\Users\ganzp\git\chocolatey-vscode-extensions"
$script:binDir = Join-Path $script:repoRoot "bin"
$script:configPath = Join-Path $script:repoRoot "bin\config.yaml"

$script:publisher = "mechatroner"
$script:extName = "rainbow-csv"
$script:packageName = "vscode-rainbow-csv"

$script:realPackagesDir = Join-Path $script:repoRoot "automatic"
$script:bakPackagesDir = Join-Path $script:repoRoot "automatic_bak"
$script:pkgDir = Join-Path $script:realPackagesDir $script:packageName

$script:configBackup = Join-Path $script:repoRoot "config.yaml.bak"

Describe "VSCode Extensions Chocolatey Workflow" {

    BeforeAll {
        # 1. Backup Config
        $script:configPath = Join-Path $script:repoRoot "bin\config.yaml"
        if (Test-Path $script:configPath) {
            $script:configBackup = Get-Content $script:configPath -Raw
        }

        $minimalConfig = @"
---
extensions:
"@
        $minimalConfig | Set-Content $script:configPath -Encoding UTF8

        # 2. Isolate the Packages Directory (hide all real packages to speed up AU)
        if (Test-Path $script:bakPackagesDir) {
            Remove-Item $script:bakPackagesDir -Recurse -Force
        }
        if (Test-Path $script:realPackagesDir) {
            Rename-Item -Path $script:realPackagesDir -NewName "automatic_bak" -Force
        }
        New-Item -ItemType Directory -Path $script:realPackagesDir -Force | Out-Null
    }

    AfterAll {
        # 1. Restore Config
        if ($script:configBackup) {
            $script:configBackup | Set-Content $script:configPath -Encoding UTF8
        }

        # 2. Restore Packages Directory
        if (Test-Path $script:realPackagesDir) {
            Remove-Item $script:realPackagesDir -Recurse -Force
        }
        if (Test-Path $script:bakPackagesDir) {
            Rename-Item -Path $script:bakPackagesDir -NewName "automatic" -Force
        }
    }

    Context "1. Add a Package (Manage-ExtensionPool.ps1)" {
        It "Should successfully add the package to the pool" {
            $script = Join-Path $script:binDir "Manage-ExtensionPool.ps1"
            & $script -Add "$script:publisher.$script:extName"

            $config = Get-Content $script:configPath -Raw
            $config | Should Match "(?m)^\s*-\s*$script:publisher\.$script:extName$"
        }

        It "Should create the scaffolding template with 0.0.0 version" {
            Test-Path $script:pkgDir | Should Be $true
            Test-Path (Join-Path $script:pkgDir "$script:packageName.nuspec") | Should Be $true
            Test-Path (Join-Path $script:pkgDir "update.ps1") | Should Be $true
            Test-Path (Join-Path $script:pkgDir "tools\chocolateyInstall.ps1") | Should Be $true

            $nuspec = [xml](Get-Content (Join-Path $script:pkgDir "$script:packageName.nuspec"))
            $nuspec.package.metadata.version | Should Be "0.0.0"
        }
    }

    Context "2. Update the Package (Invoke-AuUpdater.ps1)" {
        It "Should run the AU updater and update metadata/binaries" {
            $script = Join-Path $script:binDir "Invoke-AuUpdater.ps1"
            & $script -ForcedPackages $script:packageName
        }

        It "Should bump the version in the nuspec to a real version" {
            $nuspec = [xml](Get-Content (Join-Path $script:pkgDir "$script:packageName.nuspec"))
            $nuspec.package.metadata.version | Should Not Be "0.0.0"
            $nuspec.package.metadata.version | Should Match "^\d+\.\d+\.\d+"
        }

        It "Should populate the tools directory with metadata files" {
            $toolsDir = Join-Path $script:pkgDir "tools"
            Test-Path (Join-Path $toolsDir "README.md") | Should Be $true
        }
    }

    Context "3. Remove the Package (Manage-ExtensionPool.ps1)" {
        It "Should successfully remove the package from the pool" {
            $script = Join-Path $script:binDir "Manage-ExtensionPool.ps1"
            & $script -Remove "$script:publisher.$script:extName"

            $config = Get-Content $script:configPath -Raw
            $config | Should Not Match "(?m)^\s*-\s*$script:publisher\.$script:extName$"
        }

        It "Should delete the package directory" {
            Test-Path $script:pkgDir | Should Be $false
        }
    }
}


