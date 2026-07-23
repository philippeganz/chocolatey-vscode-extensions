#Requires -Version 7.0
#Requires -Module @{ModuleName='Pester'; ModuleVersion='6.0.0'}
BeforeAll {
    Import-Module "$PSScriptRoot\..\lib\ConfigHelpers.psm1" -Force
    function Write-Success {}
}

Describe 'ConfigHelpers' -Tag "Unit", 'ConfigHelpers' {
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

        It 'handles config.yaml with no extensions cleanly' {
            Mock Test-Path { return $true } -ModuleName ConfigHelpers
            Mock Get-Content { return "---`nfoo: bar" } -ModuleName ConfigHelpers
            Mock ConvertFrom-Yaml { return @{ foo = 'bar' } } -ModuleName ConfigHelpers

            $result = Get-ConfigState -ConfigPath 'fake.yaml'

            $result.Extensions.Count | Should -Be 0
        }
    }

    Context 'Save-ConfigState' {
        It 'sorts extensions and saves to YAML' {
            Mock Write-Success {} -ModuleName ConfigHelpers
            Mock ConvertTo-Yaml { return "extensions:`n  - a.ext`n  - z.ext" }

            $extensions = @('z.ext', 'a.ext', 'a.ext')
            Save-ConfigState -ConfigPath "$TestDrive\config.yaml" -ExtensionsList $extensions

            Should -Invoke -CommandName Write-Success -ModuleName ConfigHelpers -Times 1 -Exactly
            Test-Path "$TestDrive\config.yaml" | Should -Be $true
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

        It 'returns absolute path to automatic directory if environment variable is not set' {
            $fallback = Get-AutomaticDirectory
            $fallback | Should -Match 'automatic$'
            [System.IO.Path]::IsPathRooted($fallback) | Should -Be $true
        }
    }
}
