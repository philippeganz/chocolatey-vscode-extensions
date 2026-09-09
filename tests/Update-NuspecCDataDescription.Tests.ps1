BeforeAll {
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeCore\ChocoVSCodeCore.psd1 -Force
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeMarketplace\ChocoVSCodeMarketplace.psd1 -Force
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
}
