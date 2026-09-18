#Requires -Version 7.0
BeforeAll {
    $script:originalPSModulePath = $env:PSModulePath
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }
    Import-Module ChocoVSCodeExtensionManager -Force
}
AfterAll {
    $env:PSModulePath = $script:originalPSModulePath
}

Describe "Get-ChocolateyPackageMetadata" {
    Context "Successful XML Scraping" {
        It "should cleanly regex match all properties from the OData feed" {
            Mock Invoke-WebRequest {
                $xml = "<entry><d:Owners>philippe.ganz</d:Owners><d:Version>1.2.3</d:Version><d:Published>2026-01-01T12:00:00Z</d:Published></entry>"
                return [PSCustomObject]@{ Content = $xml }
            } -ModuleName ChocoVSCodeExtensionManager

            $meta = Get-ChocolateyPackageMetadata -PackageName "vscode-test"
            $meta.Owners | Should -Be "philippe.ganz"
            $meta.RemoteVersion | Should -Be "1.2.3"
            $meta.Published.Year | Should -Be 2026
            Should -Invoke -CommandName Invoke-WebRequest -Times 1 -ModuleName ChocoVSCodeExtensionManager
        }

        It "should gracefully return null for empty content" {
            Mock Invoke-WebRequest { return [PSCustomObject]@{ Content = $null } } -ModuleName ChocoVSCodeExtensionManager
            $meta = Get-ChocolateyPackageMetadata -PackageName "vscode-empty"
            $meta | Should -BeNullOrEmpty
        }
    }

    Context "OData API HTTP Exception Handling" {
        It "should safely return null and bypass execution when the feed returns a 404 Not Found exception (Line 54)" {
            Mock Invoke-WebRequest {
                $response = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::NotFound)
                $ex = [Microsoft.PowerShell.Commands.HttpResponseException]::new("404 Error", $response)
                throw $ex
            } -ModuleName ChocoVSCodeExtensionManager

            $meta = Get-ChocolateyPackageMetadata -PackageName "vscode-404"
            $meta | Should -BeNullOrEmpty
        }

        It "should forcefully throw the exception and crash if the API returns a generalized non-404 error (Line 55)" {
            Mock Invoke-WebRequest {
                $response = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::InternalServerError)
                $ex = [Microsoft.PowerShell.Commands.HttpResponseException]::new("500 Error", $response)
                throw $ex
            } -ModuleName ChocoVSCodeExtensionManager

            { Get-ChocolateyPackageMetadata -PackageName "vscode-500" } | Should -Throw "500 Error"
        }
    }
}
