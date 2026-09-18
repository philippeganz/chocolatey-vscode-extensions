#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force
}

Describe "Invoke-WithMarketplaceRetry" {
    Context "Successful Route" {
        It "should execute the joyful output by returning the block output on the first try" {
            $action = { return "success_payload" }
            $res = Invoke-WithMarketplaceRetry -Action $action -ErrorMessage "Failed"
            $res | Should -Be "success_payload"
        }
    }

    Context "Error Handling and Retry Logic" {
        It "should abort immediately without retrying on 404 (Line 68-71)" {
            Mock Start-Sleep -ModuleName ChocoVSCodeMarketplace {}
            $action = { throw [System.Exception]::new("404 Not Found") }

            { Invoke-WithMarketplaceRetry -Action $action } | Should -Throw "404 Not Found"
            Should -Invoke -CommandName Start-Sleep -ModuleName ChocoVSCodeMarketplace -Times 0
        }

        It "should retry on transient errors and exponentially backoff (Lines 83-86)" {
            Mock Start-Sleep -ModuleName ChocoVSCodeMarketplace {}
            Mock Write-Warn -ModuleName ChocoVSCodeMarketplace {}

            # Use a closure variable to simulate a stateful endpoint
            $script:attempts = 0
            $action = {
                $script:attempts++
                if ($script:attempts -eq 1) {
                    throw [System.Exception]::new("503 Service Unavailable")
                }
                return "finally_success"
            }

            $res = Invoke-WithMarketplaceRetry -Action $action
            $res | Should -Be "finally_success"
            Should -Invoke -CommandName Start-Sleep -ModuleName ChocoVSCodeMarketplace -Times 1 -ParameterFilter { $Seconds -eq 2 }
        }

        It "should exhaust max retries on a throttling error and throw MarketplaceThrottlingError (Lines 74-79)" {
            Mock Start-Sleep -ModuleName ChocoVSCodeMarketplace {}
            Mock Write-Warn -ModuleName ChocoVSCodeMarketplace {}
            Mock Write-Err -ModuleName ChocoVSCodeMarketplace {}

            $action = { throw [System.Exception]::new("429 Too Many Requests") }

            # Default is 3 retries (4 attempts total)
            { Invoke-WithMarketplaceRetry -Action $action -MaxRetries 3 } | Should -Throw "*MarketplaceThrottlingError*"

            Should -Invoke -CommandName Start-Sleep -ModuleName ChocoVSCodeMarketplace -Times 3
            Should -Invoke -CommandName Start-Sleep -ModuleName ChocoVSCodeMarketplace -ParameterFilter { $Seconds -eq 2 }
            Should -Invoke -CommandName Start-Sleep -ModuleName ChocoVSCodeMarketplace -ParameterFilter { $Seconds -eq 4 }
            Should -Invoke -CommandName Start-Sleep -ModuleName ChocoVSCodeMarketplace -ParameterFilter { $Seconds -eq 8 }
        }

        It "should exhaust max retries on a standard error and rethrow the original error (Lines 74-76, 80)" {
            Mock Start-Sleep -ModuleName ChocoVSCodeMarketplace {}
            Mock Write-Warn -ModuleName ChocoVSCodeMarketplace {}
            Mock Write-Err -ModuleName ChocoVSCodeMarketplace {}

            $action = { throw [System.Exception]::new("TCP Connection Reset") }

            { Invoke-WithMarketplaceRetry -Action $action -MaxRetries 2 } | Should -Throw "TCP Connection Reset"

            Should -Invoke -CommandName Start-Sleep -ModuleName ChocoVSCodeMarketplace -Times 2
        }
    }
}
