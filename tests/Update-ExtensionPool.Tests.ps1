BeforeAll {
    $script:originalPSModulePath = $env:PSModulePath
    $libPath = Resolve-Path (Join-Path $PSScriptRoot "..\lib")
    $env:PSModulePath = "$libPath;$env:PSModulePath"
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
}
