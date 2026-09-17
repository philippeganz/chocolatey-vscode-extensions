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
        It "should regenerate a package if already tracked but -Force is supplied (Line 122)" {
            Mock Get-ChocoVSCodeExtensionState { return @() }
            Mock Measure-VsCodeExtensionEligibility { return @{ State = [ExtensionEligibilityState]::AlreadyTracked; Message = "Tracked" } }
            Mock Write-Info {}
            Mock Add-VSCodeExtension {}
            $script = Join-Path $PSScriptRoot "..\bin\Manage-ExtensionPool.ps1"
            & $script -Add "dummy.extension" -Force
            Should -Invoke -CommandName Write-Info -Times 1 -ParameterFilter { $Message -match "Regenerating" }
            Should -Invoke -CommandName Add-VSCodeExtension -Times 1
        }

        It "should cleanly deny eligibility without CI exit (Line 125, 127)" {
            Mock Get-ChocoVSCodeExtensionState { return @() }
            Mock Measure-VsCodeExtensionEligibility { return @{ State = [ExtensionEligibilityState]::InvalidFormat; Message = "Invalid" } }
            Mock Write-Skip {}
            Mock Add-VSCodeExtension {}
            $script = Join-Path $PSScriptRoot "..\bin\Manage-ExtensionPool.ps1"
            & $script -Add "dummy.extension"
            Should -Invoke -CommandName Write-Skip -Times 1 -ParameterFilter { $Message -match "Request Denied" }
            Should -Invoke -CommandName Add-VSCodeExtension -Times 0
        }

        It "should cleanly deny eligibility and exit with CI switch (Line 126)" {
            Mock Get-ChocoVSCodeExtensionState { return @() }
            Mock Measure-VsCodeExtensionEligibility { return @{ State = [ExtensionEligibilityState]::MarketplaceNotFound; Message = "Not Found" } }
            Mock Write-Skip {}
            $script = Join-Path $PSScriptRoot "..\bin\Manage-ExtensionPool.ps1"
            & $script -Add "dummy.extension" -CI
            $LASTEXITCODE | Should -Be 10
        }

        It "should dynamically discover and queue untracked dependencies (Line 141-145)" {
            Mock Get-ChocoVSCodeExtensionState { return @() }
            Mock Measure-VsCodeExtensionEligibility { return @{ State = [ExtensionEligibilityState]::Eligible; Message = "Valid" } }
            Mock Add-VSCodeExtension {
                if ($ExtensionId -eq "parent.ext") { return @("child.ext") }
                return $null
            }
            Mock Write-StyledMessage {}
            $script = Join-Path $PSScriptRoot "..\bin\Manage-ExtensionPool.ps1"
            & $script -Add "parent.ext"
            Should -Invoke -CommandName Add-VSCodeExtension -Times 2
            Should -Invoke -CommandName Write-StyledMessage -ParameterFilter { $Message -match "Discovered untracked dependency" }
        }

        It "should trigger Checkpoint-GitRepository when -AutoCommit is specified (Line 151)" {
            Mock Get-ChocoVSCodeExtensionState { return @() }
            Mock Measure-VsCodeExtensionEligibility { return @{ State = [ExtensionEligibilityState]::Eligible; Message = "Valid" } }
            Mock Add-VSCodeExtension {}
            Mock Checkpoint-GitRepository {}
            $script = Join-Path $PSScriptRoot "..\bin\Manage-ExtensionPool.ps1"
            & $script -Add "dummy.extension" -AutoCommit
            Should -Invoke -CommandName Checkpoint-GitRepository -Times 1
        }

        It "should catch factory exceptions, log errors, and rethrow (Line 157-160)" {
            Mock Get-ChocoVSCodeExtensionState { return @() }
            Mock Measure-VsCodeExtensionEligibility { return @{ State = [ExtensionEligibilityState]::Eligible; Message = "Valid" } }
            Mock Add-VSCodeExtension { throw "Factory Explosion" }
            Mock Write-Err {}
            $script = Join-Path $PSScriptRoot "..\bin\Manage-ExtensionPool.ps1"
            { & $script -Add "dummy.extension" } | Should -Throw "Factory Explosion"
            Should -Invoke -CommandName Write-Err -Times 1
        }
        It "should cleanly route an -Add request to the extension manager factory" {
            Mock Get-ChocoVSCodeExtensionState { return @() }
            Mock Measure-VsCodeExtensionEligibility { return @{ State = 0; Message = "Mock" } }
            Mock Add-VSCodeExtension {}
            $script = Join-Path $PSScriptRoot "..\bin\Manage-ExtensionPool.ps1"
            & $script -Add "dummy.extension" -Force
            Should -Invoke -CommandName Add-VSCodeExtension -Times 1 -Scope It
        }

        It "should exit early when removing an untracked extension in CI mode (Line 179-180)" {
            Mock Get-ChocoVSCodeExtensionState { return @() }
            Mock Write-Skip {}
            $script = Join-Path $PSScriptRoot "..\bin\Manage-ExtensionPool.ps1"
            & $script -Remove "untracked.ext" -CI
            $LASTEXITCODE | Should -Be 30
            Should -Invoke -CommandName Write-Skip -ParameterFilter { $Message -match "Not tracked in state file" }
        }

        It "should trigger Checkpoint-GitRepository when removing with -AutoCommit (Line 195)" {
            Mock Get-ChocoVSCodeExtensionState { return @("dummy.extension") }
            Mock Remove-VSCodeExtension {}
            Mock Checkpoint-GitRepository {}
            $script = Join-Path $PSScriptRoot "..\bin\Manage-ExtensionPool.ps1"
            & $script -Remove "dummy.extension" -AutoCommit
            Should -Invoke -CommandName Checkpoint-GitRepository -Times 1
        }

        It "should cleanly route a -Remove request to the extension manager shredder" {
            Mock Remove-VSCodeExtension {}
            $script = Join-Path $PSScriptRoot "..\bin\Manage-ExtensionPool.ps1"
            & $script -Remove "dummy.extension" -Force
            Should -Invoke -CommandName Remove-VSCodeExtension -Times 1 -Scope It
        }
    }

    Context "Search Route" {
        It "should handle empty search results gracefully (Line 208)" {
            Mock Search-VsCodeMarketplace { return @() }
            Mock Write-Skip {}
            $script = Join-Path $PSScriptRoot "..\bin\Manage-ExtensionPool.ps1"
            & $script -Search "not.real"
            Should -Invoke -CommandName Write-Skip -ParameterFilter { $Message -match "No extensions found" }
        }
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
