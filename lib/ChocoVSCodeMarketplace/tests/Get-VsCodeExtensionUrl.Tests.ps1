#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force
}
Describe "Get-VsCodeExtensionUrl" {
    Context "Successful Route" {
        It "should execute the joyful output by returning the source URL for the specified asset type" {
            $fakeExtMeta = @{
                versions = @(
                    @{ version = "1.0.0" }
                )
            }
            $url = Get-VsCodeExtensionUrl -Publisher "ms-python" -ExtensionName "python" -Version "1.0.0" -ExtMeta $fakeExtMeta
            $url | Should -Match "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-python/vsextensions/python/1.0.0/vspackage"
        }
    }
}
