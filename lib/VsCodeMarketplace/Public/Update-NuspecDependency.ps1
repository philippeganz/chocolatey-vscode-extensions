<#
.SYNOPSIS
    Dynamically updates the Chocolatey .nuspec XML to append discovered extension dependencies.

.DESCRIPTION
    Scans the raw package.json of a VS Code extension for internal `extensionDependencies` or `extensionPacks` arrays.
    It maps these dependencies to their Chocolatey package equivalents, appends them to the `<dependencies>` block of the .nuspec, and auto-queues missing ones to the Factory.

.PARAMETER NuspecXml
    An [xml] object representing the parsed .nuspec file.

.PARAMETER PackageJson
    A JSON object representing the parsed package.json from the extension payload.

.PARAMETER PackageName
    The canonical Chocolatey package name currently being processed.

.PARAMETER ConfigPath
    The absolute path to the config.yaml tracker.

.EXAMPLE
    Update-NuspecDependency -NuspecXml $xml -PackageJson $json -ConfigPath "C:\var\state\config.yaml"

.INPUTS
    None

.OUTPUTS
    None

.NOTES
    Mutates the passed XML object in memory. Prevents cyclic dependency loops natively.
#>
function Update-NuspecDependency {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Function manages external state where ShouldProcess is handled internally')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Global variables are required for AU configuration and workflow state')]
    param(
        [Parameter(Mandatory = $true)][object]$NuspecXml,
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$PackageJson,
        [Parameter(Mandatory = $true)][string]$ConfigPath
    )

    Import-Module powershell-yaml

    $dependencyAliases = @{
        "vscode.docker"               = "ms-azuretools.vscode-docker"
        "PeterJausovec.vscode-docker" = "ms-azuretools.vscode-docker"
        "vscode.yaml"                 = "redhat.vscode-yaml"
        "donjayamanne.python"         = "ms-python.python"
        "lukehoban.Go"                = "golang.Go"
        "ms-vscode.Go"                = "golang.Go"
        "ms-vscode.csharp"            = "ms-dotnettools.csharp"
        "eg2.tslint"                  = "ms-vscode.vscode-typescript-tslint-plugin"
    }

    $ns = $NuspecXml.DocumentElement.NamespaceURI
    $depsNode = $NuspecXml.package.metadata.dependencies
    if ($null -eq $depsNode) {
        $depsNode = $NuspecXml.CreateElement("dependencies", $ns)
        [void]$NuspecXml.package.metadata.AppendChild($depsNode)
    }
    else {
        $depsNode.RemoveAll()
    }

    [void]$depsNode.AppendChild($NuspecXml.CreateSignificantWhitespace("`n      "))
    $baseDep = $NuspecXml.CreateElement("dependency", $ns)
    $baseDep.SetAttribute("id", "chocolatey-vscode.extension")
    $baseDep.SetAttribute("version", "[1.1.0, 2.0.0)")
    [void]$depsNode.AppendChild($baseDep)

    $config = Get-Content $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Yaml
    $trackedExtensions = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($ext in $config.extensions) { [void]$trackedExtensions.Add($ext) }

    $processDep = {
        param($depRaw)
        if ($depRaw.ToLower().StartsWith("vscode.")) { return }
        $dep = if ($dependencyAliases.ContainsKey($depRaw)) { $dependencyAliases[$depRaw] } else { $depRaw }
        $depName = ($dep -split '\.')[1].ToLower()
        $depPackageName = if ($depName.StartsWith("vscode-")) { $depName } else { "vscode-$depName" }

        if ($depPackageName -ne $PackageName) {
            [void]$depsNode.AppendChild($NuspecXml.CreateSignificantWhitespace("`n      "))
            $depNode = $NuspecXml.CreateElement("dependency", $ns)
            $depNode.SetAttribute("id", $depPackageName)
            [void]$depsNode.AppendChild($depNode)

            if (-not $trackedExtensions.Contains($dep)) {
                Write-Magenta "    [AUTO-DISCOVERY] Queuing missing dependency via Factory: $dep"
                $factoryPath = Join-Path $script:ProjectRoot "bin\Manage-ExtensionPool.ps1"
                & $factoryPath -Add $dep
                [void]$trackedExtensions.Add($dep)
                $global:au_RequiresSecondRun = $true
            }
        }
    }

    if ($PackageJson.extensionDependencies) {
        foreach ($depRaw in $PackageJson.extensionDependencies) { & $processDep $depRaw }
    }
    if ($PackageJson.extensionPack) {
        foreach ($depRaw in $PackageJson.extensionPack) { & $processDep $depRaw }
    }

    [void]$depsNode.AppendChild($NuspecXml.CreateSignificantWhitespace("`n    "))
}

