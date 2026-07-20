<#
.SYNOPSIS
    Centralized utility functions for managing the config.yaml and badge state.
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is required for cross-platform ANSI colored output in orchestration')]
param()

Import-Module "$PSScriptRoot\CoreHelpers.psm1" -ErrorAction SilentlyContinue

if (-not (Get-Module -ListAvailable powershell-yaml)) {
    Write-Host "Installing required powershell-yaml module..." -ForegroundColor Yellow
    Install-Module powershell-yaml -Force -Scope CurrentUser
}
Import-Module powershell-yaml

<#
.SYNOPSIS
Reads and parses the config.yaml state tracker.

.PARAMETER ConfigPath
The path to the config.yaml file.

.OUTPUTS
A hashtable containing the raw parsed YAML and a populated List of tracked extensions.
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

.PARAMETER ConfigPath
The path to the config.yaml file.

.PARAMETER ExtensionsList
The updated list or array of active extensions.
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

    $badgeJson = [ordered]@{ schemaVersion = 1; label = "Extensions Tracked"; message = "$($sortedExtensions.Count)"; color = "blue" } | ConvertTo-Json -Compress
    $badgePath = Join-Path (Split-Path $ConfigPath) "badge.json"
    $badgeJson = $badgeJson.Replace("`r`n", "`n")
    [System.IO.File]::WriteAllText($badgePath, $badgeJson, [System.Text.UTF8Encoding]::new($false))

    Write-Success "State saved to config.yaml ($($sortedExtensions.Count) total extensions tracked)."
}

<#
.SYNOPSIS
Resolves the canonical name of the Chocolatey package based on the VS Code extension ID.
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
#>
function Get-AutomaticDirectory {
    if ($env:CHOCO_VSCODE_AUTOMATIC_DIR) {
        return $env:CHOCO_VSCODE_AUTOMATIC_DIR
    }
    $resolved = Resolve-Path "$PSScriptRoot\..\automatic" -ErrorAction SilentlyContinue
    if ($resolved) { return $resolved.Path }
    return "$PSScriptRoot\..\automatic"
}

Export-ModuleMember -Function Get-ConfigState, Save-ConfigState, Get-ChocoPackageName, Get-AutomaticDirectory
