#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force
}

Describe "Update-VsCodeNuspecMetadata" {
    Context "Successful Route" {
        It "should execute the joyful output by dynamically replacing token placeholders in the raw XML template with accurate metadata" {
            $xmlTemplate = "<?xml version='1.0'?><package><metadata><title>placeholder</title></metadata></package>"
            $meta = @{
                Title = "Python Extension"
            }
            $xmlContent = Update-VsCodeNuspecMetadata -NuspecContent $xmlTemplate -Meta $meta
            $xmlDoc = [xml]$xmlContent
            $xmlDoc.package.metadata.title | Should -Be "Python Extension"
        }
    }

    Context "Optional URL Injection (Missing Tags)" {
        It "should dynamically inject projectSourceUrl, bugTrackerUrl, and docsUrl if they are missing from the XML (Lines 59-96)" {
            $xmlTemplate = "<?xml version='1.0'?><package><metadata><title>Original</title><summary>Original Summary</summary><authors>Original Authors</authors><projectUrl>Original Project</projectUrl><licenseUrl>Original License</licenseUrl><releaseNotes>Original Release</releaseNotes><packageSourceUrl>https://github.com/chocolatey/choco</packageSourceUrl></metadata></package>"
            $meta = @{
                Title            = "Python Extension"
                ProjectSourceUrl = "https://github.com/source"
                BugTrackerUrl    = "https://github.com/issues"
                DocsUrl          = "https://github.com/docs"
            }

            $xmlContent = Update-VsCodeNuspecMetadata -NuspecContent $xmlTemplate -Meta $meta
            $xmlDoc = [xml]$xmlContent

            $xmlDoc.package.metadata.projectSourceUrl | Should -Be "https://github.com/source"
            $xmlDoc.package.metadata.bugTrackerUrl | Should -Be "https://github.com/issues"
            $xmlDoc.package.metadata.docsUrl | Should -Be "https://github.com/docs"
        }

        It "should inject bugTrackerUrl after packageSourceUrl if projectSourceUrl is absent" {
            $xmlTemplate = "<?xml version='1.0'?><package><metadata><title>Original</title><summary>Original Summary</summary><authors>Original Authors</authors><projectUrl>Original Project</projectUrl><licenseUrl>Original License</licenseUrl><releaseNotes>Original Release</releaseNotes><packageSourceUrl>https://github.com/chocolatey/choco</packageSourceUrl></metadata></package>"
            $meta = @{
                Title         = "Python Extension"
                BugTrackerUrl = "https://github.com/issues"
            }

            $xmlContent = Update-VsCodeNuspecMetadata -NuspecContent $xmlTemplate -Meta $meta
            $xmlDoc = [xml]$xmlContent

            $xmlDoc.package.metadata.bugTrackerUrl | Should -Be "https://github.com/issues"
            ($xmlContent -match "projectSourceUrl") | Should -Be $false
        }

        It "should inject docsUrl after projectSourceUrl if bugTrackerUrl is absent" {
            $xmlTemplate = "<?xml version='1.0'?><package><metadata><title>Original</title><summary>Original Summary</summary><authors>Original Authors</authors><projectUrl>Original Project</projectUrl><licenseUrl>Original License</licenseUrl><releaseNotes>Original Release</releaseNotes><packageSourceUrl>https://github.com/chocolatey/choco</packageSourceUrl><projectSourceUrl>https://github.com/source</projectSourceUrl></metadata></package>"
            $meta = @{
                Title   = "Python Extension"
                DocsUrl = "https://github.com/docs"
            }

            $xmlContent = Update-VsCodeNuspecMetadata -NuspecContent $xmlTemplate -Meta $meta
            $xmlDoc = [xml]$xmlContent

            $xmlDoc.package.metadata.docsUrl | Should -Be "https://github.com/docs"
        }
    }

    It "should inject docsUrl after packageSourceUrl if both bugTrackerUrl and projectSourceUrl are absent (Line 91)" {
        $xmlTemplate = "<?xml version='1.0'?><package><metadata><title>Original</title><packageSourceUrl>https://github.com/chocolatey/choco</packageSourceUrl></metadata></package>"
        $meta = @{
            DocsUrl = "https://github.com/docs"
        }

        $xmlContent = Update-VsCodeNuspecMetadata -NuspecContent $xmlTemplate -Meta $meta
        $xmlDoc = [xml]$xmlContent

        $xmlDoc.package.metadata.docsUrl | Should -Be "https://github.com/docs"
        ($xmlContent -match "projectSourceUrl") | Should -Be $false
        ($xmlContent -match "bugTrackerUrl") | Should -Be $false
    }

    Context "Optional URL Replacement (Existing Tags)" {
        It "should cleanly replace projectSourceUrl, bugTrackerUrl, and docsUrl if they already exist in the XML" {
            $xmlTemplate = "<?xml version='1.0'?><package><metadata><title>Original</title><summary>Original Summary</summary><authors>Original Authors</authors><projectUrl>Original Project</projectUrl><licenseUrl>Original License</licenseUrl><releaseNotes>Original Release</releaseNotes><projectSourceUrl>OLD SOURCE</projectSourceUrl><bugTrackerUrl>OLD BUGS</bugTrackerUrl><docsUrl>OLD DOCS</docsUrl><tags>old tags</tags></metadata></package>"
            $meta = @{
                Title            = "Python Extension"
                ProjectSourceUrl = "NEW SOURCE"
                BugTrackerUrl    = "NEW BUGS"
                DocsUrl          = "NEW DOCS"
                Tags             = "new tags"
            }

            $xmlContent = Update-VsCodeNuspecMetadata -NuspecContent $xmlTemplate -Meta $meta
            $xmlDoc = [xml]$xmlContent

            $xmlDoc.package.metadata.projectSourceUrl | Should -Be "NEW SOURCE"
            $xmlDoc.package.metadata.bugTrackerUrl | Should -Be "NEW BUGS"
            $xmlDoc.package.metadata.docsUrl | Should -Be "NEW DOCS"
            $xmlDoc.package.metadata.tags | Should -Be "new tags"
        }
    }
}
