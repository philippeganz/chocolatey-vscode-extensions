BeforeAll {
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeCore\ChocoVSCodeCore.psd1 -Force
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeMarketplace\ChocoVSCodeMarketplace.psd1 -Force
    Add-Type -AssemblyName System.IO.Compression.FileSystem
}
Describe "Expand-VsCodePayload" {
    Context "Successful Route" {
        It "should execute the joyful output by extracting the vsix archive and parsing the payload" {
            $fakeVsix = Join-Path $TestDrive "fake.vsix"
            $fakePkgDir = Join-Path $TestDrive "pkg"
            New-Item -ItemType Directory -Path $fakePkgDir -Force | Out-Null
            $dummyZipDir = Join-Path $TestDrive "dummy_zip_source"
            $extDir = Join-Path $dummyZipDir "extension"
            New-Item -ItemType Directory -Path $extDir -Force | Out-Null
            Set-Content -Path (Join-Path $extDir "package.json") -Value '{"name":"test"}' -Encoding UTF8
            Set-Content -Path (Join-Path $extDir "README.md") -Value "# Test Readme" -Encoding UTF8
            [System.IO.Compression.ZipFile]::CreateFromDirectory($dummyZipDir, $fakeVsix)
            $result = Expand-VsCodePayload -VsixPath $fakeVsix -DestinationDir $fakePkgDir
            $result.PackageJson.name | Should -Be "test"
            $result.CDataSafeReadme | Should -Match "# Test Readme"
        }
    }
}
