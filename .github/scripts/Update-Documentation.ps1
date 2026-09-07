#Requires -Version 7.0
#Requires -Module platyPS

<#
.SYNOPSIS
    Auto-generates Markdown documentation for all scripts in the repository using platyPS.

.DESCRIPTION
    This script scans all `.ps1` and `.psm1` files in the repository and utilizes the `platyPS` module
    to natively extract all Comment-Based Help blocks (Synopsis, Description, Parameters, Examples).
    It then compiles these into standard Markdown files in the `/docs` directory.

.EXAMPLE
    .\Update-Documentation.ps1

.INPUTS
    None

.OUTPUTS
    None

.NOTES
    It automatically sanitizes and formats the extracted documentation for optimal rendering
    within MkDocs Material.
#>
[CmdletBinding()]
param()

# =============================================================================
# Global Error Handling
# =============================================================================
# Enforce strict fail-fast behavior across this entire script/module.
# Any cmdlet or module import failure will immediately throw a terminating error.
# Override locally with -ErrorAction SilentlyContinue when needed.
$ErrorActionPreference = 'Stop'


# =============================================================================
# Import Modules
# =============================================================================
$env:PSModulePath = "$PSScriptRoot\..\..\lib;$env:PSModulePath"
Import-Module ChocoVSCodeCore
Import-Module platyPS

$rootDir = "$PSScriptRoot\..\.."
$docsDir = Join-Path $rootDir "docs\reference"
if (Test-Path $docsDir) {
    Remove-Item -Path $docsDir -Recurse -Force
}
[void](New-Item -ItemType Directory -Path $docsDir -Force)

Write-StyledMessage -Color Cyan -Message ">>> Generating Markdown Documentation from Comment-Based Help..."

Write-StyledMessage -Color Cyan -Message ">>> Processing Scripts in bin/ ..."
$binScripts = Get-ChildItem -Path (Join-Path $rootDir "bin") -Filter "*.ps1" -File
foreach ($script in $binScripts) {
    if ($script.Name -eq "Update-Documentation.ps1") { continue }

    Write-Verbose "    Generating docs for $($script.Name)"
    try {
        [void](New-MarkdownHelp -Command $script.FullName -OutputFolder $docsDir -Force -ErrorAction SilentlyContinue)
    }
    catch {
        Write-Warn "Failed to generate docs for $($script.Name): $_"
    }
}

Write-StyledMessage -Color Cyan -Message ">>> Processing Modules in lib/ ..."
if (Test-Path (Join-Path $rootDir "lib")) {
    $libModules = Get-ChildItem -Path (Join-Path $rootDir "lib") -Filter "*.psd1" -File -Recurse
    foreach ($module in $libModules) {
        Write-Verbose "    Importing and processing $($module.Name)"
        try {
            Import-Module $module.FullName -Force
            $functions = (Get-Command -Module $module.BaseName) | Sort-Object Name
            $modInfo = Get-Module $module.BaseName

            $moduleDocsDir = Join-Path $docsDir $module.BaseName
            [void](New-Item -ItemType Directory -Path $moduleDocsDir -Force)

            $indexPath = Join-Path $moduleDocsDir "index.md"
            $desc = if ($modInfo.Description) { $modInfo.Description } else { "This module exposes the following commands:" }
            "# $($module.BaseName) Module`n`n$desc`n`n### Exported Commands`n`n" | Out-File $indexPath -Encoding UTF8

            foreach ($func in $functions) {
                Write-Verbose "      -> $($func.Name)"
                [void](New-MarkdownHelp -Command $func.Name -OutputFolder $moduleDocsDir -Force -ErrorAction SilentlyContinue)
                "- [$($func.Name)]($($func.Name).md)`n" | Out-File $indexPath -Append -Encoding UTF8
            }
        }
        catch {
            Write-Warn "Failed to generate docs for $($module.Name): $_"
        }
    }
}

Write-StyledMessage -Color Cyan -Message ">>> Scrubbing platyPS placeholders from documentation..."
Get-ChildItem -Path $docsDir -Filter "*.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $original = $content
    $content = $content -replace '(?im)^\s*\{\{\s*Fill\s+.*?\}\}\s*$', ''
    $content = $content -replace '(?sm)PS C:\\>\s*\{\{\s*Add\s+example\s+code\s+here\s*\}\}\r?\n\{\{\s*Add\s+example\s+description\s+here\s*\}\}', ''
    $content = $content -replace '(?sm)^\{\{\s*Add\s+example\s+description\s+here\s*\}\}\r?\n', ''

    # Sometimes platyPS leaves empty EXAMPLES or PARAMETERS blocks after scrubbing
    if ($original -ne $content) {
        $content = $content.Replace("`r`n", "`n")
        [System.IO.File]::WriteAllText($_.FullName, $content, [System.Text.UTF8Encoding]::new($false))
    }
}

Write-Success "Documentation successfully compiled to $docsDir!"
