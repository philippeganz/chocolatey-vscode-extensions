BeforeAll {
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeCore\ChocoVSCodeCore.psd1 -Force
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeMarketplace\ChocoVSCodeMarketplace.psd1 -Force
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeExtensionManager\ChocoVSCodeExtensionManager.psd1 -Force

    $fakeTemplatesDir = Join-Path $TestDrive "templates"
    New-Item -ItemType Directory -Path $fakeTemplatesDir | Out-Null
    $xml = "<?xml version='1.0'?><package></package>"
    Set-Content -Path (Join-Path $fakeTemplatesDir "template.nuspec") -Value $xml -Encoding UTF8
    Set-Content -Path (Join-Path $fakeTemplatesDir "chocolateyInstall.ps1") -Value " " -Encoding UTF8
    Set-Content -Path (Join-Path $fakeTemplatesDir "chocolateyUninstall.ps1") -Value " " -Encoding UTF8
}

Describe "Add-VSCodeExtension" {
    Context "Successful Route" {
        It "should execute the joyful output by orchestrating all factory components" {
            Mock Get-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager -MockWith { return @() }
            Mock Save-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Info -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Success -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Warn -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-StyledMessage -ModuleName ChocoVSCodeExtensionManager {}

            $fakeExtMeta = @{
                versions         = @(
                    @{
                        version = "1.0.0"
                        files   = @(
                            @{ assetType = "Microsoft.VisualStudio.Services.Icons.Default"; source = "http://icon" }
                        )
                    }
                )
                shortDescription = "Fake Desc"
            }
            Mock Get-VsCodeMarketplaceMetadata -ModuleName ChocoVSCodeExtensionManager -MockWith { return $fakeExtMeta }
            Mock Get-VsCodeExtensionUrl -ModuleName ChocoVSCodeExtensionManager -MockWith { return "http://fake.url" }
            Mock Invoke-RobustDownload -ModuleName ChocoVSCodeExtensionManager -MockWith {
                $expectedPath = Join-Path $TestDrive "automatic\vscode-python\tools\ms-python.python-1.0.0.vsix"
                [System.IO.File]::WriteAllBytes($expectedPath, [System.Convert]::FromBase64String("UEsFBgAAAAAAAAAAAAAAAAAAAAAAAA=="))
            }
            Mock Expand-VsCodePayload -ModuleName ChocoVSCodeExtensionManager -MockWith {
                return @{ CDataSafeReadme = "<![CDATA[readme]]>"; PackageJson = @{} }
            }
            Mock Save-VsCodeIcon -ModuleName ChocoVSCodeExtensionManager {}
            Mock New-VerificationFile -ModuleName ChocoVSCodeExtensionManager {}
            Mock Get-VsCodeNuspecMetadata -ModuleName ChocoVSCodeExtensionManager -MockWith { return @{} }
            Mock Update-VsCodeNuspecMetadata -ModuleName ChocoVSCodeExtensionManager -MockWith { return $xml }
            Mock Update-NuspecCDataDescription -ModuleName ChocoVSCodeExtensionManager {}
            Mock Update-NuspecDependency -ModuleName ChocoVSCodeExtensionManager -MockWith { return @() }
            Mock Save-NuspecXml -ModuleName ChocoVSCodeExtensionManager {}

            $fakeAutomaticDir = Join-Path $TestDrive "automatic"
            $fakeStatePath = Join-Path $TestDrive "state.yaml"
            Add-VSCodeExtension -ExtensionId "ms-python.python" -StatePath $fakeStatePath -AutomaticDir $fakeAutomaticDir -TemplatesDir $fakeTemplatesDir

            Should -Invoke -CommandName Get-VsCodeMarketplaceMetadata -ModuleName ChocoVSCodeExtensionManager -Times 1
        }
    }
}

