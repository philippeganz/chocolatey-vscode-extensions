#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    $testDir = Join-Path $TestDrive "CoreHelpersTest"
    New-Item -ItemType Directory -Path $testDir | Out-Null
    $script:statePath = Join-Path $testDir "extensions.json"
}

Describe "Get-ChocoVSCodePackageName" {
    Context "Successful Route" {
        It "should extract the extension name and prepend vscode-" {
            $result = Get-ChocoVSCodePackageName -ExtensionId "ms-python.python"
            $result | Should -Be "vscode-python"
        }
    }
}

Describe "Get-ChocoVSCodeExtensionState" {
    Context "Successful Route" {
        It "should parse the flat JSON array and return string array" {
            $json = '["ms-python.python", "eamodio.gitlens"]'
            Set-Content -Path $script:statePath -Value $json -Encoding UTF8

            $result = Get-ChocoVSCodeExtensionState -StatePath $script:statePath

            $result.Count | Should -Be 2
            $result[0] | Should -Be "ms-python.python"
            $result[1] | Should -Be "eamodio.gitlens"
        }
    }

    Context "File Not Found Route" {
        It "should throw FileNotFoundException if the state file does not exist (Lines 78-79)" {
            $missingPath = Join-Path $TestDrive "does_not_exist.json"
            { Get-ChocoVSCodeExtensionState -StatePath $missingPath } | Should -Throw "*not found at*"
        }
    }
}

Describe "Save-ChocoVSCodeExtensionState" {
    Context "Successful Route" {
        It "should sort, deduplicate, and write extensions to JSON array" {
            $extList = @("ms-python.python", "z-author.extension", "a-author.extension", "ms-python.python")

            Mock Write-Success -ModuleName ChocoVSCodeCore {}
            Save-ChocoVSCodeExtensionState -StatePath $script:statePath -ExtensionsList $extList

            $content = Get-Content $script:statePath -Raw
            $content -match "a-author\.extension" | Should -Be $true
            $content -match "z-author\.extension" | Should -Be $true
            $content.IndexOf("a-author") -lt $content.IndexOf("ms-python") | Should -Be $true
            $content.IndexOf("ms-python") -lt $content.IndexOf("z-author") | Should -Be $true

            $matchResult = [regex]::Matches($content, "ms-python\.python")
            $matchResult.Count | Should -Be 1
        }
    }

    Context "Empty Collection Route" {
        It "should write an empty JSON array if the provided list is empty (Line 132)" {
            Mock Write-Success -ModuleName ChocoVSCodeCore {}
            Save-ChocoVSCodeExtensionState -StatePath $script:statePath -ExtensionsList @()

            $content = Get-Content $script:statePath -Raw
            $content.Trim() | Should -Be "[]"
        }
    }
}
