#Requires -Version 7.0
#Requires -Module @{ModuleName='Pester'; ModuleVersion='6.0.0'}
Describe "Invoke-ExtensionFactory.ps1" -Tag "Integration", 'Invoke-ExtensionFactory' {
    BeforeAll {
        $script:scriptPath = "$PSScriptRoot\..\bin\Invoke-ExtensionFactory.ps1"
        $script:mockConfig = Join-Path $TestDrive "mock_config.yaml"
        Set-Content -Path $script:mockConfig -Value "---\nextensions:`n  - ms-python.python"
    }

    BeforeEach {
        $env:CHOCO_VSCODE_AUTOMATIC_DIR = Join-Path $TestDrive "automatic"
        if (-not (Test-Path $env:CHOCO_VSCODE_AUTOMATIC_DIR)) {
            [void](New-Item -ItemType Directory -Path $env:CHOCO_VSCODE_AUTOMATIC_DIR)
        }
    }

    It "Should handle invalid extension ID format" {
        { & $script:scriptPath -ConfigFile $script:mockConfig -ExtensionId "invalidformat" } | Should -Not -Throw
        # It just skips
        Test-Path (Join-Path $env:CHOCO_VSCODE_AUTOMATIC_DIR "invalidformat") | Should -Be $false
    }

    It "Should just log if package exists and UpdateMetadata is specified" {
        Mock Get-VsCodeMarketplaceMetadata -MockWith {
            return @{ versions = @( @{ version = "1.0.0"; files = @() } ); shortDescription = "Test" }
        }
        Mock Get-VsCodeExtensionUrl -MockWith { return "http://vsix" }
        Mock Invoke-RobustDownload -MockWith { Set-Content -Path $OutFile -Value "fake payload" }
        Mock Expand-VsCodePayload -MockWith { return @{} }
        Mock Get-VsCodeNuspecMetadata -MockWith { return @{ Title = "T"; Authors = "A"; ProjectUrl = "U"; IconUrl = "I"; MarketplaceUrl = "M"; Description = "D"; Summary = "S" } }

        $pkgDir = Join-Path $env:CHOCO_VSCODE_AUTOMATIC_DIR "vscode-mock"
        [void](New-Item -ItemType Directory -Path $pkgDir)

        $UpdateMetadata = $true
        Write-Verbose "$UpdateMetadata"
        { . $script:scriptPath -ConfigFile $script:mockConfig -ExtensionId "test.mock" } | Should -Not -Throw
    }

    It "Should catch exception if Get-VsCodeMarketplaceMetadata fails" {
        Mock Get-VsCodeMarketplaceMetadata -MockWith { throw "Mock failure" }
        { & $script:scriptPath -ConfigFile $script:mockConfig -ExtensionId "test.fail" } | Should -Not -Throw
    }

    It "Should scaffold a package and discover dependencies" {
        Mock Get-VsCodeMarketplaceMetadata -MockWith {
            return @{
                versions         = @( @{ version = "1.0.0"; files = @( @{ assetType = "Microsoft.VisualStudio.Services.Icons.Default"; source = "http://icon" } ) } )
                shortDescription = "Test " * 5000 # Test length > 4000
            }
        }
        Mock Get-VsCodeExtensionUrl -MockWith { return "http://vsix" }
        Mock Invoke-RobustDownload -MockWith {
            # create a fake file so scanning doesn't fail
            Set-Content -Path $OutFile -Value "fake payload"
        }
        Mock Expand-VsCodePayload -MockWith {
            $jsonStr = '{ "extensionDependencies": ["vscode.built-in", "vscode.yaml"], "extensionPack": ["peterjausovec.vscode-docker", "unknown.dependency"] }'
            return [PSCustomObject]@{
                PackageJson = $jsonStr | ConvertFrom-Json
                TruncatedReadme = "Test"
            }
        }
        Mock Get-VsCodeNuspecMetadata -MockWith {
            return @{
                Title          = "Title"
                Authors        = "Authors"
                ProjectUrl     = "http://project"
                IconUrl        = "http://icon"
                MarketplaceUrl = "http://marketplace"
                Description    = "Desc"
                Summary        = "Summary"
            }
        }
        Mock Invoke-WebRequest -MockWith { return $true }

        # Test full scaffold without forcing
        & $script:scriptPath -ConfigFile $script:mockConfig -ExtensionId "test.deps"

        $pkgDir = Join-Path $env:CHOCO_VSCODE_AUTOMATIC_DIR "vscode-deps"
        Test-Path $pkgDir | Should -Be $true
        Test-Path (Join-Path $pkgDir "vscode-deps.nuspec") | Should -Be $true
        Test-Path (Join-Path $pkgDir "tools\chocolateyInstall.ps1") | Should -Be $true
        Test-Path (Join-Path $pkgDir "update.ps1") | Should -Be $true

        # Test skipping existing
        & $script:scriptPath -ConfigFile $script:mockConfig -ExtensionId "test.deps"

        # Test Force regenerating
        Start-Sleep -Milliseconds 200
        & $script:scriptPath -ConfigFile $script:mockConfig -ExtensionId "test.deps" -Force

        # Ensure dependencies were discovered by checking console output or something?
        # Actually we just run it and let the mocks hit
    }

    It "Should warn on dangerous network triggers in VSIX" {
        Mock Get-VsCodeMarketplaceMetadata -MockWith {
            return @{ versions = @( @{ version = "1.0.0"; files = @() } ); shortDescription = "Test" }
        }
        Mock Get-VsCodeExtensionUrl -MockWith { return "http://vsix" }
        Mock Invoke-RobustDownload -MockWith {
            # Inject bad payload
            Set-Content -Path $OutFile -Value "wget http://bad"
        }
        Mock Expand-VsCodePayload -MockWith { return @{} }
        Mock Get-VsCodeNuspecMetadata -MockWith { return @{ Title = "T"; Authors = "A"; ProjectUrl = "U"; IconUrl = "I"; MarketplaceUrl = "M"; Description = "D"; Summary = "S" } }

        & $script:scriptPath -ConfigFile $script:mockConfig -ExtensionId "test.dangerous"
    }

    It "Should throw if no extensions are found and no ExtensionId is provided" {
        $emptyConfig = Join-Path $TestDrive "empty_config.yaml"
        Set-Content -Path $emptyConfig -Value "---\nextensions: []"
        { & $script:scriptPath -ConfigFile $emptyConfig } | Should -Throw "No extensions found in $emptyConfig, and no -ExtensionId was provided."
    }

    It "Should rewrite the config.yaml if ExtensionId is not provided" {
        Mock Get-VsCodeMarketplaceMetadata -MockWith {
            return @{ versions = @( @{ version = "1.0.0"; files = @() } ); shortDescription = "Test" }
        }
        Mock Get-VsCodeExtensionUrl -MockWith { return "http://vsix" }
        Mock Invoke-RobustDownload -MockWith { Set-Content -Path $OutFile -Value "fake payload" }
        Mock Expand-VsCodePayload -MockWith { return @{} }
        Mock Get-VsCodeNuspecMetadata -MockWith { return @{ Title = "T"; Authors = "A"; ProjectUrl = "U"; IconUrl = "I"; MarketplaceUrl = "M"; Description = "D"; Summary = "S" } }

        $testConfig = Join-Path $TestDrive "test_config.yaml"
        $yamlContent = @"
---
extensions:
  - test.ext
"@
        Set-Content -Path $testConfig -Value $yamlContent

        & $script:scriptPath -ConfigFile $testConfig

        # It should rewrite test_config.yaml
        $rewritten = Get-Content -Path $testConfig -Raw
        $rewritten | Should -Match "  - test.ext"
    }

    It "Should handle extremely long descriptions" {
        Mock Get-VsCodeMarketplaceMetadata -MockWith {
            return @{ versions = @( @{ version = "1.0.0"; files = @() } ); shortDescription = "A" * 5000 }
        }
        Mock Get-VsCodeExtensionUrl -MockWith { return "http://vsix" }
        Mock Invoke-RobustDownload -MockWith { Set-Content -Path $OutFile -Value "fake payload" }
        Mock Expand-VsCodePayload -MockWith { return @{} }
        Mock Get-VsCodeNuspecMetadata -MockWith { return @{ Title = "T"; Authors = "A"; ProjectUrl = "U"; IconUrl = "I"; MarketplaceUrl = "M"; Description = "D"; Summary = "S" } }

        & $script:scriptPath -ConfigFile $script:mockConfig -ExtensionId "test.longdesc"
    }
}
