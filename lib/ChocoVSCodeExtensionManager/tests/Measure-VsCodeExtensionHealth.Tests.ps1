#Requires -Version 7.0
BeforeAll {
    $script:originalPSModulePath = $env:PSModulePath
    $libPath = Resolve-Path (Join-Path $PSScriptRoot "..\..")
    $env:PSModulePath = "$libPath;$env:PSModulePath"
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeExtensionManager -Force
}

AfterAll {
    $env:PSModulePath = $script:originalPSModulePath
}

Describe "Measure-VsCodeExtensionHealth" {
    Context "Health Engine Thresholds" {
        It "should successfully calculate abandonware for >3 year old packages" {
            $oldDate = (Get-Date).AddYears(-4).ToString("o")
            $mockMeta = [PSCustomObject]@{
                flags               = "public"
                deprecationSettings = $null
                versions            = @( [PSCustomObject]@{ lastUpdated = $oldDate } )
            }

            $health = Measure-VsCodeExtensionHealth -Metadata $mockMeta
            $health.IsAbandonware | Should -Be $true
            $health.YearsOld | Should -BeGreaterOrEqual 4.0
        }

        It "should correctly detect and extract deprecation settings" {
            $mockMeta = [PSCustomObject]@{
                flags               = "public, deprecated"
                deprecationSettings = [PSCustomObject]@{ alternateExtensionId = "new.extension" }
                versions            = @( [PSCustomObject]@{ lastUpdated = (Get-Date).ToString("o") } )
            }

            $health = Measure-VsCodeExtensionHealth -Metadata $mockMeta
            $health.IsDeprecated | Should -Be $true
            $health.DeprecationMessage | Should -Match "Replaced by: new.extension"
        }
    }
}
