BeforeAll {
    $modulePath = Resolve-Path "$PSScriptRoot\..\lib\ConfigHelpers.psm1"
    Import-Module $modulePath.Path -Force
    function Write-Success {}
}

Describe 'ConfigHelpers' {
    Context 'Get-ConfigState' {
        It 'throws if config.yaml does not exist' {
            Mock Test-Path { return $false } -ModuleName ConfigHelpers
            { Get-ConfigState -ConfigPath 'fake.yaml' } | Should -Throw 'config.yaml not found at fake.yaml'
        }

        It 'parses YAML and returns raw object and extensions list' {
            Mock Test-Path { return $true } -ModuleName ConfigHelpers
            Mock Get-Content { return "extensions:`n  - publisher.ext1`n  - pub.ext2" } -ModuleName ConfigHelpers
            Mock ConvertFrom-Yaml { return @{ extensions = @('publisher.ext1', 'pub.ext2') } } -ModuleName ConfigHelpers

            $result = Get-ConfigState -ConfigPath 'fake.yaml'

            $result.Extensions.Count | Should -Be 2
            $result.Extensions[0] | Should -Be 'publisher.ext1'
            $result.Extensions[1] | Should -Be 'pub.ext2'
            $result.Raw.extensions.Count | Should -Be 2
        }
    }

    Context 'Save-ConfigState' {
        BeforeAll {
            $m = Get-Module ConfigHelpers
            & $m {
                function ConvertTo-Yaml { return "extensions:`n  - a.ext`n  - z.ext" }
                function ConvertTo-Json { return "{}" }
            }
        }
        It 'sorts extensions, saves to YAML and generates a badge' {
            Mock Set-Content {}
            Mock Set-Content {} -ModuleName ConfigHelpers
            Mock Write-Success {}
            Mock Write-Success {} -ModuleName ConfigHelpers
            Mock Split-Path { return 'C:\fake' }
            Mock Split-Path { return 'C:\fake' } -ModuleName ConfigHelpers
            Mock Join-Path { return 'C:\fake\badge.json' }
            Mock Join-Path { return 'C:\fake\badge.json' } -ModuleName ConfigHelpers

            $extensions = @('z.ext', 'a.ext', 'a.ext')
            Save-ConfigState -ConfigPath 'C:\fake\config.yaml' -ExtensionsList $extensions

            Assert-MockCalled Set-Content -ModuleName ConfigHelpers -Times 2 -Exactly
            Assert-MockCalled Write-Success -ModuleName ConfigHelpers -Times 1 -Exactly
        }
    }

    Context 'Get-ChocoPackageName' {
        It 'returns empty string when extension ID is null or empty' {
            Get-ChocoPackageName -ExtensionId '' | Should -BeNullOrEmpty
        }

        It 'prepends vscode- and uses the second part of the ID' {
            Get-ChocoPackageName -ExtensionId 'publisher.some-extension' | Should -Be 'vscode-some-extension'
        }

        It 'handles IDs without a dot correctly' {
            Get-ChocoPackageName -ExtensionId 'some-extension' | Should -Be 'vscode-some-extension'
        }

        It 'does not prepend vscode- if it already starts with vscode-' {
            Get-ChocoPackageName -ExtensionId 'publisher.vscode-extension' | Should -Be 'vscode-extension'
        }

        It 'converts everything to lowercase' {
            Get-ChocoPackageName -ExtensionId 'Publisher.Some-Extension' | Should -Be 'vscode-some-extension'
        }
    }

    Context 'Get-AutomaticDirectory' {
        BeforeEach {
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = $null
        }

        It 'returns directory from environment variable if set' {
            $env:CHOCO_VSCODE_AUTOMATIC_DIR = 'C:\Env\Automatic'
            Get-AutomaticDirectory | Should -Be 'C:\Env\Automatic'
        }

        It 'returns resolved path if environment variable is not set' {
            Mock Resolve-Path { return [PSCustomObject]@{ Path = 'C:\Resolved\Automatic' } } -ModuleName ConfigHelpers
            Get-AutomaticDirectory | Should -Be 'C:\Resolved\Automatic'
        }

        It 'returns fallback path if Resolve-Path fails' {
            Mock Resolve-Path { return $null } -ModuleName ConfigHelpers
            $fallback = Get-AutomaticDirectory
            $fallback | Should -Match 'automatic$'
        }
    }
}
