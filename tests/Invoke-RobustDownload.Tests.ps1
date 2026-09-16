#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\lib"))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force
}

Describe "Invoke-RobustDownload" {
    Context "Successful Route" {
        It "should execute the joyful output by deferring the download block to the retry wrapper" {
            Mock Invoke-WithMarketplaceRetry -ModuleName ChocoVSCodeMarketplace {}

            Invoke-RobustDownload -Url "https://fake.url/file.vsix" -OutFile "$TestDrive\out.vsix"

            Should -Invoke -CommandName Invoke-WithMarketplaceRetry -ModuleName ChocoVSCodeMarketplace -Times 1
        }
    }
}
