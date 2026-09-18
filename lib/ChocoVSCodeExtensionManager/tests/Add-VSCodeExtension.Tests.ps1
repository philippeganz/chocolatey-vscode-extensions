#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force
    Import-Module ChocoVSCodeExtensionManager -Force

    $fakeTemplatesDir = Join-Path $TestDrive "templates"
    New-Item -ItemType Directory -Path $fakeTemplatesDir -Force | Out-Null
    $xml = "<?xml version='1.0'?><package></package>"
    Set-Content -Path (Join-Path $fakeTemplatesDir "template.nuspec") -Value $xml -Encoding UTF8
    Set-Content -Path (Join-Path $fakeTemplatesDir "chocolateyInstall.ps1") -Value " " -Encoding UTF8
    Set-Content -Path (Join-Path $fakeTemplatesDir "chocolateyUninstall.ps1") -Value " " -Encoding UTF8

    $fakeExtMeta = @{
        versions         = @(
            @{
                version = "1.0.0"
                files   = @( @{ assetType = "Microsoft.VisualStudio.Services.Icons.Default"; source = "http://icon" } )
            }
        )
        shortDescription = "Fake Desc"
    }

    $script:fakeExtMeta = $fakeExtMeta
    $script:xmlTemplate = $xml
}

Describe "Add-VSCodeExtension" {
    Context "Successful Route" {
        It "should execute the joyful output by orchestrating all factory components" {
            Mock Write-Info -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Success -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Warn -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-StyledMessage -ModuleName ChocoVSCodeExtensionManager {}
            Mock Get-VsCodeMarketplaceMetadata -ModuleName ChocoVSCodeExtensionManager -MockWith { return $script:fakeExtMeta }
            Mock Get-VsCodeExtensionUrl -ModuleName ChocoVSCodeExtensionManager -MockWith { return "http://fake.url" }
            Mock Invoke-RobustDownload -ModuleName ChocoVSCodeExtensionManager -MockWith {
                $expectedPath = Join-Path $TestDrive "automatic\vscode-python\tools\ms-python.python-1.0.0.vsix"
                [System.IO.File]::WriteAllBytes($expectedPath, [System.Convert]::FromBase64String("UEsFBgAAAAAAAAAAAAAAAAAAAAAAAA=="))
            }
            Mock Expand-VsCodePayload -ModuleName ChocoVSCodeExtensionManager -MockWith { return @{ CDataSafeReadme = "<![CDATA[readme]]>"; PackageJson = @{} } }
            Mock Save-VsCodeIcon -ModuleName ChocoVSCodeExtensionManager {}
            Mock New-VerificationFile -ModuleName ChocoVSCodeExtensionManager {}
            Mock Get-VsCodeNuspecMetadata -ModuleName ChocoVSCodeExtensionManager -MockWith { return @{} }
            Mock Update-VsCodeNuspecMetadata -ModuleName ChocoVSCodeExtensionManager -MockWith { return $script:xmlTemplate }
            Mock Update-NuspecCDataDescription -ModuleName ChocoVSCodeExtensionManager {}
            Mock Update-NuspecDependency -ModuleName ChocoVSCodeExtensionManager -MockWith { return @() }
            Mock Save-NuspecXml -ModuleName ChocoVSCodeExtensionManager {}

            $fakeAutomaticDir = Join-Path $TestDrive "automatic"
            $fakeStatePath = Join-Path $TestDrive "state.json"
            Add-VSCodeExtension -ExtensionId "ms-python.python" -StatePath $fakeStatePath -AutomaticDir $fakeAutomaticDir -TemplatesDir $fakeTemplatesDir

            Should -Invoke -CommandName Get-VsCodeMarketplaceMetadata -ModuleName ChocoVSCodeExtensionManager -Times 1
        }
    }

    Context "Error Handling and Validation" {
        It "should throw an ArgumentException if the ExtensionId is improperly formatted (Line 93)" {
            Mock Write-StyledMessage -ModuleName ChocoVSCodeExtensionManager {}
            $fakeAutomaticDir = Join-Path $TestDrive "auto_err"
            $fakeStatePath = Join-Path $TestDrive "state.json"

            { Add-VSCodeExtension -ExtensionId "badformat" -StatePath $fakeStatePath -AutomaticDir $fakeAutomaticDir -TemplatesDir $fakeTemplatesDir } | Should -Throw -ExceptionType System.ArgumentException
        }

        It "should log and rethrow if the VS Code Marketplace API fails (Lines 121-122)" {
            Mock Write-StyledMessage -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Err -ModuleName ChocoVSCodeExtensionManager {}
            Mock Get-VsCodeMarketplaceMetadata -ModuleName ChocoVSCodeExtensionManager -MockWith { throw "Marketplace Outage" }

            $fakeAutomaticDir = Join-Path $TestDrive "auto_api_err"
            $fakeStatePath = Join-Path $TestDrive "state.json"

            { Add-VSCodeExtension -ExtensionId "pub.ext" -StatePath $fakeStatePath -AutomaticDir $fakeAutomaticDir -TemplatesDir $fakeTemplatesDir } | Should -Throw "Marketplace Outage"
            Should -Invoke -CommandName Write-Err -ModuleName ChocoVSCodeExtensionManager -Times 1
        }
    }

    Context "Directory Regeneration and Output Pipes" {
        It "should skip regeneration and return early if the package directory exists and -Force is NOT passed (Line 106)" {
            Mock Write-Skip -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-StyledMessage -ModuleName ChocoVSCodeExtensionManager {}
            Mock Get-VsCodeMarketplaceMetadata -ModuleName ChocoVSCodeExtensionManager {}

            $fakeAutomaticDir = Join-Path $TestDrive "auto_skip"
            New-Item -ItemType Directory -Path $fakeAutomaticDir -Force | Out-Null

            $pkgDir = Join-Path $fakeAutomaticDir "vscode-skip"
            New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null

            $fakeStatePath = Join-Path $TestDrive "state.json"

            Add-VSCodeExtension -ExtensionId "pub.skip" -StatePath $fakeStatePath -AutomaticDir $fakeAutomaticDir -TemplatesDir $fakeTemplatesDir

            Should -Invoke -CommandName Write-Skip -ModuleName ChocoVSCodeExtensionManager -ParameterFilter { $Message -match "Package folder already exists" }
            Should -Invoke -CommandName Get-VsCodeMarketplaceMetadata -ModuleName ChocoVSCodeExtensionManager -Times 0
        }

        It "should aggressively remove and regenerate the package directory if -Force is passed (Lines 101-106)" {
            Mock Write-Info -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Success -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-StyledMessage -ModuleName ChocoVSCodeExtensionManager {}
            Mock Get-VsCodeMarketplaceMetadata -ModuleName ChocoVSCodeExtensionManager -MockWith { return $script:fakeExtMeta }
            Mock Get-VsCodeExtensionUrl -ModuleName ChocoVSCodeExtensionManager -MockWith { return "http://fake.url" }

            Mock Invoke-RobustDownload -ModuleName ChocoVSCodeExtensionManager -MockWith {
                $vdir = Split-Path $OutFile
                if (-not (Test-Path $vdir)) { New-Item -ItemType Directory -Path $vdir -Force | Out-Null }
                New-Item -ItemType File -Path $OutFile -Force | Out-Null
            }

            Mock Expand-VsCodePayload -ModuleName ChocoVSCodeExtensionManager -MockWith { return @{ CDataSafeReadme = "<![CDATA[readme]]>"; PackageJson = @{} } }
            Mock Save-VsCodeIcon -ModuleName ChocoVSCodeExtensionManager {}
            Mock New-VerificationFile -ModuleName ChocoVSCodeExtensionManager {}
            Mock Get-VsCodeNuspecMetadata -ModuleName ChocoVSCodeExtensionManager -MockWith { return @{} }
            Mock Update-VsCodeNuspecMetadata -ModuleName ChocoVSCodeExtensionManager -MockWith { return $script:xmlTemplate }
            Mock Update-NuspecCDataDescription -ModuleName ChocoVSCodeExtensionManager {}
            Mock Update-NuspecDependency -ModuleName ChocoVSCodeExtensionManager -MockWith { return @() }
            Mock Save-NuspecXml -ModuleName ChocoVSCodeExtensionManager {}

            $fakeAutomaticDir = Join-Path $TestDrive "auto_force"
            New-Item -ItemType Directory -Path $fakeAutomaticDir -Force | Out-Null

            $pkgDir = Join-Path $fakeAutomaticDir "vscode-force"
            New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null
            $dummyFile = Join-Path $pkgDir "old.txt"
            Set-Content -Path $dummyFile -Value "OLD"

            $fakeStatePath = Join-Path $TestDrive "state.json"

            Add-VSCodeExtension -ExtensionId "pub.force" -StatePath $fakeStatePath -AutomaticDir $fakeAutomaticDir -TemplatesDir $fakeTemplatesDir -Force

            Test-Path $dummyFile | Should -Be $false
            Should -Invoke -CommandName Write-Info -ModuleName ChocoVSCodeExtensionManager -ParameterFilter { $Message -match "-Force is set" }
        }
    }

    Context "Security Scanning and Dependency Output" {
        It "should scan the VSIX for network triggers and output deduplicated missing dependencies (Lines 178, 203-206, 246)" {
            Mock Write-Info -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Success -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Warn -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-StyledMessage -ModuleName ChocoVSCodeExtensionManager {}
            Mock Get-VsCodeMarketplaceMetadata -ModuleName ChocoVSCodeExtensionManager -MockWith { return $script:fakeExtMeta }
            Mock Get-VsCodeExtensionUrl -ModuleName ChocoVSCodeExtensionManager -MockWith { return "http://fake.url" }

            Mock Invoke-RobustDownload -ModuleName ChocoVSCodeExtensionManager -MockWith {
                $vdir = Split-Path $OutFile
                if (-not (Test-Path $vdir)) { New-Item -ItemType Directory -Path $vdir -Force | Out-Null }
                Set-Content -Path $OutFile -Value "Some binary junk then npm install more junk"
            }

            Mock Expand-VsCodePayload -ModuleName ChocoVSCodeExtensionManager -MockWith { return @{ CDataSafeReadme = "<![CDATA[readme]]>"; PackageJson = @{} } }
            Mock Save-VsCodeIcon -ModuleName ChocoVSCodeExtensionManager {}
            Mock New-VerificationFile -ModuleName ChocoVSCodeExtensionManager {}
            Mock Get-VsCodeNuspecMetadata -ModuleName ChocoVSCodeExtensionManager -MockWith { return @{} }
            Mock Update-VsCodeNuspecMetadata -ModuleName ChocoVSCodeExtensionManager -MockWith { return $script:xmlTemplate }
            Mock Update-NuspecCDataDescription -ModuleName ChocoVSCodeExtensionManager {}
            Mock Update-NuspecDependency -ModuleName ChocoVSCodeExtensionManager -MockWith { return @("Pub.Dep1", "Pub.Dep2", "pub.dep1") }
            Mock Save-NuspecXml -ModuleName ChocoVSCodeExtensionManager {}

            $fakeAutomaticDir = Join-Path $TestDrive "auto_scan"
            $fakeStatePath = Join-Path $TestDrive "state.json"

            $output = Add-VSCodeExtension -ExtensionId "pub.sec" -StatePath $fakeStatePath -AutomaticDir $fakeAutomaticDir -TemplatesDir $fakeTemplatesDir

            Should -Invoke -CommandName Write-Warn -ModuleName ChocoVSCodeExtensionManager -ParameterFilter { $Message -match "network triggers found" }

            $output.Count | Should -Be 2
            $output[0] | Should -Be "pub.dep1"
            $output[1] | Should -Be "pub.dep2"
        }
    }
}
