#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force
}
Describe "Save-VsCodeIcon" {
    Context "Successful Route" {
        It "should execute the joyful output by retrieving the icon url and downloading it" {
            Mock Invoke-RobustDownload -ModuleName ChocoVSCodeMarketplace {}
            $fakePkgDir = Join-Path $TestDrive "pkg"
            New-Item -ItemType Directory -Path $fakePkgDir -Force | Out-Null
            Save-VsCodeIcon -IconUrl "https://icon.url/icon.png" -PackageDir $fakePkgDir -PackageName "vscode-bar"
            Should -Invoke -CommandName Invoke-RobustDownload -ModuleName ChocoVSCodeMarketplace -Times 1
        }
    }
    Context "Error Handling and Fallback" {
        It "should gracefully catch download exceptions, log them, and generate a transparent dummy icon fallback (Line 55)" {
            Mock Invoke-RobustDownload -ModuleName ChocoVSCodeMarketplace -MockWith { throw "HTTP 404 Not Found" }
            Mock Write-Verbose -ModuleName ChocoVSCodeMarketplace {}
            Mock Write-Warning -ModuleName ChocoVSCodeMarketplace {}
            $fakePkgDir = Join-Path $TestDrive "pkg_err"
            New-Item -ItemType Directory -Path $fakePkgDir -Force | Out-Null
            Save-VsCodeIcon -IconUrl "https://icon.url/bad.png" -PackageDir $fakePkgDir -PackageName "vscode-err"
            Should -Invoke -CommandName Write-Verbose -ModuleName ChocoVSCodeMarketplace -Times 1
            Test-Path (Join-Path $fakePkgDir "icon.png") | Should -Be $true
        }
    }
}
