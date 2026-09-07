BeforeAll {
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeCore\ChocoVSCodeCore.psd1 -Force
}

Describe "Write-StyledMessage" {
    Context "Successful Route" {
        It "should format and pass the message to Write-Host" {
            Mock Write-Host -ModuleName ChocoVSCodeCore {}
            Write-StyledMessage -Message "Test Message" -Prefix "[PREFIX]" -Color "Cyan"
            Should -Invoke -CommandName Write-Host -ModuleName ChocoVSCodeCore -Times 1 -ParameterFilter { $Object -match "Test Message" }
        }
    }
}

Describe "Write-Err" {
    Context "Successful Route" {
        It "should pass the message with [ERROR] prefix to Write-StyledMessage" {
            Mock Write-StyledMessage -ModuleName ChocoVSCodeCore {}
            Write-Err -Message "Failure"
            Should -Invoke -CommandName Write-StyledMessage -ModuleName ChocoVSCodeCore -Times 1 -ParameterFilter { $Message -eq "[ERROR] Failure" }
        }
    }
}

Describe "Write-Info" {
    Context "Successful Route" {
        It "should pass the message with [INFO] prefix to Write-StyledMessage" {
            Mock Write-StyledMessage -ModuleName ChocoVSCodeCore {}
            Write-Info -Message "Information"
            Should -Invoke -CommandName Write-StyledMessage -ModuleName ChocoVSCodeCore -Times 1 -ParameterFilter { $Prefix -eq "[INFO]" -and $Message -eq "Information" }
        }
    }
}

Describe "Write-Skip" {
    Context "Successful Route" {
        It "should pass the message with [SKIP] prefix to Write-StyledMessage" {
            Mock Write-StyledMessage -ModuleName ChocoVSCodeCore {}
            Write-Skip -Message "Skipped"
            Should -Invoke -CommandName Write-StyledMessage -ModuleName ChocoVSCodeCore -Times 1 -ParameterFilter { $Prefix -eq "[SKIP]" -and $Message -eq "Skipped" }
        }
    }
}

Describe "Write-Success" {
    Context "Successful Route" {
        It "should pass the message with [SUCCESS] prefix to Write-StyledMessage" {
            Mock Write-StyledMessage -ModuleName ChocoVSCodeCore {}
            Write-Success -Message "Done"
            Should -Invoke -CommandName Write-StyledMessage -ModuleName ChocoVSCodeCore -Times 1 -ParameterFilter { $Prefix -eq "[SUCCESS]" -and $Message -eq "Done" }
        }
    }
}

Describe "Write-Warn" {
    Context "Successful Route" {
        It "should pass the message with [WARNING] prefix to Write-StyledMessage" {
            Mock Write-StyledMessage -ModuleName ChocoVSCodeCore {}
            Write-Warn -Message "Warning"
            Should -Invoke -CommandName Write-StyledMessage -ModuleName ChocoVSCodeCore -Times 1 -ParameterFilter { $Prefix -eq "[WARNING]" -and $Message -eq "Warning" }
        }
    }
}
