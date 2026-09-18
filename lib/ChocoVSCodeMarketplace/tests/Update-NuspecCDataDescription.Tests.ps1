#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force
}
Describe "Update-NuspecCDataDescription" {
    Context "Successful Route" {
        It "should execute the joyful output by wrapping markdown content in a CDATA section inside the XML description node" {
            $xmlDoc = [xml]"<?xml version='1.0'?><package><metadata><description>placeholder</description></metadata></package>"
            $readme = "# Hello World"
            Update-NuspecCDataDescription -NuspecXml $xmlDoc -CDataSafeReadme $readme -ShortDescription "test desc"
            $outPath = Join-Path $TestDrive "out.xml"
            $xmlDoc.Save($outPath)
            (Get-Content $outPath -Raw) | Should -Match "# Hello World"
        }
    }
    Context "Empty Readme Fallback" {
        It "should gracefully fallback to injecting the ShortDescription if the README is entirely empty (Line 54)" {
            $xmlDoc = [xml]"<?xml version='1.0'?><package><metadata><description>placeholder</description></metadata></package>"
            Update-NuspecCDataDescription -NuspecXml $xmlDoc -CDataSafeReadme "" -ShortDescription "Fallback desc"
            $outPath = Join-Path $TestDrive "out_fallback.xml"
            $xmlDoc.Save($outPath)
            (Get-Content $outPath -Raw) | Should -Match "Fallback desc"
        }
    }
}
