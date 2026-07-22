$ErrorActionPreference = 'Stop'

Describe "CoreHelpers Module" -Tag "Unit", 'CoreHelpers' {
    BeforeAll {
        $script:modulePath = Join-Path $PSScriptRoot "..\lib\CoreHelpers.psm1"
        Import-Module $script:modulePath -Force
    }

    Context "Write-StyledMessage" {
        It "should unconditionally use ANSI styling via `$PSStyle" {
            Mock Write-Host {} -ModuleName CoreHelpers

            Write-StyledMessage -Prefix "[TEST]" -Message "Test message" -Color Cyan

            Should -Invoke -CommandName Write-Host -ModuleName CoreHelpers -Times 1 -ParameterFilter {
                $Object -match '\[TEST\]' -and $Object -match 'Test message'
            }
        }

        It "should omit the prefix space when Prefix is empty" {
            Mock Write-Host {} -ModuleName CoreHelpers

            Write-StyledMessage -Message "Bare message" -Color Magenta

            Should -Invoke -CommandName Write-Host -ModuleName CoreHelpers -Times 1 -ParameterFilter {
                $Object -match 'Bare message'
            }
        }
    }

    Context "Helper Wrapper Functions" {
        BeforeEach {
            Mock Write-StyledMessage {} -ModuleName CoreHelpers
        }

        It "Write-Success passes correct parameters" {
            Write-Success "All good"
            Should -Invoke -CommandName Write-StyledMessage -ModuleName CoreHelpers -Times 1 -ParameterFilter {
                $Prefix -eq '[SUCCESS]' -and $Message -eq 'All good' -and $Color -eq 'Green'
            }
        }

        It "Write-Info passes correct parameters" {
            Write-Info "Some info"
            Should -Invoke -CommandName Write-StyledMessage -ModuleName CoreHelpers -Times 1 -ParameterFilter {
                $Prefix -eq '[INFO]' -and $Message -eq 'Some info' -and $Color -eq 'Cyan'
            }
        }

        It "Write-Skip passes correct parameters" {
            Write-Skip "Skipping"
            Should -Invoke -CommandName Write-StyledMessage -ModuleName CoreHelpers -Times 1 -ParameterFilter {
                $Prefix -eq '[SKIP]' -and $Message -eq 'Skipping' -and $Color -eq 'Yellow'
            }
        }

        It "Write-Err passes correct parameters" {
            Write-Err "Failed"
            Should -Invoke -CommandName Write-StyledMessage -ModuleName CoreHelpers -Times 1 -ParameterFilter {
                $Prefix -eq '[ERROR]' -and $Message -eq 'Failed' -and $Color -eq 'Red'
            }
        }

        It "Write-Red passes correct parameters" {
            Write-Red "Red message"
            Should -Invoke -CommandName Write-StyledMessage -ModuleName CoreHelpers -Times 1 -ParameterFilter {
                (-not $PSBoundParameters.ContainsKey('Prefix')) -and $Message -eq 'Red message' -and $Color -eq 'Red'
            }
        }

        It "Write-Cyan passes correct parameters" {
            Write-Cyan "Cyan message"
            Should -Invoke -CommandName Write-StyledMessage -ModuleName CoreHelpers -Times 1 -ParameterFilter {
                (-not $PSBoundParameters.ContainsKey('Prefix')) -and $Message -eq 'Cyan message' -and $Color -eq 'Cyan'
            }
        }

        It "Write-Yellow passes correct parameters" {
            Write-Yellow "Yellow message"
            Should -Invoke -CommandName Write-StyledMessage -ModuleName CoreHelpers -Times 1 -ParameterFilter {
                (-not $PSBoundParameters.ContainsKey('Prefix')) -and $Message -eq 'Yellow message' -and $Color -eq 'Yellow'
            }
        }

        It "Write-Green passes correct parameters" {
            Write-Green "Green message"
            Should -Invoke -CommandName Write-StyledMessage -ModuleName CoreHelpers -Times 1 -ParameterFilter {
                (-not $PSBoundParameters.ContainsKey('Prefix')) -and $Message -eq 'Green message' -and $Color -eq 'Green'
            }
        }

        It "Write-Gray passes correct parameters" {
            Write-Gray "Gray message"
            Should -Invoke -CommandName Write-StyledMessage -ModuleName CoreHelpers -Times 1 -ParameterFilter {
                (-not $PSBoundParameters.ContainsKey('Prefix')) -and $Message -eq 'Gray message' -and $Color -eq 'Gray'
            }
        }

        It "Write-Magenta passes correct parameters" {
            Write-Magenta "Magenta message"
            Should -Invoke -CommandName Write-StyledMessage -ModuleName CoreHelpers -Times 1 -ParameterFilter {
                (-not $PSBoundParameters.ContainsKey('Prefix')) -and $Message -eq 'Magenta message' -and $Color -eq 'Magenta'
            }
        }

        It "Write-White passes correct parameters" {
            Write-White "White message"
            Should -Invoke -CommandName Write-StyledMessage -ModuleName CoreHelpers -Times 1 -ParameterFilter {
                (-not $PSBoundParameters.ContainsKey('Prefix')) -and $Message -eq 'White message' -and $Color -eq 'White'
            }
        }
    }
}
