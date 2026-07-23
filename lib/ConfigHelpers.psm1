#Requires -Version 7.0
#Requires -Module powershell-yaml
<#
.SYNOPSIS
    Centralized utility functions for managing the config.yaml and badge state.
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is required for cross-platform ANSI colored output in orchestration')]
param()

Import-Module "$PSScriptRoot\CoreHelpers.psm1" -ErrorAction SilentlyContinue
Import-Module powershell-yaml -ErrorAction Stop

<#
.SYNOPSIS
    Reads and parses the config.yaml state tracker.

.DESCRIPTION
    Uses the powershell-yaml module to read the raw `config.yaml` state file into an
    object model, extracting the list of active extensions for pool management.

.PARAMETER ConfigPath
    The path to the config.yaml file.

.EXAMPLE
    $config = Get-ConfigState -ConfigPath "C:\var\state\config.yaml"

.INPUTS
    None

.OUTPUTS
    [System.Collections.Hashtable]
    A hashtable containing the raw parsed YAML and a populated List of tracked extensions.

.NOTES
    Throws a terminating error if powershell-yaml is not installed.
#>
function Get-ConfigState ([string]$ConfigPath) {
    if (-not (Test-Path $ConfigPath)) { throw "config.yaml not found at $($ConfigPath)" }
    $yamlObj = Get-Content $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Yaml
    $extensions = [System.Collections.Generic.List[string]]::new()
    if ($yamlObj.extensions) {
        foreach ($ext in $yamlObj.extensions) {
            $extensions.Add([string]$ext.ToLower())
        }
    }
    return @{ Raw = $yamlObj; Extensions = $extensions }
}

<#
.SYNOPSIS
    Saves the modified extension pool back to config.yaml safely.

.DESCRIPTION
    Takes an array of extension IDs, sorts them alphabetically for consistency, and
    serializes them back to the `config.yaml` state file using powershell-yaml.

.PARAMETER ConfigPath
    The path to the config.yaml file.

.PARAMETER ExtensionsList
    The updated list or array of active extensions.

.EXAMPLE
    Save-ConfigState -ConfigPath "C:\var\state\config.yaml" -ExtensionsList @("foo.bar", "ms-python.python")

.INPUTS
    None

.OUTPUTS
    None

.NOTES
    Ensures that the resulting YAML structure uses standard array formatting.
#>
function Save-ConfigState ([string]$ConfigPath, [string[]]$ExtensionsList) {
    $sortedExtensions = $ExtensionsList | Sort-Object -Unique
    $orderedYaml = [ordered]@{
        extensions = @($sortedExtensions)
    }
    $yamlStr = ConvertTo-Yaml $orderedYaml
    $formattedYaml = "---`n" + ($yamlStr -replace '(?m)^-', '  -').TrimEnd() + "`n"
    $formattedYaml = $formattedYaml.Replace("`r`n", "`n")
    [System.IO.File]::WriteAllText($ConfigPath, $formattedYaml, [System.Text.UTF8Encoding]::new($false))

    Write-Success "State saved to config.yaml ($($sortedExtensions.Count) total extensions tracked)."
}

<#
.SYNOPSIS
    Resolves the canonical name of the Chocolatey package based on the VS Code extension ID.

.DESCRIPTION
    Replaces the period separator (e.g., `ms-python.python`) with a hyphen and prefixes
    `vscode-` to produce the canonical Chocolatey package ID (e.g., `vscode-python`).

.EXAMPLE
    $pkgName = Get-ChocoPackageName -ExtensionId "ms-python.python"

.INPUTS
    [System.String]

.OUTPUTS
    [System.String]

.NOTES
    This is the standard naming convention adopted across the Chocolatey ecosystem.
#>
function Get-ChocoPackageName ([string]$ExtensionId) {
    if (-not $ExtensionId) { return "" }
    $parts = $ExtensionId -split '\.'
    $pkgName = if ($parts.Count -eq 2) { $parts[1] } else { $ExtensionId }
    $pkgName = $pkgName.ToLower()
    if (-not $pkgName.StartsWith("vscode-")) {
        $pkgName = "vscode-$pkgName"
    }
    return $pkgName
}

<#
.SYNOPSIS
    Resolves the absolute path to the 'automatic' directory where packages are scaffolded.

.DESCRIPTION
    Dynamically navigates up from the current module path to find the repository root,
    then constructs the absolute path to the `automatic/` directory.

.EXAMPLE
    $autoDir = Get-AutomaticDirectory

.INPUTS
    None

.OUTPUTS
    [System.String]

.NOTES
    Designed to work regardless of where the repository is checked out.
#>
function Get-AutomaticDirectory {
    if ($env:CHOCO_VSCODE_AUTOMATIC_DIR) {
        return $env:CHOCO_VSCODE_AUTOMATIC_DIR
    }
    return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\automatic"))
}

Export-ModuleMember -Function Get-ConfigState, Save-ConfigState, Get-ChocoPackageName, Get-AutomaticDirectory
