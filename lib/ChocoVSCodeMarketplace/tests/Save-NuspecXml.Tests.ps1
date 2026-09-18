#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force
}
Describe "Save-NuspecXml" {
    Context "Successful Route" {
        It "should execute the joyful output by pretty-printing and persisting the XML document to disk" {
            $xmlDoc = [xml]"<?xml version='1.0'?><package></package>"
            $fakePkgDir = Join-Path $TestDrive "pkg"
            New-Item -ItemType Directory -Path $fakePkgDir -Force | Out-Null
            $nuspecPath = Join-Path $fakePkgDir "vscode-test.nuspec"
            Save-NuspecXml -NuspecXml $xmlDoc -NuspecPath $nuspecPath
            Test-Path $nuspecPath | Should -Be $true
            (Get-Content $nuspecPath -Raw) | Should -Match "package"
        }
    }
}
