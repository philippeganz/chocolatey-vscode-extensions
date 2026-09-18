#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }
    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force
}

Describe "Update-NuspecDependency" {
    Context "Successful Route" {
        It "should execute the joyful output by appending missing VS Code extension dependencies to the nuspec xml and tracking state" {
            $xmlDoc = [xml]"<?xml version='1.0'?><package><metadata><id>dummy</id><dependencies><dependency id='dummy'/></dependencies></metadata></package>"
            $packageJson = @{
                extensionDependencies = @("ms-python.python")
            }
            $fakeStatePath = Join-Path $TestDrive "state.json"
            Set-Content $fakeStatePath -Value "[]" -Encoding ASCII
            $deps = @(Update-NuspecDependency -NuspecXml $xmlDoc -PackageJson $packageJson -PackageName "vscode-test" -StatePath $fakeStatePath)
            $deps.Count | Should -Be 1
            $xmlDoc.package.metadata.dependencies.dependency[1].id | Should -Be "vscode-python"
        }
    }

    Context "ShouldProcess WhatIf Bypass" {
        It "should immediately return an empty list and bypass all XML modification (Line 63)" {
            $xmlDoc = [xml]"<?xml version='1.0'?><package><metadata><id>dummy</id><dependencies><dependency id='dummy'/></dependencies></metadata></package>"
            $packageJson = @{ extensionDependencies = @("ms-python.python") }
            $fakeStatePath = Join-Path $TestDrive "state.json"
            $deps = @(Update-NuspecDependency -NuspecXml $xmlDoc -PackageJson $packageJson -PackageName "vscode-test" -StatePath $fakeStatePath -WhatIf)

            $deps.Count | Should -Be 0
            # Ensure the XML was not mutated
            $xmlDoc.package.metadata.dependencies.dependency.id | Should -Be "dummy"
        }
    }

    Context "Missing Dependencies Node Creation" {
        It "should dynamically create the <dependencies> XML node if it doesn't already exist in the metadata (Lines 80-81)" {
            $xmlDoc = [xml]"<?xml version='1.0'?><package xmlns='http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd'><metadata><id>dummy</id></metadata></package>"
            $packageJson = @{ extensionDependencies = @("golang.Go") }
            $fakeStatePath = Join-Path $TestDrive "state.json"
            Set-Content $fakeStatePath -Value "[]" -Encoding ASCII

            $deps = @(Update-NuspecDependency -NuspecXml $xmlDoc -PackageJson $packageJson -PackageName "vscode-test" -StatePath $fakeStatePath)

            # Assert the node was successfully created and populated
            $xmlDoc.package.metadata.dependencies | Should -Not -BeNullOrEmpty
            $xmlDoc.package.metadata.dependencies.dependency.Count | Should -Be 2 # baseDep + golang.Go
            $deps.Count | Should -Be 1
        }
    }

    Context "ExtensionPack Mapping" {
        It "should correctly parse and inject dependencies declared in the extensionPack array (Line 124)" {
            $xmlDoc = [xml]"<?xml version='1.0'?><package><metadata><id>dummy</id><dependencies><dependency id='dummy'/></dependencies></metadata></package>"
            $packageJson = @{ extensionPack = @("ms-azuretools.vscode-docker") }
            $fakeStatePath = Join-Path $TestDrive "state.json"
            Set-Content $fakeStatePath -Value "[]" -Encoding ASCII

            $deps = @(Update-NuspecDependency -NuspecXml $xmlDoc -PackageJson $packageJson -PackageName "vscode-test" -StatePath $fakeStatePath)

            $deps.Count | Should -Be 1
            $deps[0] | Should -Be "ms-azuretools.vscode-docker"
            $xmlDoc.package.metadata.dependencies.dependency[1].id | Should -Be "vscode-docker"
        }
    }
}
