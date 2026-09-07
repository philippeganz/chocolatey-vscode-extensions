#Requires -Version 7.0
<#
.SYNOPSIS
    Automated Chocolatey Package Factory for Visual Studio Code Extensions.
.DESCRIPTION
    A highly robust PowerShell script that automates the scaffolding of Chocolatey packages
    for Visual Studio Code extensions. It queries the VS Code Marketplace API to extract
    metadata, payload URLs, and dependency graphs.
    This Factory is designed for enterprise air-gapped compliance. It extracts the embedded
    README and LICENSE files directly from the `.vsix` archive and ensures the generated
    `.nuspec` natively maps the Chocolatey dependencies correctly.
    [Smart Versioning]
    If the Factory is regenerating an existing package, it safely preserves the current
    version in the `.nuspec` instead of resetting it to 0.0.0, preventing CI pipeline collisions.
    [Auto-Discovery Engine]
    The Factory recursively parses internal `extensionDependencies` and `extensionPacks`.
    If it discovers dependencies that are not currently tracked in the `config.yaml` state file,
    it returns them to the caller (Orchestrator) for recursive queuing and tracking.
.PARAMETER ExtensionId
    The exact unique identifier of the extension from the VS Code Marketplace
    (e.g., 'ms-python.python'). The Factory scaffolds this single package.
.PARAMETER Force
    If specified, completely nukes the existing package directory in 'automatic/'
    and forces a clean regeneration of all templates. Resets the version to 0.0.0.
.EXAMPLE
    .\Add-VSCodeExtension.ps1 -ExtensionId "ms-python.python"
.EXAMPLE
    .\Add-VSCodeExtension.ps1 -ExtensionId "ms-python.python" -Force
.INPUTS
    [System.String]
    Does not accept pipeline input.
.OUTPUTS
    None
.NOTES
    The script relies on `VsCodeMarketplace.psm1` for handling all API requests to Microsoft.
    It generates an `automatic/$ExtensionId` directory fully populated with the required AU scaffolding.
