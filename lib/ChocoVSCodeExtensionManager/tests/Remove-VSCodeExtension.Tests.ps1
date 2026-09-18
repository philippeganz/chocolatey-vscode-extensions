#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }
    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeExtensionManager -Force
}

Describe "Remove-VSCodeExtension" {
    Context "Successful Route" {
        It "should execute the joyful output and save the updated state" {
            Mock Get-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager -MockWith { return [string[]]@("ms-python.python") }
            Mock Save-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Info -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Success -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Warn -ModuleName ChocoVSCodeExtensionManager {}

            $fakeAutomaticDir = Join-Path $TestDrive "automatic"
            New-Item -ItemType Directory -Path $fakeAutomaticDir | Out-Null
            $fakePkgDir = Join-Path $fakeAutomaticDir "vscode-python"
            New-Item -ItemType Directory -Path $fakePkgDir | Out-Null
            $fakeStatePath = Join-Path $TestDrive "state.json"

            Remove-VSCodeExtension -ExtensionId "ms-python.python" -StatePath $fakeStatePath -AutomaticDir $fakeAutomaticDir
            Should -Invoke -CommandName Save-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager -Times 1
        }
    }

    Context "Reverse Lookup" {
        It "should resolve compiled package names back to their full extension IDs (Lines 84-93)" {
            Mock Get-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager -MockWith { return [string[]]@("ms-python.python") }
            Mock Save-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Info -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Success -ModuleName ChocoVSCodeExtensionManager {}

            $fakeAutomaticDir = Join-Path $TestDrive "auto_lookup"
            New-Item -ItemType Directory -Path $fakeAutomaticDir | Out-Null
            $fakeStatePath = Join-Path $TestDrive "state.json"

            # Pass the compiled name 'vscode-python' instead of the ID
            Remove-VSCodeExtension -ExtensionId "vscode-python" -StatePath $fakeStatePath -AutomaticDir $fakeAutomaticDir
            Should -Invoke -CommandName Save-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager -Times 1
        }
    }

    Context "WhatIf Execution" {
        It "should respect ShouldProcess and skip deletions (Line 100, 112)" {
            Mock Get-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager -MockWith { return [string[]]@("ms-python.python") }
            Mock Save-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Info -ModuleName ChocoVSCodeExtensionManager {}

            $fakeAutomaticDir = Join-Path $TestDrive "auto_whatif"
            New-Item -ItemType Directory -Path $fakeAutomaticDir | Out-Null
            $fakePkgDir = Join-Path $fakeAutomaticDir "vscode-python"
            New-Item -ItemType Directory -Path $fakePkgDir | Out-Null
            $fakeStatePath = Join-Path $TestDrive "state.json"

            Remove-VSCodeExtension -ExtensionId "ms-python.python" -StatePath $fakeStatePath -AutomaticDir $fakeAutomaticDir -WhatIf

            Test-Path $fakePkgDir | Should -Be $true
            Should -Invoke -CommandName Save-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager -Times 0
        }
    }

    Context "Dependency Protections" {
        It "should block deletion if another package depends on it (Line 122-133, 141-143)" {
            Mock Get-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager -MockWith { return [string[]]@("ms-python.python") }
            Mock Write-Err -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Info -ModuleName ChocoVSCodeExtensionManager {}

            $fakeAutomaticDir = Join-Path $TestDrive "auto_dep"
            New-Item -ItemType Directory -Path $fakeAutomaticDir | Out-Null
            $fakePkgDir = Join-Path $fakeAutomaticDir "vscode-python"
            New-Item -ItemType Directory -Path $fakePkgDir | Out-Null

            $dependentPkgDir = Join-Path $fakeAutomaticDir "vscode-jupyter"
            New-Item -ItemType Directory -Path $dependentPkgDir | Out-Null

            $nuspecContent = '<?xml version="1.0"?><package><metadata><dependencies><dependency id="vscode-python" /></dependencies></metadata></package>'
            Set-Content -Path (Join-Path $dependentPkgDir "vscode-jupyter.nuspec") -Value $nuspecContent
            $fakeStatePath = Join-Path $TestDrive "state.json"

            Remove-VSCodeExtension -ExtensionId "ms-python.python" -StatePath $fakeStatePath -AutomaticDir $fakeAutomaticDir

            Test-Path $fakePkgDir | Should -Be $true
            Should -Invoke -CommandName Write-Err -ModuleName ChocoVSCodeExtensionManager -ParameterFilter { $Message -match "Cannot safely remove.*vscode-jupyter" }
        }

        It "should override dependency protection if -Force is passed (Line 146)" {
            Mock Get-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager -MockWith { return [string[]]@("ms-python.python") }
            Mock Write-Warn -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Info -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Success -ModuleName ChocoVSCodeExtensionManager {}
            Mock Save-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager {}

            $fakeAutomaticDir = Join-Path $TestDrive "auto_force"
            New-Item -ItemType Directory -Path $fakeAutomaticDir | Out-Null
            $fakePkgDir = Join-Path $fakeAutomaticDir "vscode-python"
            New-Item -ItemType Directory -Path $fakePkgDir | Out-Null

            $dependentPkgDir = Join-Path $fakeAutomaticDir "vscode-jupyter"
            New-Item -ItemType Directory -Path $dependentPkgDir | Out-Null
            $nuspecContent = '<?xml version="1.0"?><package><metadata><dependencies><dependency id="vscode-python" /></dependencies></metadata></package>'
            Set-Content -Path (Join-Path $dependentPkgDir "vscode-jupyter.nuspec") -Value $nuspecContent
            $fakeStatePath = Join-Path $TestDrive "state.json"

            Remove-VSCodeExtension -ExtensionId "ms-python.python" -StatePath $fakeStatePath -AutomaticDir $fakeAutomaticDir -Force

            Test-Path $fakePkgDir | Should -Be $false
            Should -Invoke -CommandName Write-Warn -ModuleName ChocoVSCodeExtensionManager -ParameterFilter { $Message -match "Overriding dependency protection" }
        }
    }

    Context "State and Ownership Protections" {
        It "should log a skip if the extension is not tracked in state (Line 156)" {
            Mock Get-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager -MockWith { return [string[]]@() }
            Mock Write-Skip -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Info -ModuleName ChocoVSCodeExtensionManager {}

            $fakeAutomaticDir = Join-Path $TestDrive "auto_skip"
            $fakeStatePath = Join-Path $TestDrive "state.json"

            Remove-VSCodeExtension -ExtensionId "not.tracked" -StatePath $fakeStatePath -AutomaticDir $fakeAutomaticDir

            Should -Invoke -CommandName Write-Skip -ModuleName ChocoVSCodeExtensionManager -ParameterFilter { $Message -match "was not found in state tracking" }
        }

        It "should delete state but retain directory if ownership is shared (Line 162)" {
            Mock Get-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager -MockWith { return [string[]]@("ms-python.python", "ms-python.python-test") }
            Mock Get-ChocoVSCodePackageName -ModuleName ChocoVSCodeExtensionManager -MockWith { return "vscode-python" }
            Mock Write-Warn -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Info -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Success -ModuleName ChocoVSCodeExtensionManager {}
            Mock Save-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager {}

            $fakeAutomaticDir = Join-Path $TestDrive "auto_shared"
            New-Item -ItemType Directory -Path $fakeAutomaticDir | Out-Null
            $fakePkgDir = Join-Path $fakeAutomaticDir "vscode-python"
            New-Item -ItemType Directory -Path $fakePkgDir | Out-Null
            $fakeStatePath = Join-Path $TestDrive "state.json"

            Remove-VSCodeExtension -ExtensionId "ms-python.python" -StatePath $fakeStatePath -AutomaticDir $fakeAutomaticDir

            Test-Path $fakePkgDir | Should -Be $true
            Should -Invoke -CommandName Write-Warn -ModuleName ChocoVSCodeExtensionManager -ParameterFilter { $Message -match "Skipping directory deletion" }
            Should -Invoke -CommandName Save-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager -Times 1
        }
    }

    Context "Deletion Retry Logic" {
        It "should sleep and retry if directory deletion throws, eventually failing (Line 174-179)" {
            Mock Get-ChocoVSCodeExtensionState -ModuleName ChocoVSCodeExtensionManager -MockWith { return [string[]]@("ms-python.python") }
            Mock Start-Sleep -ModuleName ChocoVSCodeExtensionManager {}
            Mock Remove-Item -ModuleName ChocoVSCodeExtensionManager { throw "Access Denied" }
            Mock Write-Info -ModuleName ChocoVSCodeExtensionManager {}
            Mock Write-Success -ModuleName ChocoVSCodeExtensionManager {}

            $fakeAutomaticDir = Join-Path $TestDrive "auto_retry"
            New-Item -ItemType Directory -Path $fakeAutomaticDir | Out-Null
            $fakePkgDir = Join-Path $fakeAutomaticDir "vscode-python"
            New-Item -ItemType Directory -Path $fakePkgDir | Out-Null
            $fakeStatePath = Join-Path $TestDrive "state.json"

            { Remove-VSCodeExtension -ExtensionId "ms-python.python" -StatePath $fakeStatePath -AutomaticDir $fakeAutomaticDir } | Should -Throw "Access Denied"

            Should -Invoke -CommandName Start-Sleep -ModuleName ChocoVSCodeExtensionManager -Times 2
            Should -Invoke -CommandName Remove-Item -ModuleName ChocoVSCodeExtensionManager -Times 3
        }
    }
}
