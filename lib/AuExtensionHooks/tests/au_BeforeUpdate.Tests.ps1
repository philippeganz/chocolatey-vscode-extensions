#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force
    Import-Module ChocoVSCodeExtensionManager -Force
    Import-Module AuExtensionHooks -Force
}

Describe "au_BeforeUpdate" {
    BeforeEach {
        Set-Variable -Name "ExtensionPublisher" -Value "ms-python" -Scope Global
        Set-Variable -Name "ExtensionName" -Value "python" -Scope Global

        Set-Variable -Name "Latest" -Scope Global -Value @{
            Version            = "1.0.0"
            URL64              = "http://fake.url"
            RawMeta            = @{ shortDescription = "desc" }
            MarketplaceIconUrl = "http://fake.icon"
        }

        $script:fakePkgPath = Join-Path $TestDrive "vscode-python"
        New-Item -ItemType Directory -Path $script:fakePkgPath -Force | Out-Null

        $script:xml = "<?xml version='1.0'?><package></package>"
        Set-Content -Path (Join-Path $script:fakePkgPath "vscode-python.nuspec") -Value $script:xml -Encoding UTF8

        $script:fakePackage = [PSCustomObject]@{
            Path      = $script:fakePkgPath
            Name      = "vscode-python"
            NuspecXml = $null
        }
    }

    Context "Successful Update Route" {
        It "should successfully download the payload, scaffold the XML, and backup the README (Line 121)" {
            # Mock the core components so AU just passes through smoothly
            Mock Get-ChildItem -ModuleName AuExtensionHooks -MockWith { return @() }
            Mock Remove-Item -ModuleName AuExtensionHooks {}
            Mock Invoke-RobustDownload -ModuleName AuExtensionHooks {}
            Mock New-VerificationFile -ModuleName AuExtensionHooks {}
            Mock Expand-VsCodePayload -ModuleName AuExtensionHooks -MockWith { return @{ CDataSafeReadme = "<![CDATA[readme]]>"; PackageJson = @{} } }
            Mock Get-VsCodeNuspecMetadata -ModuleName AuExtensionHooks -MockWith { return @{} }
            Mock Update-VsCodeNuspecMetadata -ModuleName AuExtensionHooks -MockWith { return $script:xml }
            Mock Update-NuspecCDataDescription -ModuleName AuExtensionHooks {}

            # Simulate no missing dependencies
            Mock Update-NuspecDependency -ModuleName AuExtensionHooks -MockWith { return $null }
            Mock Save-NuspecXml -ModuleName AuExtensionHooks {}
            Mock Save-VsCodeIcon -ModuleName AuExtensionHooks {}

            # Create a dummy README to trigger line 121
            $readmePath = Join-Path $script:fakePkgPath "README.md"
            Set-Content -Path $readmePath -Value "hello"

            # Execute Hook
            au_BeforeUpdate -package $script:fakePackage

            # Assert README was moved (Line 121)
            Test-Path $readmePath | Should -Be $false
            Test-Path (Join-Path $script:fakePkgPath "README.md.bak") | Should -Be $true

            # Assert Nuspec XML object was saved on the package context
            $script:fakePackage.NuspecXml | Should -Not -BeNullOrEmpty
        }
    }

    Context "DAG Integrity Protection" {
        It "should spawn Orchestrator and throw if missing dependencies are discovered (Lines 85, 101-105)" {
            Mock Get-ChildItem -ModuleName AuExtensionHooks -MockWith { return @() }
            Mock Remove-Item -ModuleName AuExtensionHooks {}
            Mock Invoke-RobustDownload -ModuleName AuExtensionHooks {}
            Mock New-VerificationFile -ModuleName AuExtensionHooks {}
            Mock Expand-VsCodePayload -ModuleName AuExtensionHooks -MockWith { return @{ CDataSafeReadme = "<![CDATA[readme]]>"; PackageJson = @{} } }
            Mock Get-VsCodeNuspecMetadata -ModuleName AuExtensionHooks -MockWith { return @{} }
            Mock Update-VsCodeNuspecMetadata -ModuleName AuExtensionHooks -MockWith { return $script:xml }
            Mock Update-NuspecCDataDescription -ModuleName AuExtensionHooks {}

            # Force discovery of missing dependencies!
            Mock Update-NuspecDependency -ModuleName AuExtensionHooks -MockWith { return @("ms-tools.tool1") }
            Mock Write-StyledMessage -ModuleName AuExtensionHooks {}
            Mock Write-Info -ModuleName AuExtensionHooks {}

            # Prevent pwsh from actually executing
            Mock Start-Process -ModuleName AuExtensionHooks {}

            # Execution should be violently terminated by InvalidOperationException
            { au_BeforeUpdate -package $script:fakePackage } | Should -Throw -ExceptionType System.InvalidOperationException

            # Assert Start-Process was called to invoke the Orchestrator
            Should -Invoke -CommandName Start-Process -ModuleName AuExtensionHooks -Times 1 -ParameterFilter { $ArgumentList -match "ms-tools.tool1" }
            Should -Invoke -CommandName Write-StyledMessage -ModuleName AuExtensionHooks -ParameterFilter { $Message -match "Missing dependencies detected" }
        }
    }
}