#>
function Add-VSCodeExtension {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$ExtensionId,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$StatePath,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$AutomaticDir,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$TemplatesDir,
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    # =============================================================================
    # Global Error Handling
    # =============================================================================
    # Enforce strict fail-fast behavior across this entire script/module.
    # Any cmdlet or module import failure will immediately throw a terminating error.
    # Override locally with -ErrorAction SilentlyContinue when needed.
    $ErrorActionPreference = 'Stop'
    # Load the .NET Compression framework into the AppDomain to enable [System.IO.Compression.ZipFile] for parsing VSIX archive streams.
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    # Factory only outputs to the automatic/ directory at the root
    $OutputDir = $AutomaticDir
    if (-not (Test-Path $OutputDir)) {
        [void](New-Item -ItemType Directory -Force -Path $OutputDir)
    }
    $extId = $ExtensionId.ToLower()
    $missingDepsOutput = [System.Collections.Generic.List[string]]::new()
    Write-StyledMessage -Color Cyan -Message ">>> Starting VS Code Extension Factory"
    Write-StyledMessage -Color White -Message "    Target Output Directory: $OutputDir"
    Write-StyledMessage -Color Cyan -Message "`n================================================================================"
    Write-StyledMessage -Color Cyan -Message " PROCESSING: $extId"
    Write-StyledMessage -Color Cyan -Message "================================================================================`n"
    $parts = $extId -split '\.'
    if ($parts.Count -ne 2) {
        throw "    [ERROR] Invalid ExtensionId format ($extId)."
    }
    $publisher = $parts[0]
    $extensionName = $parts[1]
    $packageName = Get-ChocoVSCodePackageName -ExtensionId $ExtensionId
    $pkgDir = Join-Path $OutputDir $packageName
    if (Test-Path $pkgDir) {
        if ($Force) {
            Write-Info "Package folder exists. -Force is set. Regenerating..." -Indent 1
            Remove-Item -Path $pkgDir -Recurse -Force
        }
        else {
            Write-Skip "Package folder already exists ($packageName). Skipping. Use -Force to regenerate." -Indent 1
            return
        }
    }
    # =============================================================================
    # 2. Query VS Code Marketplace API
    # =============================================================================
    # We query the official marketplace API to fetch the absolute latest metadata
    # about this extension. This metadata drives everything: versioning, payloads,
    # dependencies, and asset resolution.
    try {
        $extMeta = Get-VsCodeMarketplaceMetadata -Publisher $publisher -ExtensionName $extensionName
    }
    catch {
        Write-Err "$_" -Indent 1
        throw "$_"
    }
    $version = $extMeta.versions[0].version
    $versionClean = $version -replace '[^\d\.-]', ''
    Write-StyledMessage -Color White -Message "Version: $versionClean" -Indent 1
    # Scaffold Package Directory and Tools subfolder
    if (-not (Test-Path $pkgDir)) {
        [void](New-Item -ItemType Directory -Force -Path $pkgDir)
    }
    $toolsDir = Join-Path $pkgDir "tools"
    if (-not (Test-Path $toolsDir)) {
        [void](New-Item -ItemType Directory -Force -Path $toolsDir)
    }
    # =============================================================================
    # 3. Payload Resolution & Download
    # =============================================================================
    # Fetch the raw VSIX package and extension icon. We compute the exact download URL
    # dynamically because target platforms (e.g., win32-x64) require specific URLs.
    $vsixUrl = Get-VsCodeExtensionUrl -Publisher $publisher -ExtensionName $extensionName -Version $version -ExtMeta $extMeta
    $vsixName = "$publisher.$extensionName-$versionClean.vsix"
    $vsixPath = Join-Path $toolsDir $vsixName
    # Download icon if it doesn't exist
    $iconUrl = $null
    if ($extMeta.versions[0].files | Where-Object { $_.assetType -eq "Microsoft.VisualStudio.Services.Icons.Default" }) {
        $iconUrl = ($extMeta.versions[0].files | Where-Object { $_.assetType -eq "Microsoft.VisualStudio.Services.Icons.Default" }).source
    }
    Save-VsCodeIcon -IconUrl $iconUrl -PackageDir $pkgDir -PackageName $packageName
    Invoke-RobustDownload -Url $vsixUrl -OutFile $vsixPath
    # =============================================================================
    # 4. Generate VERIFICATION.txt (Chocolatey Compliance)
    # =============================================================================
    # Chocolatey explicitly requires a VERIFICATION.txt file for binaries fetched at
    # packaging time to prove to moderators that the source is authentic.
    New-VerificationFile -VsixPath $vsixPath -PackageDir $pkgDir -Publisher $publisher -ExtensionName $extensionName
    # =========================================================================
    # 5. Payload Extraction (Air-Gap Compliance)
    # =========================================================================
    $payloadResult = Expand-VsCodePayload -VsixPath $vsixPath -DestinationDir $pkgDir
    $packageJson = $payloadResult.PackageJson
    # =========================================================================
    # 6. Security Validation
    # =========================================================================
    # We scan the raw binary payload to look for forbidden runtime commands
    # that might attempt to break out of an offline/air-gapped network.
    Write-StyledMessage -Color White -Message "Deep Scanning VSIX for Network Triggers..." -Indent 1
    $dangerousMatches = Select-String -Path "$vsixPath" -Pattern "(wget\s|curl\s|Invoke-WebRequest|npm install|pip install)" -Quiet
    if ($dangerousMatches) {
        Write-Warn "Potential runtime network triggers found in VSIX payload!" -Indent 1
    }
    # =========================================================================
    # 7. Template Rendering & Dependency Discovery
    # =========================================================================
    # We take the static scaffolding templates from etc/templates and inject
    # the dynamically resolved metadata to finalize the AU package structure.
    Write-StyledMessage -Color White -Message "Rendering AU Templates..." -Indent 1
    $templatesDir = $TemplatesDir
    $nuspecPath = Join-Path $pkgDir "$packageName.nuspec"
    $meta = Get-VsCodeNuspecMetadata -ExtMeta $extMeta -ExtensionPublisher $publisher -ExtensionName $extensionName
    $nuspecContent = Get-Content (Join-Path $templatesDir "template.nuspec") -Raw -Encoding UTF8
    $nuspecContent = Update-VsCodeNuspecMetadata -NuspecContent $nuspecContent -Meta $meta
    $targetVersion = '0.0.0'
    if (Test-Path $nuspecPath) {
        try {
            $existingXml = [xml](Get-Content $nuspecPath -Raw)
            if ($existingXml.package.metadata.version) {
                $targetVersion = $existingXml.package.metadata.version
                Write-Verbose "    Smart Versioning: Preserved existing version $targetVersion"
            }
        }
        catch {
            Write-Warn "Failed to parse existing nuspec version. Defaulting to 0.0.0" -Indent 1
        }
    }
    $nuspecContent = $nuspecContent -replace '\{\{ExtensionNameLowerCase\}\}', $packageName.Replace("vscode-", "")
    $nuspecContent = $nuspecContent -replace '\{\{Version\}\}', $targetVersion
    $nuspecContent = $nuspecContent -replace '\{\{IconUrl\}\}', "https://cdn.jsdelivr.net/gh/philippeganz/chocolatey-vscode-extensions@main/automatic/$packageName/icon.png"
    $nuspecContent = $nuspecContent -replace '\{\{Dependencies\}\}', ''
    $nuspecXml = [xml]$nuspecContent
    Update-NuspecCDataDescription -NuspecXml $nuspecXml -CDataSafeReadme $payloadResult.CDataSafeReadme -ShortDescription $extMeta.shortDescription
    $newDeps = Update-NuspecDependency -NuspecXml $nuspecXml -PackageJson $packageJson -PackageName $packageName -StatePath $StatePath
    if ($newDeps) {
        foreach ($d in $newDeps) {
            $dLower = $d.ToLower()
            if (-not $missingDepsOutput.Contains($dLower)) {
                $missingDepsOutput.Add($dLower)
            }
        }
    }
    Save-NuspecXml -NuspecXml $nuspecXml -NuspecPath $nuspecPath
    if (-not (Test-Path (Join-Path $toolsDir "chocolateyInstall.ps1"))) {
        $installContent = Get-Content (Join-Path $templatesDir "chocolateyInstall.ps1") -Raw -Encoding UTF8
        $installContent = $installContent -replace '\{\{Publisher\}\}', $publisher
        $installContent = $installContent -replace '\{\{ExtensionName\}\}', $extensionName
        $installContent = $installContent -replace '\{\{Version\}\}', $versionClean
        $installContent = $installContent.Replace("`r`n", "`n")
        [System.IO.File]::WriteAllText((Join-Path $toolsDir "chocolateyInstall.ps1"), $installContent, [System.Text.UTF8Encoding]::new($false))
    }
    if (-not (Test-Path (Join-Path $toolsDir "chocolateyUninstall.ps1"))) {
        $uninstallContent = Get-Content (Join-Path $templatesDir "chocolateyUninstall.ps1") -Raw -Encoding UTF8
        $uninstallContent = $uninstallContent -replace '\{\{Publisher\}\}', $publisher
        $uninstallContent = $uninstallContent -replace '\{\{ExtensionName\}\}', $extensionName
        $uninstallContent = $uninstallContent.Replace("`r`n", "`n")
        [System.IO.File]::WriteAllText((Join-Path $toolsDir "chocolateyUninstall.ps1"), $uninstallContent, [System.Text.UTF8Encoding]::new($false))
    }
    if (-not (Test-Path (Join-Path $pkgDir "update.ps1"))) {
        $updateContent = @"
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
  `$global:ExtensionPublisher = "$publisher"
  `$global:ExtensionName = "$extensionName"
. "`$PSScriptRoot\..\..\lib\AuExtensionHooks\Invoke-AuUpdateTrigger.ps1"
"@
        $updateContent = $updateContent.Replace("`r`n", "`n")
        [System.IO.File]::WriteAllText((Join-Path $pkgDir "update.ps1"), $updateContent, [System.Text.UTF8Encoding]::new($false))
    }
    Write-Success "Scaffolded at: $pkgDir" -Indent 1
    Write-StyledMessage -Color Cyan -Message "`n>>> Factory Run Complete!"
    if ($missingDepsOutput.Count -gt 0) {
        Write-Output $missingDepsOutput.ToArray()
    }

}
