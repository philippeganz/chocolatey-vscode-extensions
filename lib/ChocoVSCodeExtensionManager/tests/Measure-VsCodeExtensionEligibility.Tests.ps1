#Requires -Version 7.0
BeforeAll {
    $script:originalPSModulePath = $env:PSModulePath
    $libPath = Resolve-Path (Join-Path $PSScriptRoot "..\..")
    $env:PSModulePath = "$libPath;$env:PSModulePath"
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }
    Import-Module ChocoVSCodeExtensionManager -Force
    Import-Module ChocoVSCodeMarketplace -Force
}
AfterAll {
    $env:PSModulePath = $script:originalPSModulePath
}

Describe "Measure-VsCodeExtensionEligibility" {
    Context "Lexical Pre-Checks" {
        It "should reject badly formatted identifiers" {
            $res = Measure-VsCodeExtensionEligibility -ExtensionId "badformat" -CurrentState @()
            $res.State.ToString() | Should -Be "InvalidFormat"
        }

        It "should reject identifiers with invalid characters" {
            $res = Measure-VsCodeExtensionEligibility -ExtensionId "bad_pub.bad_ext!" -CurrentState @()
            $res.State.ToString() | Should -Be "InvalidCharacters"
        }

        It "should reject already tracked identifiers" {
            $res = Measure-VsCodeExtensionEligibility -ExtensionId "pub.ext" -CurrentState @("pub.ext")
            $res.State.ToString() | Should -Be "AlreadyTracked"
        }
    }

    Context "Marketplace and Health Checks" {
        It "should reject packages not found on the Marketplace" {
            Mock Get-VsCodeMarketplaceMetadata { return $null } -ModuleName ChocoVSCodeExtensionManager
            $res = Measure-VsCodeExtensionEligibility -ExtensionId "pub.ext" -CurrentState @()
            $res.State.ToString() | Should -Be "MarketplaceNotFound"
        }

        It "should reject deprecated extensions" {
            Mock Get-VsCodeMarketplaceMetadata { return @{} } -ModuleName ChocoVSCodeExtensionManager
            Mock Measure-VsCodeExtensionHealth { return [PSCustomObject]@{ IsDeprecated = $true; DeprecationMessage = "Dep msg"; IsAbandonware = $false } } -ModuleName ChocoVSCodeExtensionManager
            $res = Measure-VsCodeExtensionEligibility -ExtensionId "pub.ext" -CurrentState @()
            $res.State.ToString() | Should -Be "MarketplaceDeprecated"
            $res.Message | Should -Be "Dep msg"
        }

        It "should reject abandonware extensions" {
            Mock Get-VsCodeMarketplaceMetadata { return @{} } -ModuleName ChocoVSCodeExtensionManager
            Mock Measure-VsCodeExtensionHealth { return [PSCustomObject]@{ IsDeprecated = $false; IsAbandonware = $true; YearsOld = 4.2 } } -ModuleName ChocoVSCodeExtensionManager
            $res = Measure-VsCodeExtensionEligibility -ExtensionId "pub.ext" -CurrentState @()
            $res.State.ToString() | Should -Be "MarketplaceAbandonware"
        }
    }

    Context "Chocolatey Ownership Checks" {
        It "should reject extensions already owned by someone else on Chocolatey" {
            Mock Get-VsCodeMarketplaceMetadata { return @{} } -ModuleName ChocoVSCodeExtensionManager
            Mock Measure-VsCodeExtensionHealth { return [PSCustomObject]@{ IsDeprecated = $false; IsAbandonware = $false } } -ModuleName ChocoVSCodeExtensionManager
            Mock Get-ChocoVSCodePackageName { return "vscode-ext" } -ModuleName ChocoVSCodeExtensionManager
            Mock Get-ChocolateyPackageMetadata { return [PSCustomObject]@{ Owners = "john.doe" } } -ModuleName ChocoVSCodeExtensionManager

            $res = Measure-VsCodeExtensionEligibility -ExtensionId "pub.ext" -CurrentState @()
            $res.State.ToString() | Should -Be "ChocolateyOwnershipConflict"
        }

        It "should accept eligible extensions" {
            Mock Get-VsCodeMarketplaceMetadata { return @{} } -ModuleName ChocoVSCodeExtensionManager
            Mock Measure-VsCodeExtensionHealth { return [PSCustomObject]@{ IsDeprecated = $false; IsAbandonware = $false } } -ModuleName ChocoVSCodeExtensionManager
            Mock Get-ChocoVSCodePackageName { return "vscode-ext" } -ModuleName ChocoVSCodeExtensionManager
            Mock Get-ChocolateyPackageMetadata { return [PSCustomObject]@{ Owners = "philippe.ganz" } } -ModuleName ChocoVSCodeExtensionManager

            $res = Measure-VsCodeExtensionEligibility -ExtensionId "pub.ext" -CurrentState @()
            $res.State.ToString() | Should -Be "Eligible"
        }
    }
}
