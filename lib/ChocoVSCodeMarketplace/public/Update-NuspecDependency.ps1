<#
.SYNOPSIS
    Dynamically updates the Chocolatey .nuspec XML to append discovered extension dependencies.

.DESCRIPTION
    Scans the raw package.json of a VS Code extension for internal extensionDependencies or extensionPack arrays.
    It maps these dependencies to their Chocolatey package equivalents, appends them to the <dependencies> block of the .nuspec, and auto-queues missing ones to the Factory.

.PARAMETER NuspecXml
    An [xml] object representing the parsed .nuspec file.

.PARAMETER PackageJson
    A JSON object representing the parsed package.json from the extension payload.

.PARAMETER PackageName
    The canonical Chocolatey package name currently being processed.

.PARAMETER StatePath
    The absolute path to the extensions.yaml tracker.

.EXAMPLE
    Update-NuspecDependency -NuspecXml $xml -PackageJson $json -PackageName "vscode-python" -StatePath "C:\var\state\extensions.yaml"

.INPUTS
    None

.OUTPUTS
    [System.Collections.Generic.List[string]]
    A list of newly discovered dependency identifiers.

.NOTES
    Mutates the passed XML object in memory. Prevents cyclic dependency loops natively.
#>
function Update-NuspecDependency {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.Collections.Generic.List[string]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]
        $NuspecXml,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]
        $PackageJson,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $PackageName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $StatePath
    )

    $missingDeps = [System.Collections.Generic.List[string]]::new()

    if (-not $PSCmdlet.ShouldProcess("Nuspec XML for $PackageName", "Update Dependencies")) {
        return $missingDeps
    }

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

    [void]$depsNode.AppendChild($NuspecXml.CreateSignificantWhitespace("
      "))
    $baseDep = $NuspecXml.CreateElement("dependency", $ns)
    $baseDep.SetAttribute("id", "chocolatey-vscode.extension")
    $baseDep.SetAttribute("version", "[1.1.0, 2.0.0)")
    [void]$depsNode.AppendChild($baseDep)

    $config = Get-ChocoVSCodeExtensionState -StatePath $StatePath
    $trackedExtensions = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($ext in $config) { [void]$trackedExtensions.Add($ext) }

    $processDep = {
        param($depRaw)
        if ($depRaw.ToLower().StartsWith("vscode.")) { return }
        $dep = if ($dependencyAliases.ContainsKey($depRaw)) { $dependencyAliases[$depRaw] } else { $depRaw }
        $depName = ($dep -split '\.')[1].ToLower()
        $depPackageName = if ($depName.StartsWith("vscode-")) { $depName } else { "vscode-$depName" }

        if ($depPackageName -ne $PackageName) {
            [void]$depsNode.AppendChild($NuspecXml.CreateSignificantWhitespace("
      "))
            $depNode = $NuspecXml.CreateElement("dependency", $ns)
            $depNode.SetAttribute("id", $depPackageName)
            [void]$depsNode.AppendChild($depNode)

            if (-not $trackedExtensions.Contains($dep)) {
                Write-Info "[AUTO-DISCOVERY] Discovered untracked dependency: $dep"
                $missingDeps.Add($dep)
                [void]$trackedExtensions.Add($dep)
            }
        }
    }

    if ($PackageJson.extensionDependencies) {
        foreach ($depRaw in $PackageJson.extensionDependencies) { & $processDep $depRaw }
    }
    if ($PackageJson.extensionPack) {
        foreach ($depRaw in $PackageJson.extensionPack) { & $processDep $depRaw }
    }

    [void]$depsNode.AppendChild($NuspecXml.CreateSignificantWhitespace("
    "))

    return $missingDeps
}
