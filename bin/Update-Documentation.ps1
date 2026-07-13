<#
.SYNOPSIS
Auto-generates Markdown documentation for all scripts in the repository using platyPS.

.DESCRIPTION
This script scans all `.ps1` and `.psm1` files in the repository and utilizes the `platyPS` module
to natively extract all Comment-Based Help blocks (Synopsis, Description, Parameters, Examples).
It then compiles these into standard Markdown files in the `/docs` directory.
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
param()

$ErrorActionPreference = 'Stop'

# Ensure platyPS is installed
if (-not (Get-Module -ListAvailable -Name platyPS)) {
    Write-Host ">>> Installing platyPS module for documentation generation..." -ForegroundColor Cyan
    Install-Module -Name platyPS -Force -Scope CurrentUser -ErrorAction Stop
}
Import-Module platyPS -ErrorAction Stop

$docsDir = "$PSScriptRoot\..\docs\reference"
if (-not (Test-Path $docsDir)) {
    New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
}

Write-Host ">>> Generating Markdown Documentation from Comment-Based Help..." -ForegroundColor Cyan

$rootDir = "$PSScriptRoot\.."

Write-Host ">>> Processing Scripts in bin/ ..." -ForegroundColor Cyan
$binScripts = Get-ChildItem -Path (Join-Path $rootDir "bin") -Filter "*.ps1" -File
foreach ($script in $binScripts) {
    if ($script.Name -eq "Update-Documentation.ps1") { continue }
    Write-Host "    Generating docs for $($script.Name)"
    try {
        New-MarkdownHelp -Command $script.FullName -OutputFolder $docsDir -Force -ErrorAction SilentlyContinue | Out-Null
    }
    catch {
        Write-Host "    [WARNING] Failed to generate docs for $($script.Name): $_" -ForegroundColor Yellow
    }
}

Write-Host ">>> Processing Modules in lib/ ..." -ForegroundColor Cyan
if (Test-Path (Join-Path $rootDir "lib")) {
    $libModules = Get-ChildItem -Path (Join-Path $rootDir "lib") -Filter "*.psm1" -File
    foreach ($module in $libModules) {
        Write-Host "    Importing and processing $($module.Name)"
        try {
            Import-Module $module.FullName -Force
            $functions = Get-Command -Module $module.BaseName
            foreach ($func in $functions) {
                Write-Host "      -> $($func.Name)"
                New-MarkdownHelp -Command $func.Name -OutputFolder $docsDir -Force -ErrorAction SilentlyContinue | Out-Null
            }
        }
        catch {
            Write-Host "    [WARNING] Failed to generate docs for $($module.Name): $_" -ForegroundColor Yellow
        }
    }
}

Write-Host ">>> Documentation successfully compiled to $docsDir!" -ForegroundColor Green



