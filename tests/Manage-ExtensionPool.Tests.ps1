BeforeAll {
    $script:originalPSModulePath = $env:PSModulePath
    $libPath = Resolve-Path (Join-Path $PSScriptRoot "..\lib")
    $env:PSModulePath = "$libPath;$env:PSModulePath"
    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeExtensionManager -Force
}

AfterAll {
    $env:PSModulePath = $script:originalPSModulePath
}

Describe "Manage-ExtensionPool CLI - E2E" {
    Context "Successful Route" {
        It "should cleanly route an -Add request to the extension manager factory" {
            Mock Get-VsCodeMarketplaceMetadata { return @{ versions = @() } }
            Mock Add-VSCodeExtension {}
            $script = Join-Path $PSScriptRoot "..\bin\Manage-ExtensionPool.ps1"
            & $script -Add "dummy.extension" -Force
            Should -Invoke -CommandName Add-VSCodeExtension -Times 1
        }

        It "should cleanly route a -Remove request to the extension manager shredder" {
            Mock Remove-VSCodeExtension {}
            $script = Join-Path $PSScriptRoot "..\bin\Manage-ExtensionPool.ps1"
            & $script -Remove "dummy.extension" -Force
            Should -Invoke -CommandName Remove-VSCodeExtension -Times 1
        }
    }
}
