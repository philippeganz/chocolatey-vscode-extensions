BeforeAll {
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeCore\ChocoVSCodeCore.psd1 -Force
    $testDir = Join-Path $TestDrive "CoreHelpersTest"
    New-Item -ItemType Directory -Path $testDir | Out-Null
    $script:statePath = Join-Path $testDir "extensions.yaml"
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
        It "should parse the flat YAML array and return string array" {
            # Setup
            $yaml = "---
- 'ms-python.python'
- eamodio.gitlens
"
            Set-Content -Path $script:statePath -Value $yaml -Encoding UTF8

            # Execution
            $result = Get-ChocoVSCodeExtensionState -StatePath $script:statePath

            # Assertion
            $result.Count | Should -Be 2
            $result[0] | Should -Be "ms-python.python"
            $result[1] | Should -Be "eamodio.gitlens"
        }
    }
}

Describe "Save-ChocoVSCodeExtensionState" {
    Context "Successful Route" {
        It "should sort, deduplicate, and write extensions to YAML array" {
            # Setup
            $extList = @("ms-python.python", "z-author.extension", "a-author.extension", "ms-python.python")

            # Execution (Write-Success will be natively printed, we can ignore or mock it)
            Mock Write-Success -ModuleName ChocoVSCodeCore {}
            Save-ChocoVSCodeExtensionState -StatePath $script:statePath -ExtensionsList $extList

            # Assertion
            $content = Get-Content $script:statePath -Raw
            $content -match "a-author\.extension" | Should -Be $true
            $content -match "z-author\.extension" | Should -Be $true
            # Should be sorted
            $content.IndexOf("a-author") -lt $content.IndexOf("ms-python") | Should -Be $true
            $content.IndexOf("ms-python") -lt $content.IndexOf("z-author") | Should -Be $true

            # Should deduplicate
            $matchResult = [regex]::Matches($content, "ms-python\.python")
            $matchResult.Count | Should -Be 1
        }
    }
}


