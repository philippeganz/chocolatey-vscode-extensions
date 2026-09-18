#Requires -Version 7.0
BeforeAll {
    $libPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
    if ($env:PSModulePath -notmatch [regex]::Escape($libPath)) {
        $env:PSModulePath = "$libPath;$env:PSModulePath"
    }

    Import-Module ChocoVSCodeCore -Force
    Import-Module ChocoVSCodeMarketplace -Force
}

Describe "Get-VsCodeNuspecMetadata" {
    Context "Basic Metadata Mapping" {
        It "should map basic properties (displayName, shortDescription, publisher)" {
            $fakeExtMeta = @{
                displayName      = "My Extension"
                shortDescription = "A test extension"
                publisher        = @{ publisherName = "TestPublisher" }
            }
            $meta = Get-VsCodeNuspecMetadata -ExtMeta $fakeExtMeta -ExtensionPublisher "test-pub" -ExtensionName "my-ext"
            $meta.Title | Should -Match "My Extension"
            $meta.Authors | Should -Be "TestPublisher"
        }
    }

    Context "Complex Metadata Extraction (Versions Array)" {
        It "should extract and format Source, Support, Learn links, and strip .git from ProjectSource (Lines 73-92)" {
            $fakeExtMeta = @{
                displayName = "My Extension"
                versions    = @(
                    @{
                        properties = @(
                            @{ key = "Microsoft.VisualStudio.Services.Links.Source"; value = "https://github.com/org/repo.git" }
                            @{ key = "Microsoft.VisualStudio.Services.Links.Support"; value = "https://github.com/org/repo/issues" }
                            @{ key = "Microsoft.VisualStudio.Services.Links.Learn"; value = "https://github.com/org/repo/wiki" }
                        )
                    }
                )
            }
            $meta = Get-VsCodeNuspecMetadata -ExtMeta $fakeExtMeta -ExtensionPublisher "test-pub" -ExtensionName "my-ext"

            # The .git suffix must be stripped
            $meta.ProjectSourceUrl | Should -Be "https://github.com/org/repo"
            # But the original .git URL should be set as ProjectUrl
            $meta.ProjectUrl | Should -Be "https://github.com/org/repo.git"

            $meta.BugTrackerUrl | Should -Be "https://github.com/org/repo/issues"
            $meta.DocsUrl | Should -Be "https://github.com/org/repo/wiki"
        }

        It "should extract the Icon URL from the files array (Lines 106-112)" {
            $fakeExtMeta = @{
                displayName = "My Extension"
                versions    = @(
                    @{
                        files = @(
                            @{ assetType = "Microsoft.VisualStudio.Services.VSIXPackage"; source = "bad" }
                            @{ assetType = "Microsoft.VisualStudio.Services.Icons.Default"; source = "https://icon.url/icon.png" }
                        )
                    }
                )
            }
            $meta = Get-VsCodeNuspecMetadata -ExtMeta $fakeExtMeta -ExtensionPublisher "test-pub" -ExtensionName "my-ext"
            $meta.IconUrl | Should -Be "https://icon.url/icon.png"
        }
    }

    Context "Tags Processing" {
        It "should merge default tags, sanitize invalid characters, and deduplicate (Lines 94-104)" {
            $fakeExtMeta = @{
                displayName = "My Extension"
                tags        = @("Python", "Jupyter", "Bad@Tag!", "  ", "vscode", "jupyter")
            }
            $meta = Get-VsCodeNuspecMetadata -ExtMeta $fakeExtMeta -ExtensionPublisher "test-pub" -ExtensionName "my-ext"

            # Default tags should be 'vscode extension my-ext'
            # Merged with 'python jupyter bad-tag-'
            # And deduplicated!
            $tags = $meta.Tags -split " "
            $tags | Should -Contain "vscode"
            $tags | Should -Contain "extension"
            $tags | Should -Contain "my-ext"
            $tags | Should -Contain "python"
            $tags | Should -Contain "jupyter"
            $tags | Should -Contain "bad-tag"

            # Deduplication check: 'vscode' and 'jupyter' were provided twice, they should only appear once
            ($tags | Where-Object { $_ -eq "vscode" }).Count | Should -Be 1
            ($tags | Where-Object { $_ -eq "jupyter" }).Count | Should -Be 1
        }
    }
}
