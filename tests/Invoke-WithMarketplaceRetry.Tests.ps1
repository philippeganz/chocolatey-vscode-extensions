BeforeAll {
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeCore\ChocoVSCodeCore.psd1 -Force
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeMarketplace\ChocoVSCodeMarketplace.psd1 -Force
}

Describe "Invoke-WithMarketplaceRetry" {
    Context "Successful Route" {
        It "should execute the joyful output by returning the block output on the first try" {
            $action = { return "success_payload" }

            $res = Invoke-WithMarketplaceRetry -Action $action -ErrorMessage "Failed"

            $res | Should -Be "success_payload"
        }
    }
}
