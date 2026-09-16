#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\lib"))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force
}

Describe "Invoke-WithMarketplaceRetry" {
    Context "Successful Route" {
        It "should execute the joyful output by returning the block output on the first try" {
            $action = { return "success_payload" }

            $res = Invoke-WithMarketplaceRetry -Action $action -ErrorMessage "Failed"

            $res | Should -Be "success_payload"
        }
    }
}
