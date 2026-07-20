BeforeAll {
    $scriptPath = Resolve-Path "$PSScriptRoot\..\bin\Invoke-ExtensionShredder.ps1" -ErrorAction SilentlyContinue
    if (-not $scriptPath) {
        $scriptPath = Join-Path $PSScriptRoot "..\bin\Invoke-ExtensionShredder.ps1"
    }

    function Get-ConfigState {}
    function Save-ConfigState {}
    function Get-ChocoPackageName {}
    function Get-AutomaticDirectory {}
    function Write-Info {}
    function Write-Err {}
    function Write-Success {}
    function Write-Skip {}
}

Describe 'Invoke-ExtensionShredder' -Tag "Integration", 'Invoke-ExtensionShredder' {
    BeforeEach {
        $mockState = [PSCustomObject]@{
            Extensions = [System.Collections.Generic.List[string]]::new()
        }

        Mock Get-ConfigState { return $mockState }
        Mock Save-ConfigState {}
        Mock Get-ChocoPackageName {
            param($Id)
            if ([string]::IsNullOrWhiteSpace($Id)) { return $null }
            return $Id.Replace('.', '').ToLower()
        }
        Mock Get-AutomaticDirectory { return $baseAuto }
        Mock Write-Info {}
        Mock Write-Err {}
        Mock Write-Warning {}
        Mock Write-Success {}
        Mock Write-Skip {}
        Mock Import-Module {}

        $baseAuto = Join-Path $TestDrive "automatic_$(New-Guid)"
        New-Item -ItemType Directory -Path $baseAuto -Force | Out-Null

        $configFile = Join-Path $TestDrive 'config.yaml'
        New-Item -ItemType File -Path $configFile -Force | Out-Null
    }

    It 'removes a single extension correctly without dependencies' {
        $mockState.Extensions.Add('publisher.ext')
        $pkgName = 'publisherext'

        $pkgDir = Join-Path $baseAuto $pkgName
        New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null

        & $scriptPath -ExtensionId 'publisher.ext' -ConfigFile $configFile

        $mockState.Extensions.Contains('publisher.ext') | Should -BeFalse
        Test-Path $pkgDir | Should -BeFalse
        Should -Invoke -CommandName Save-ConfigState -Times 1 -Exactly
    }

    It 'performs reverse lookup when short package name is provided' {
        $mockState.Extensions.Add('publisher.ext')
        $pkgName = 'publisherext'

        $pkgDir = Join-Path $baseAuto $pkgName
        New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null

        & $scriptPath -ExtensionId $pkgName -ConfigFile $configFile

        $mockState.Extensions.Contains('publisher.ext') | Should -BeFalse
        Test-Path $pkgDir | Should -BeFalse
    }

    It 'blocks removal if the extension is a dependency of another package' {
        $mockState.Extensions.Add('publisher.ext')
        $pkgName = 'publisherext'
        $pkgDir = Join-Path $baseAuto $pkgName
        New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null

        $dependentPkgName = 'otherpkg'
        $dependentDir = Join-Path $baseAuto $dependentPkgName
        New-Item -ItemType Directory -Path $dependentDir -Force | Out-Null

        $nuspecContent = @"
<?xml version="1.0"?>
<package>
  <metadata>
    <dependencies>
      <dependency id="$pkgName" />
    </dependencies>
  </metadata>
</package>
"@
        Set-Content -Path (Join-Path $dependentDir "$dependentPkgName.nuspec") -Value $nuspecContent

        & $scriptPath -ExtensionId 'publisher.ext' -ConfigFile $configFile

        $mockState.Extensions.Contains('publisher.ext') | Should -BeTrue
        Test-Path $pkgDir | Should -BeTrue
        Should -Invoke -CommandName Write-Err -Times 2
    }

    It 'removes the extension if -Force is used, even if it is a dependency' {
        $mockState.Extensions.Add('publisher.ext')
        $pkgName = 'publisherext'
        $pkgDir = Join-Path $baseAuto $pkgName
        New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null

        $dependentPkgName = 'otherpkg'
        $dependentDir = Join-Path $baseAuto $dependentPkgName
        New-Item -ItemType Directory -Path $dependentDir -Force | Out-Null

        $nuspecContent = @"
<?xml version="1.0"?>
<package>
  <metadata>
    <dependencies>
      <dependency id="$pkgName" />
    </dependencies>
  </metadata>
</package>
"@
        Set-Content -Path (Join-Path $dependentDir "$dependentPkgName.nuspec") -Value $nuspecContent

        & $scriptPath -ExtensionId 'publisher.ext' -Force -ConfigFile $configFile

        $mockState.Extensions.Contains('publisher.ext') | Should -BeFalse
        Test-Path $pkgDir | Should -BeFalse
        Should -Invoke -CommandName Write-Warning -Times 1
    }

    It 'does not mutate config if the extension is not found in the config' {
        $pkgName = 'publisherext'
        $pkgDir = Join-Path $baseAuto $pkgName
        New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null

        & $scriptPath -ExtensionId 'publisher.ext' -ConfigFile $configFile

        Test-Path $pkgDir | Should -BeFalse
        Should -Invoke -CommandName Save-ConfigState -Times 0 -Exactly
        Should -Invoke -CommandName Write-Skip -Times 1
    }

    It 'does not fail if package directory does not exist' {
        $mockState.Extensions.Add('publisher.ext')

        & $scriptPath -ExtensionId 'publisher.ext' -ConfigFile $configFile

        $mockState.Extensions.Contains('publisher.ext') | Should -BeFalse
        Should -Invoke -CommandName Save-ConfigState -Times 1 -Exactly
    }
}
