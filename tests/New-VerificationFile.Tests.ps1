BeforeAll {
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeCore\ChocoVSCodeCore.psd1 -Force
    Import-Module $PSScriptRoot\..\lib\ChocoVSCodeMarketplace\ChocoVSCodeMarketplace.psd1 -Force
}
Describe "New-VerificationFile" {
    Context "Successful Route" {
        It "should execute the joyful output by generating a SHA256 checksum and writing the verification file" {
            $fakeVsix = Join-Path $TestDrive "fake.vsix"
            Set-Content -Path $fakeVsix -Value "dummy_content" -Encoding ASCII
            $fakePkgDir = Join-Path $TestDrive "pkg"
            New-Item -ItemType Directory -Path $fakePkgDir -Force | Out-Null
            New-VerificationFile -VsixPath $fakeVsix -PackageDir $fakePkgDir -Publisher "foo" -ExtensionName "bar"
            $verFile = Join-Path $fakePkgDir "legal\VERIFICATION.txt"
            Test-Path $verFile | Should -Be $true
            $content = Get-Content $verFile -Raw
            $content | Should -Match "Expected SHA256"
        }
    }
}
