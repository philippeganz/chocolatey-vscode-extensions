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
        It "should evaluate default parameters and standard Cron Run when omitted (Line 77, 82, 198)" {
            Mock Import-Module {
                if ($Name -eq 'au') { return }
                & (Get-Command -CommandType Cmdlet -Name Import-Module) @args
            }
            Mock Update-AUPackages {}
            $script = Join-Path $PSScriptRoot "..\bin\Update-ExtensionPool.ps1"
            # Clear env vars to force fallback to $PSScriptRoot
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = $null
            $env:CHOCO_VSCODE_STATE_DIR = $null
            # Run without parameters to trigger standard Cron Run (Line 198)
            & $script
            Should -Invoke -CommandName Update-AUPackages -Times 1
        }

                It "should evaluate default parameters using environment variables (Line 77, 82 - left side of AST)" {
            Mock Import-Module {
                if ($Name -eq 'au') { return }
                & (Get-Command -CommandType Cmdlet -Name Import-Module) @args
            }
            Mock Update-AUPackages {}
            $script = Join-Path $PSScriptRoot "..\bin\Update-ExtensionPool.ps1"
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = Join-Path $TestDrive "auto"
            $env:CHOCO_VSCODE_STATE_DIR = Join-Path $TestDrive "state"
            New-Item -ItemType Directory -Path $env:CHOCO_VSCODE_AUTOMATIC_DIR -Force | Out-Null
            & $script
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = $null
            $env:CHOCO_VSCODE_STATE_DIR = $null
        }

        It "should apply PushUrl override if specified (Line 92-93)" {
            Mock Import-Module {
                if ($Name -eq 'au') { return }
                & (Get-Command -CommandType Cmdlet -Name Import-Module) @args
            }
            Mock Update-AUPackages {}
            $script = Join-Path $PSScriptRoot "..\bin\Update-ExtensionPool.ps1"
            & $script -ForcedPackages "dummy" -PushUrl "https://nexus.local"
            $env:au_PushUrl | Should -Be "https://nexus.local"
        }

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
        It "should clean update_info.xml and run choco push loop successfully (Line 134, 143-176)" {
            $autoDir = Join-Path $TestDrive "automatic"
            $pkgName = "vscode-mock-repush"
            $pkgDir = Join-Path $autoDir $pkgName
            New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null

            # Trigger update_info.xml deletion (Line 134)
            $infoPath = Join-Path $pkgDir "update_info.xml"
            Set-Content -Path $infoPath -Value "dummy" -Encoding UTF8

            # Trigger choco push loop (Line 143-176)
            $nupkgPath = Join-Path $pkgDir "dummy.1.0.0.nupkg"
            Set-Content -Path $nupkgPath -Value "binary payload"
            $env:api_key = "dummy_key"
            $env:au_PushUrl = $null

            # Mock choco native command
            function global:choco {
                if ($args[0] -eq 'push') {
                    $global:LASTEXITCODE = 0
                    return "Push successful."
                }
            }

            Mock Import-Module {
                if ($Name -eq 'au') { return }
                & (Get-Command -CommandType Cmdlet -Name Import-Module) @args
            }
            Mock Update-AUPackages {}
            Mock Save-NuspecXml {}
            Mock Write-Success {}

            $script = Join-Path $PSScriptRoot "..\bin\Update-ExtensionPool.ps1"
            & $script -ModerationRepush $pkgName -AutomaticDir $autoDir

            Test-Path $infoPath | Should -Be $false
            Should -Invoke -CommandName Write-Success -ParameterFilter { $Message -match "Push successful on attempt 1" }

            # Cleanup
            $env:api_key = $null
            Remove-Item -Path function:\global:choco -ErrorAction SilentlyContinue
        }

                It "should handle push failures, trigger retry wait, and eventually throw if max retries exhausted (Line 164-167, 172)" {
            $autoDir = Join-Path $TestDrive "automatic"
            $pkgName = "vscode-mock-repush"
            $pkgDir = Join-Path $autoDir $pkgName
            New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null
            Set-Content -Path (Join-Path $pkgDir "dummy.1.0.0.nupkg") -Value "binary payload"
            $env:api_key = "dummy_key"

            function global:choco {
                $global:LASTEXITCODE = 1
                return "500 Internal Server Error"
            }

            Mock Import-Module {
                if ($Name -eq 'au') { return }
                & (Get-Command -CommandType Cmdlet -Name Import-Module) @args
            }
            Mock Update-AUPackages {}
            Mock Save-NuspecXml {}
            Mock Write-Warn {}
            Mock Write-Info {}
            Mock Start-Sleep {}

            $script = Join-Path $PSScriptRoot "..\bin\Update-ExtensionPool.ps1"
            { & $script -ModerationRepush $pkgName -AutomaticDir $autoDir } | Should -Throw "All 3 push attempts failed*"

            Should -Invoke -CommandName Write-Warn -Times 3 -ParameterFilter { $Message -match "Push attempt" }
            Should -Invoke -CommandName Start-Sleep -Times 2 -ParameterFilter { $Seconds -eq 20 }

            $env:api_key = $null
            Remove-Item -Path function:\global:choco -ErrorAction SilentlyContinue
        }

        It "should log error when no .nupkg is generated during repush (Line 180)" {
            $autoDir = Join-Path $TestDrive "automatic"
            $pkgName = "vscode-mock-missing-nupkg"
            $pkgDir = Join-Path $autoDir $pkgName
            New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null
            # Purposely DO NOT create a .nupkg file

            Mock Import-Module {
                if ($Name -eq 'au') { return }
                & (Get-Command -CommandType Cmdlet -Name Import-Module) @args
            }
            Mock Update-AUPackages {}
            Mock Save-NuspecXml {}
            Mock Write-Err {}

            $script = Join-Path $PSScriptRoot "..\bin\Update-ExtensionPool.ps1"
            & $script -ModerationRepush $pkgName -AutomaticDir $autoDir

            Should -Invoke -CommandName Write-Err -Times 1 -ParameterFilter { $Message -match "No .nupkg was generated" }
        }

        It "should handle already exists during choco push (Line 158-161)" {
            $autoDir = Join-Path $TestDrive "automatic"
            $pkgName = "vscode-mock-repush"
            $pkgDir = Join-Path $autoDir $pkgName
            New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null
            Set-Content -Path (Join-Path $pkgDir "dummy.1.0.0.nupkg") -Value "binary payload"
            $env:api_key = "dummy_key"

            function global:choco {
                $global:LASTEXITCODE = 1
                return "already exists"
            }

            Mock Import-Module {
                if ($Name -eq 'au') { return }
                & (Get-Command -CommandType Cmdlet -Name Import-Module) @args
            }
            Mock Update-AUPackages {}
            Mock Save-NuspecXml {}
            Mock Write-Warn {}

            $script = Join-Path $PSScriptRoot "..\bin\Update-ExtensionPool.ps1"
            & $script -ModerationRepush $pkgName -AutomaticDir $autoDir

            Should -Invoke -CommandName Write-Warn -ParameterFilter { $Message -match "already approved" }

            $env:api_key = $null
            Remove-Item -Path function:\global:choco -ErrorAction SilentlyContinue
        }

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
                & $script -ForcedPackages "dummy" -AutomaticDir $autoDir -StateDir (Join-Path $TestDrive "var\state")

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
