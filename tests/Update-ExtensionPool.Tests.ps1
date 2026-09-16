#Requires -Version 7.0
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for manipulating AU state globally in tests')]
param()

BeforeAll {
    $script:originalPSModulePath = $env:PSModulePath
    $libPath = Resolve-Path (Join-Path $PSScriptRoot "..\lib")
    $env:PSModulePath = "$libPath;$env:PSModulePath"
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\lib"))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force

    # We must define the mock target first if it doesn't exist
    function global:Update-AUPackages {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
        [CmdletBinding()]
        param($Name, $Options)
    }
}

AfterAll {
    $env:PSModulePath = $script:originalPSModulePath
}

Describe "Update-ExtensionPool CLI - E2E" {
    Context "Successful Route" {
        It "should successfully load AU and invoke update against a valid target" {
            Mock Import-Module {
                if ($Name -eq 'au') { return }
                & (Get-Command -CommandType Cmdlet -Name Import-Module) @args
            }
            function global:Update-AUPackages {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
                [CmdletBinding()]
                param($Name, $Options)
            }
            Mock Update-AUPackages {}

            $script = Join-Path $PSScriptRoot "..\bin\Update-ExtensionPool.ps1"
            # Pass a dummy package to avoid reading the whole AutomaticDir
            & $script -ForcedPackages "dummy.extension.test"
            Should -Invoke -CommandName Update-AUPackages -Times 1
        }
    }

    Context "Moderation Repush Route" {
        It "should successfully bypass native AU matching and execute a ModerationRepush" {
            $autoDir = Join-Path $TestDrive "automatic"
            $pkgName = "vscode-mock-repush"
            $pkgDir = Join-Path $autoDir $pkgName
            New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null

            $nuspecContent = @"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <version>1.5.0</version>
  </metadata>
</package>
"@
            $nuspecPath = Join-Path $pkgDir "$pkgName.nuspec"
            Set-Content -Path $nuspecPath -Value $nuspecContent -Encoding UTF8

            Mock Import-Module {
                if ($Name -eq 'au') { return }
                & (Get-Command -CommandType Cmdlet -Name Import-Module) @args
            }
            function global:Update-AUPackages {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
                [CmdletBinding()]
                param($Name, $Options)
            }
            Mock Update-AUPackages {}
            Mock Save-NuspecXml {}

            $script = Join-Path $PSScriptRoot "..\bin\Update-ExtensionPool.ps1"

            & $script -ModerationRepush $pkgName -AutomaticDir $autoDir

            # Assertions
            Should -Invoke -CommandName Save-NuspecXml -Times 1 -ParameterFilter {
                $NuspecPath -eq $nuspecPath -and $NuspecXml.package.metadata.version -eq '0.0.0'
            }
            Should -Invoke -CommandName Update-AUPackages -Times 1 -ParameterFilter {
                $Name -eq $pkgName
            }
        }
    }

    Context "Post-Execution Teardown (finally block)" {
        It "should gracefully restore orphaned README.md.bak files to README.md" {
            $autoDir = Join-Path $TestDrive "automatic"
            $pkgDir = Join-Path $autoDir "vscode-readme-test"
            New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null

            $bakPath = Join-Path $pkgDir "README.md.bak"
            Set-Content -Path $bakPath -Value "dummy hidden content" -Encoding UTF8

            Mock Import-Module {
                if ($Name -eq 'au') { return }
                & (Get-Command -CommandType Cmdlet -Name Import-Module) @args
            }
            Mock Update-AUPackages {}

            $script = Join-Path $PSScriptRoot "..\bin\Update-ExtensionPool.ps1"

            # Execute with a dummy force package to quickly hit the finally block
            & $script -ForcedPackages "dummy.extension" -AutomaticDir $autoDir

            # Assertions
            $mdPath = Join-Path $pkgDir "README.md"
            Test-Path $bakPath | Should -Be $false
            Test-Path $mdPath | Should -Be $true
            (Get-Content $mdPath) | Should -Be "dummy hidden content"
        }

        It "should successfully serialize global AU_Packages to au_results.json" {
            Push-Location $TestDrive
            try {
                $autoDir = Join-Path $TestDrive "automatic"
                New-Item -ItemType Directory -Path $autoDir -Force | Out-Null

                # Mock the global variable that native AU would usually populate
                $global:AU_Packages = @(
                    [PSCustomObject]@{
                        Name      = "test-pkg"
                        Version   = "1.0.0"
                        Updated   = $true
                        Ignore    = $false
                        Error     = $null
                        PushError = $null
                        Status    = "Successful"
                    }
                )

                Mock Import-Module {
                    if ($Name -eq 'au') { return }
                    & (Get-Command -CommandType Cmdlet -Name Import-Module) @args
                }
                Mock Update-AUPackages {}

                $script = Join-Path $PSScriptRoot "..\bin\Update-ExtensionPool.ps1"
                & $script -ForcedPackages "dummy" -AutomaticDir $autoDir

                # Assertions
                $outPath = Join-Path $TestDrive "var\state\au_results.json"
                Test-Path $outPath | Should -Be $true
                $json = Get-Content -Path $outPath -Raw | ConvertFrom-Json
                $json.Name | Should -Be "test-pkg"
            }
            finally {
                Pop-Location
                $global:AU_Packages = $null
            }
        }
    }
}
