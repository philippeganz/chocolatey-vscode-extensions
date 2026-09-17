#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force
}
Describe "Update-VsCodeNuspecMetadata" {
    Context "Successful Route" {
        It "should execute the joyful output by dynamically replacing token placeholders in the raw XML template with accurate metadata" {
            $xmlTemplate = "<?xml version='1.0'?><package><metadata><title>placeholder</title></metadata></package>"
            $meta = @{
                Title = "Python Extension"
            }
            $xmlContent = Update-VsCodeNuspecMetadata -NuspecContent $xmlTemplate -Meta $meta
            $xmlDoc = [xml]$xmlContent
            $xmlDoc.package.metadata.title | Should -Be "Python Extension"
        }
    }
}
