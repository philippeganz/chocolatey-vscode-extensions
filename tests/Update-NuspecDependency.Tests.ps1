BeforeAll {
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeCore\ChocoVSCodeCore.psd1 -Force
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeMarketplace\ChocoVSCodeMarketplace.psd1 -Force
}
Describe "Update-NuspecDependency" {
    Context "Successful Route" {
        It "should execute the joyful output by appending missing VS Code extension dependencies to the nuspec xml and tracking state" {
            $xmlDoc = [xml]"<?xml version='1.0'?><package><metadata><dependencies><dependency id='dummy'/></dependencies></metadata></package>"
            $packageJson = @{
                extensionDependencies = @("ms-python.python")
            }
            $fakeStatePath = Join-Path $TestDrive "state.yaml"
            Set-Content $fakeStatePath -Value "---" -Encoding ASCII
            $deps = Update-NuspecDependency -NuspecXml $xmlDoc -PackageJson $packageJson -PackageName "vscode-test" -StatePath $fakeStatePath
            $deps.Count | Should -Be 1
            $xmlDoc.package.metadata.dependencies.dependency[1].id | Should -Be "vscode-python"
        }
    }
}
