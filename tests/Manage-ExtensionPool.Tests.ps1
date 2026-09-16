#Requires -Version 7.0
BeforeAll {
    $script:originalPSModulePath = $env:PSModulePath
    $libPath = Resolve-Path (Join-Path $PSScriptRoot "..\lib")
    $env:PSModulePath = "$libPath;$env:PSModulePath"
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\lib"))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeExtensionManager -Force
}

AfterAll {
    $env:PSModulePath = $script:originalPSModulePath
}

Describe "Manage-ExtensionPool CLI - E2E" {
    Context "Successful Route" {
        It "should cleanly route an -Add request to the extension manager factory" {
            Mock Get-ChocoVSCodeExtensionState { return @() }
            Mock Measure-VsCodeExtensionEligibility { return @{ State = 0; Message = "Mock" } }
            Mock Add-VSCodeExtension {}
            $script = Join-Path $PSScriptRoot "..\bin\Manage-ExtensionPool.ps1"
            & $script -Add "dummy.extension" -Force
            Should -Invoke -CommandName Add-VSCodeExtension -Times 1 -Scope It
        }

        It "should cleanly route a -Remove request to the extension manager shredder" {
            Mock Remove-VSCodeExtension {}
            $script = Join-Path $PSScriptRoot "..\bin\Manage-ExtensionPool.ps1"
            & $script -Remove "dummy.extension" -Force
            Should -Invoke -CommandName Remove-VSCodeExtension -Times 1 -Scope It
        }
    }

    Context "Search Route" {
        It "should cleanly route a -Search request to the marketplace api" {
            Mock Search-VsCodeMarketplace {
                return [PSCustomObject]@{
                    publisher        = [PSCustomObject]@{ publisherName = "pub" }
                    extensionName    = "ext"
                    displayName      = "Ext"
                    shortDescription = "Desc"
                }
            }
            $script = Join-Path $PSScriptRoot "..\bin\Manage-ExtensionPool.ps1"
            & $script -Search "dummy.extension"
            Should -Invoke -CommandName Search-VsCodeMarketplace -Times 1
        }
    }

    Context "Invalid Route (Fallback)" {
        It "should cleanly warn the user when no valid parameters are supplied" {
            Mock Write-Err {}
            $script = Join-Path $PSScriptRoot "..\bin\Manage-ExtensionPool.ps1"
            & $script
            Should -Invoke -CommandName Write-Err -Times 1 -ParameterFilter {
                $Message -match "valid operation"
            }
        }
    }
}
