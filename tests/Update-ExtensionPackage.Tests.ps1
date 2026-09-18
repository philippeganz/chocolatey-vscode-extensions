#Requires -Version 7.0
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for mocking global state in tests')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Mocked parameters are intentionally unused')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidAssignmentToAutomaticVariable', '', Justification = 'Required for mocking the choco executable args')]
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

    # Define the mock targets globally if they don't exist
    function global:Update-Package {
        [CmdletBinding()]
        param([string]$ChecksumFor)
    }
    function global:choco {
        [CmdletBinding()]
        param([Parameter(ValueFromRemainingArguments)] $args)
    }
}

AfterAll {
    $env:PSModulePath = $script:originalPSModulePath
}

Describe "Update-ExtensionPackage Execution Stub" {
    BeforeEach {
        # Required by the script
        $global:ExtensionPublisher = "mock"
        $global:ExtensionName = "extension"

        Mock Import-Module {
            if ($Name -match 'AuExtensionHooks') { return }
            & (Get-Command -CommandType Cmdlet -Name Import-Module) @args
        }
        Mock Get-ChildItem {
            return [PSCustomObject]@{
                Name     = "mock.1.0.0.nupkg"
                FullName = "C:\mock.1.0.0.nupkg"
            }
        }
        Mock choco {}
    }

    AfterEach {
        $global:ExtensionPublisher = $null
        $global:ExtensionName = $null
        $env:CHOCO_VSCODE_SKIP_VSIX_TEST = $null
        $global:LASTEXITCODE = 0
    }

    Context "When AU reports no update occurred" {
        It "should return the AU result and skip installation testing" {
            Mock Update-Package {
                return [PSCustomObject]@{ Updated = $false; Name = "mock.extension" }
            }

            $script = Join-Path $PSScriptRoot "..\bin\Update-ExtensionPackage.ps1"
            $result = & $script

            $result.Updated | Should -Be $false
            Should -Invoke -CommandName Get-ChildItem -Times 0
            Should -Invoke -CommandName choco -Times 0
        }
    }

    Context "When AU reports a successful update" {
        It "should skip VSIX testing if the environment variable override is true" {
            Mock Update-Package {
                return [PSCustomObject]@{ Updated = $true; Name = "mock.extension" }
            }
            $env:CHOCO_VSCODE_SKIP_VSIX_TEST = 'true'

            $script = Join-Path $PSScriptRoot "..\bin\Update-ExtensionPackage.ps1"
            $result = & $script

            $result.Updated | Should -Be $true
            Should -Invoke -CommandName Get-ChildItem -Times 1
            Should -Invoke -CommandName choco -Times 0
        }

        It "should successfully test install and uninstall the VSIX if no override is present" {
            Mock Update-Package {
                return [PSCustomObject]@{ Updated = $true; Name = "mock.extension" }
            }
            Mock choco {
                $global:LASTEXITCODE = 0
            }

            $script = Join-Path $PSScriptRoot "..\bin\Update-ExtensionPackage.ps1"
            $result = & $script

            $result.Updated | Should -Be $true
            Should -Invoke -CommandName choco -Times 2
        }

        It "should throw a hard exception if the custom VSIX test installation fails" {
            Mock Update-Package {
                return [PSCustomObject]@{ Updated = $true; Name = "mock.extension" }
            }
            Mock choco {
                $global:LASTEXITCODE = 1
            }

            $script = Join-Path $PSScriptRoot "..\bin\Update-ExtensionPackage.ps1"
            { & $script } | Should -Throw "Custom Test Failed for mock.1.0.0.nupkg! The VSIX payload may be corrupted or uninstallable."
        }
    }
}
