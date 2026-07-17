#Requires -Version 7.0
<#
.SYNOPSIS
Auto-generates Markdown documentation for all scripts in the repository using platyPS.

.DESCRIPTION
This script scans all `.ps1` and `.psm1` files in the repository and utilizes the `platyPS` module
to natively extract all Comment-Based Help blocks (Synopsis, Description, Parameters, Examples).
It then compiles these into standard Markdown files in the `/docs` directory.
#>
[CmdletBinding()]
param()

Import-Module "$PSScriptRoot\..\lib\CoreHelpers.psm1" -ErrorAction Stop

$ErrorActionPreference = 'Stop'

# Ensure platyPS is installed
if (-not (Get-Module -ListAvailable -Name platyPS)) {
    Write-Cyan ">>> Installing platyPS module for documentation generation..."
    Install-Module -Name platyPS -Force -Scope CurrentUser -ErrorAction Stop
}
Import-Module platyPS -ErrorAction Stop

$docsDir = "$PSScriptRoot\..\docs\reference"
if (-not (Test-Path $docsDir)) {
    [void](New-Item -ItemType Directory -Path $docsDir -Force)
}

Write-Cyan ">>> Generating Markdown Documentation from Comment-Based Help..."

$rootDir = "$PSScriptRoot\.."

Write-Cyan ">>> Processing Scripts in bin/ ..."
$binScripts = Get-ChildItem -Path (Join-Path $rootDir "bin") -Filter "*.ps1" -File
foreach ($script in $binScripts) {
    if ($script.Name -eq "Update-Documentation.ps1") { continue }

    if ($script.Name -eq "AuExtensionHooks.ps1") {
        Write-White "    Extracting internal functions for $($script.Name)"
        $tempModule = Join-Path ([System.IO.Path]::GetTempPath()) "AuExtensionHooks.psm1"
        $content = Get-Content $script.FullName -Raw
        $content = $content -replace '(?im)^Update-Package.*$', ''
        $content = $content -replace '(?im)^Import-Module au.*$', ''
        $content = $content -replace '\$PSScriptRoot', (Split-Path $script.FullName)
        Set-Content -Path $tempModule -Value $content -Encoding UTF8
        try {
            Import-Module $tempModule -Force
            foreach ($func in @('au_GetLatest', 'au_BeforeUpdate', 'au_SearchReplace')) {
                Write-White "      -> $func"
                [void](New-MarkdownHelp -Command $func -OutputFolder $docsDir -Force -ErrorAction SilentlyContinue)
            }
        }
        catch {
            Write-Yellow "    [WARNING] Failed to extract functions from $($script.Name): $_"
        }
        finally {
            Remove-Module AuExtensionHooks -ErrorAction SilentlyContinue
            Remove-Item $tempModule -Force -ErrorAction SilentlyContinue
        }
    }

    Write-White "    Generating docs for $($script.Name)"
    try {
        [void](New-MarkdownHelp -Command $script.FullName -OutputFolder $docsDir -Force -ErrorAction SilentlyContinue)
    }
    catch {
        Write-Yellow "    [WARNING] Failed to generate docs for $($script.Name): $_"
    }
}

Write-Cyan ">>> Processing Modules in lib/ ..."
if (Test-Path (Join-Path $rootDir "lib")) {
    $libModules = Get-ChildItem -Path (Join-Path $rootDir "lib") -Filter "*.psm1" -File
    foreach ($module in $libModules) {
        Write-White "    Importing and processing $($module.Name)"
        try {
            Import-Module $module.FullName -Force
            $functions = Get-Command -Module $module.BaseName
            foreach ($func in $functions) {
                Write-White "      -> $($func.Name)"
                [void](New-MarkdownHelp -Command $func.Name -OutputFolder $docsDir -Force -ErrorAction SilentlyContinue)
            }
        }
        catch {
            Write-Yellow "    [WARNING] Failed to generate docs for $($module.Name): $_"
        }
    }
}

Write-Cyan ">>> Scrubbing platyPS placeholders from documentation..."
Get-ChildItem -Path $docsDir -Filter "*.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $original = $content
    $content = $content -replace '(?im)^\s*\{\{\s*Fill\s+.*?\}\}\s*$', ''
    $content = $content -replace '(?sm)PS C:\\>\s*\{\{\s*Add\s+example\s+code\s+here\s*\}\}\r?\n\{\{\s*Add\s+example\s+description\s+here\s*\}\}', ''
    $content = $content -replace '(?sm)^\{\{\s*Add\s+example\s+description\s+here\s*\}\}\r?\n', ''

    # Sometimes platyPS leaves empty EXAMPLES or PARAMETERS blocks after scrubbing
    if ($original -ne $content) {
        Set-Content -Path $_.FullName -Value $content
    }
}

Write-Success "Documentation successfully compiled to $docsDir!"
