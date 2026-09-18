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

    Context "Platform-Specific Payload Route" {
        It "should automatically append the win32-x64 targetPlatform query flag for OS-dependent binaries (Lines 66-67)" {
            $fakeExtMeta = @{
                versions = @(
                    @{ version = "1.0.0"; targetPlatform = "win32-x64" }
                )
            }
            Mock Write-Info -ModuleName ChocoVSCodeMarketplace {}
            $url = Get-VsCodeExtensionUrl -Publisher "ms-python" -ExtensionName "python" -Version "1.0.0" -ExtMeta $fakeExtMeta
            $url | Should -Match "targetPlatform=win32-x64"

            Should -Invoke -CommandName Write-Info -ModuleName ChocoVSCodeMarketplace -Times 1 -ParameterFilter { $Message -match "win32-x64 binary" }
        }
    }
}
