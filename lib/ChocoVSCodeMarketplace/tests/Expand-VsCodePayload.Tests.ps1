#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    Context "Markdown Truncation and Tag Balancing" {
        It "should cleanly truncate on HTML boundaries and auto-close hanging tags" { Mock Convert-MixedMarkdownToPure { param($Text) return $Text } -ModuleName ChocoVSCodeMarketplace
            $fakeVsix = Join-Path $TestDrive "fake_html.vsix"
            $fakePkgDir = Join-Path $TestDrive "pkg_html"
            New-Item -ItemType Directory -Path $fakePkgDir -Force | Out-Null
            $dummyZipDir = Join-Path $TestDrive "dummy_html"
            $extDir = Join-Path $dummyZipDir "extension"
            New-Item -ItemType Directory -Path $extDir -Force | Out-Null

            # Create a 3800 char README with unclosed HTML tags right before the limit
            $padding = "A" * 3600
            $readmeContent = "<table><tr><td>$padding</td></tr></table></div>"
            # It will match </td></tr></table> as the cut-off, but we want it to leave unclosed tags
            $readmeContent = "<div><table><tbody><tr><td>$padding</td></tr>" + ("B" * 200)

            Set-Content -Path (Join-Path $extDir "package.json") -Value '{"name":"test", "publisher":"pub"}' -Encoding UTF8
            Set-Content -Path (Join-Path $extDir "README.md") -Value $readmeContent -Encoding UTF8
            Set-Content -Path (Join-Path $extDir "LICENSE.txt") -Value "MIT" -Encoding UTF8

            [System.IO.Compression.ZipFile]::CreateFromDirectory($dummyZipDir, $fakeVsix)

            $result = Expand-VsCodePayload -VsixPath $fakeVsix -DestinationDir $fakePkgDir

            # Assert truncation message
            $result.CDataSafeReadme | Should -Match "Truncated due to Chocolatey character limits"
            # Assert auto-closing of the tags (div, table, tbody, tr, td)
            $result.CDataSafeReadme | Should -Match "</tbody>"
            $result.CDataSafeReadme | Should -Match "</table>"
            $result.CDataSafeReadme | Should -Match "</div>"

            # Assert LICENSE extraction
            Test-Path (Join-Path $fakePkgDir "legal\LICENSE.txt") | Should -Be $true
        }

        It "should cleanly truncate on period boundaries if no HTML tags are present" {
            $fakeVsix = Join-Path $TestDrive "fake_dot.vsix"
            $fakePkgDir = Join-Path $TestDrive "pkg_dot"
            New-Item -ItemType Directory -Path $fakePkgDir -Force | Out-Null
            $dummyZipDir = Join-Path $TestDrive "dummy_dot"
            $extDir = Join-Path $dummyZipDir "extension"
            New-Item -ItemType Directory -Path $extDir -Force | Out-Null

            # Pad with 3600 chars, then a dot, then 300 chars without any HTML or dots
            $padding = "A" * 3600
            $readmeContent = "$padding. " + ("B" * 300)

            Set-Content -Path (Join-Path $extDir "package.json") -Value '{"name":"test", "publisher":"pub"}' -Encoding UTF8
            Set-Content -Path (Join-Path $extDir "README.md") -Value $readmeContent -Encoding UTF8
            [System.IO.Compression.ZipFile]::CreateFromDirectory($dummyZipDir, $fakeVsix)

            $result = Expand-VsCodePayload -VsixPath $fakeVsix -DestinationDir $fakePkgDir
            $result.CDataSafeReadme | Should -Match "Truncated due to Chocolatey character limits"
        }

        It "should cleanly truncate on newline boundaries" {
            $fakeVsix = Join-Path $TestDrive "fake_nl.vsix"
            $fakePkgDir = Join-Path $TestDrive "pkg_nl"
            New-Item -ItemType Directory -Path $fakePkgDir -Force | Out-Null
            $dummyZipDir = Join-Path $TestDrive "dummy_nl"
            $extDir = Join-Path $dummyZipDir "extension"
            New-Item -ItemType Directory -Path $extDir -Force | Out-Null

            # Pad with 3600 chars, then a newline, then 300 chars
            $padding = "A" * 3600
            $readmeContent = "$padding
" + ("B" * 300)

            Set-Content -Path (Join-Path $extDir "package.json") -Value '{"name":"test", "publisher":"pub"}' -Encoding UTF8
            Set-Content -Path (Join-Path $extDir "README.md") -Value $readmeContent -Encoding UTF8
            [System.IO.Compression.ZipFile]::CreateFromDirectory($dummyZipDir, $fakeVsix)

            $result = Expand-VsCodePayload -VsixPath $fakeVsix -DestinationDir $fakePkgDir
            $result.CDataSafeReadme | Should -Match "Truncated due to Chocolatey character limits"
        }

        It "should cleanly truncate on space boundaries" {
            $fakeVsix = Join-Path $TestDrive "fake_sp.vsix"
            $fakePkgDir = Join-Path $TestDrive "pkg_sp"
            New-Item -ItemType Directory -Path $fakePkgDir -Force | Out-Null
            $dummyZipDir = Join-Path $TestDrive "dummy_sp"
            $extDir = Join-Path $dummyZipDir "extension"
            New-Item -ItemType Directory -Path $extDir -Force | Out-Null

            # Pad with 3600 chars, then a space, then 300 chars
            $padding = "A" * 3600
            $readmeContent = "$padding " + ("B" * 300)

            Set-Content -Path (Join-Path $extDir "package.json") -Value '{"name":"test", "publisher":"pub"}' -Encoding UTF8
            Set-Content -Path (Join-Path $extDir "README.md") -Value $readmeContent -Encoding UTF8
            [System.IO.Compression.ZipFile]::CreateFromDirectory($dummyZipDir, $fakeVsix)

            $result = Expand-VsCodePayload -VsixPath $fakeVsix -DestinationDir $fakePkgDir
            $result.CDataSafeReadme | Should -Match "Truncated due to Chocolatey character limits"
        }

        It "should fallback to hard truncation" {
            $fakeVsix = Join-Path $TestDrive "fake_hard.vsix"
            $fakePkgDir = Join-Path $TestDrive "pkg_hard"
            New-Item -ItemType Directory -Path $fakePkgDir -Force | Out-Null
            $dummyZipDir = Join-Path $TestDrive "dummy_hard"
            $extDir = Join-Path $dummyZipDir "extension"
            New-Item -ItemType Directory -Path $extDir -Force | Out-Null

            # 3900 characters without ANY spaces, dots, newlines, or html
            $readmeContent = "A" * 3900

            Set-Content -Path (Join-Path $extDir "package.json") -Value '{"name":"test", "publisher":"pub"}' -Encoding UTF8
            Set-Content -Path (Join-Path $extDir "README.md") -Value $readmeContent -Encoding UTF8
            [System.IO.Compression.ZipFile]::CreateFromDirectory($dummyZipDir, $fakeVsix)

            $result = Expand-VsCodePayload -VsixPath $fakeVsix -DestinationDir $fakePkgDir
            $result.CDataSafeReadme | Should -Match "Truncated due to Chocolatey character limits"
        }
    }
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
    Context "Markdown Truncation and Tag Balancing" {
        It "should cleanly truncate on HTML boundaries and auto-close hanging tags" { Mock Convert-MixedMarkdownToPure { param($Text) return $Text } -ModuleName ChocoVSCodeMarketplace
            $fakeVsix = Join-Path $TestDrive "fake_html.vsix"
            $fakePkgDir = Join-Path $TestDrive "pkg_html"
            New-Item -ItemType Directory -Path $fakePkgDir -Force | Out-Null
            $dummyZipDir = Join-Path $TestDrive "dummy_html"
            $extDir = Join-Path $dummyZipDir "extension"
            New-Item -ItemType Directory -Path $extDir -Force | Out-Null

            # Create a 3800 char README with unclosed HTML tags right before the limit
            $padding = "A" * 3600
            $readmeContent = "<table><tr><td>$padding</td></tr></table></div>"
            # It will match </td></tr></table> as the cut-off, but we want it to leave unclosed tags
            $readmeContent = "<div><table><tbody><tr><td>$padding</td></tr>" + ("B" * 200)

            Set-Content -Path (Join-Path $extDir "package.json") -Value '{"name":"test", "publisher":"pub"}' -Encoding UTF8
            Set-Content -Path (Join-Path $extDir "README.md") -Value $readmeContent -Encoding UTF8
            Set-Content -Path (Join-Path $extDir "LICENSE.txt") -Value "MIT" -Encoding UTF8

            [System.IO.Compression.ZipFile]::CreateFromDirectory($dummyZipDir, $fakeVsix)

            $result = Expand-VsCodePayload -VsixPath $fakeVsix -DestinationDir $fakePkgDir

            # Assert truncation message
            $result.CDataSafeReadme | Should -Match "Truncated due to Chocolatey character limits"
            # Assert auto-closing of the tags (div, table, tbody, tr, td)
            $result.CDataSafeReadme | Should -Match "</tbody>"
            $result.CDataSafeReadme | Should -Match "</table>"
            $result.CDataSafeReadme | Should -Match "</div>"

            # Assert LICENSE extraction
            Test-Path (Join-Path $fakePkgDir "legal\LICENSE.txt") | Should -Be $true
        }

        It "should cleanly truncate on period boundaries if no HTML tags are present" {
            $fakeVsix = Join-Path $TestDrive "fake_dot.vsix"
            $fakePkgDir = Join-Path $TestDrive "pkg_dot"
            New-Item -ItemType Directory -Path $fakePkgDir -Force | Out-Null
            $dummyZipDir = Join-Path $TestDrive "dummy_dot"
            $extDir = Join-Path $dummyZipDir "extension"
            New-Item -ItemType Directory -Path $extDir -Force | Out-Null

            # Pad with 3600 chars, then a dot, then 300 chars without any HTML or dots
            $padding = "A" * 3600
            $readmeContent = "$padding. " + ("B" * 300)

            Set-Content -Path (Join-Path $extDir "package.json") -Value '{"name":"test", "publisher":"pub"}' -Encoding UTF8
            Set-Content -Path (Join-Path $extDir "README.md") -Value $readmeContent -Encoding UTF8
            [System.IO.Compression.ZipFile]::CreateFromDirectory($dummyZipDir, $fakeVsix)

            $result = Expand-VsCodePayload -VsixPath $fakeVsix -DestinationDir $fakePkgDir
            $result.CDataSafeReadme | Should -Match "Truncated due to Chocolatey character limits"
        }

        It "should cleanly truncate on newline boundaries" {
            $fakeVsix = Join-Path $TestDrive "fake_nl.vsix"
            $fakePkgDir = Join-Path $TestDrive "pkg_nl"
            New-Item -ItemType Directory -Path $fakePkgDir -Force | Out-Null
            $dummyZipDir = Join-Path $TestDrive "dummy_nl"
            $extDir = Join-Path $dummyZipDir "extension"
            New-Item -ItemType Directory -Path $extDir -Force | Out-Null

            # Pad with 3600 chars, then a newline, then 300 chars
            $padding = "A" * 3600
            $readmeContent = "$padding
" + ("B" * 300)

            Set-Content -Path (Join-Path $extDir "package.json") -Value '{"name":"test", "publisher":"pub"}' -Encoding UTF8
            Set-Content -Path (Join-Path $extDir "README.md") -Value $readmeContent -Encoding UTF8
            [System.IO.Compression.ZipFile]::CreateFromDirectory($dummyZipDir, $fakeVsix)

            $result = Expand-VsCodePayload -VsixPath $fakeVsix -DestinationDir $fakePkgDir
            $result.CDataSafeReadme | Should -Match "Truncated due to Chocolatey character limits"
        }

        It "should cleanly truncate on space boundaries" {
            $fakeVsix = Join-Path $TestDrive "fake_sp.vsix"
            $fakePkgDir = Join-Path $TestDrive "pkg_sp"
            New-Item -ItemType Directory -Path $fakePkgDir -Force | Out-Null
            $dummyZipDir = Join-Path $TestDrive "dummy_sp"
            $extDir = Join-Path $dummyZipDir "extension"
            New-Item -ItemType Directory -Path $extDir -Force | Out-Null

            # Pad with 3600 chars, then a space, then 300 chars
            $padding = "A" * 3600
            $readmeContent = "$padding " + ("B" * 300)

            Set-Content -Path (Join-Path $extDir "package.json") -Value '{"name":"test", "publisher":"pub"}' -Encoding UTF8
            Set-Content -Path (Join-Path $extDir "README.md") -Value $readmeContent -Encoding UTF8
            [System.IO.Compression.ZipFile]::CreateFromDirectory($dummyZipDir, $fakeVsix)

            $result = Expand-VsCodePayload -VsixPath $fakeVsix -DestinationDir $fakePkgDir
            $result.CDataSafeReadme | Should -Match "Truncated due to Chocolatey character limits"
        }

        It "should fallback to hard truncation" {
            $fakeVsix = Join-Path $TestDrive "fake_hard.vsix"
            $fakePkgDir = Join-Path $TestDrive "pkg_hard"
            New-Item -ItemType Directory -Path $fakePkgDir -Force | Out-Null
            $dummyZipDir = Join-Path $TestDrive "dummy_hard"
            $extDir = Join-Path $dummyZipDir "extension"
            New-Item -ItemType Directory -Path $extDir -Force | Out-Null

            # 3900 characters without ANY spaces, dots, newlines, or html
            $readmeContent = "A" * 3900

            Set-Content -Path (Join-Path $extDir "package.json") -Value '{"name":"test", "publisher":"pub"}' -Encoding UTF8
            Set-Content -Path (Join-Path $extDir "README.md") -Value $readmeContent -Encoding UTF8
            [System.IO.Compression.ZipFile]::CreateFromDirectory($dummyZipDir, $fakeVsix)

            $result = Expand-VsCodePayload -VsixPath $fakeVsix -DestinationDir $fakePkgDir
            $result.CDataSafeReadme | Should -Match "Truncated due to Chocolatey character limits"
        }
    }
}
