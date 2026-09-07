<#
.SYNOPSIS
    The Payload Downloader hook for Chocolatey AU.

.DESCRIPTION
    If AU detects that the version returned by au_GetLatest is newer than the
    current package (or is forced), it triggers this hook. This downloads the actual
    VSIX binary, extracts the metadata and LICENSE, dynamically injects dependencies,
    and algorithmically truncates the README to update the nuspec.

    This function is strictly responsible for fulfilling the Air-Gap mandate by
    physically embedding the upstream .vsix payload into the package directory.

.PARAMETER package
    The AU package object representing the current context, containing properties like
    Path, Name, and NuspecXml.

.EXAMPLE
    # This function is not meant to be called directly. It is invoked natively by AU.

.INPUTS
    [System.Management.Automation.PSCustomObject]

.OUTPUTS
    None

.NOTES
    It utilizes the `$Latest` global variable injected by AU to access metadata returned
    by `au_GetLatest`.
#>
function global:au_BeforeUpdate {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for AU Engine state')]
    param($package)


    $toolsDir = Join-Path $package.Path 'tools'
    if (-not (Test-Path $toolsDir)) { [void](New-Item -ItemType Directory -Path $toolsDir) }

    $vsixPath = Join-Path $toolsDir "$global:ExtensionPublisher.$global:ExtensionName-$($Latest.Version).vsix"

    # =========================================================================
    # Step 1. Download and Verify Payload (Air-Gap Mandate)
    # =========================================================================
    # Purge any old VSIX payloads to prevent package bloat
    Get-ChildItem -Path $toolsDir -Filter "*.vsix" | Remove-Item -Force

    # Download the new upstream VSIX payload directly into the tools folder
    Invoke-RobustDownload -Url $Latest.URL64 -OutFile $vsixPath

    # Compute checksums and generate the VERIFICATION.txt file required by Chocolatey
    New-VerificationFile -VsixPath $vsixPath -PackageDir $package.Path -Publisher $global:ExtensionPublisher -ExtensionName $global:ExtensionName

    # =========================================================================
    # Step 2. Extract Payload Metadata
    # =========================================================================
    # Automatically rip the newest README.md, LICENSE, and package.json from the ZIP payload
    # so AU can natively inject the updated documentation into the Chocolatey package.
    $payloadResult = Expand-VsCodePayload -VsixPath $vsixPath -DestinationDir $package.Path

    # =========================================================================
    # Step 3. Update In-Memory String (Pre-DOM)
    # =========================================================================
    # Update the raw text template with Title, Authors, Summary, etc. via regex
    # before converting to a native XML DOM object.
    $nuspecPath = Join-Path $package.Path "$($package.Name).nuspec"
    $nuspecContent = Get-Content $nuspecPath -Raw -Encoding UTF8
    $meta = Get-VsCodeNuspecMetadata -ExtMeta $Latest.RawMeta -ExtensionPublisher $global:ExtensionPublisher -ExtensionName $global:ExtensionName
    $nuspecContent = Update-VsCodeNuspecMetadata -NuspecContent $nuspecContent -Meta $meta
    $package.NuspecXml = [xml]$nuspecContent

    # =========================================================================
    # Step 4. Update XML DOM (AU State) & Physical Templates
    # =========================================================================
    # We must inject the CDataSafeReadme natively as a pure CDataSection
    # so that PowerShell's XML parser doesn't incorrectly escape the payload when saving.
    Update-NuspecCDataDescription -NuspecXml $package.NuspecXml -CDataSafeReadme $payloadResult.CDataSafeReadme -ShortDescription $Latest.RawMeta.shortDescription

    $workspace = $env:CHOCO_VSCODE_WORKSPACE_ROOT ?? (Resolve-Path "$PSScriptRoot\..").Path
    $StatePath = "$workspace\var\state\extensions.yaml"
    $packageName = $package.Name
    $newDeps = Update-NuspecDependency -NuspecXml $package.NuspecXml -PackageJson $payloadResult.PackageJson -PackageName $packageName -StatePath $StatePath

    if ($newDeps) {
        Write-StyledMessage -Color Magenta -Message "    [AU] Missing dependencies detected: $($newDeps -join ', ')"

        # --------------------------------------------------------------------------------
        # Dependency DAG Resolution (AU Mode)
        # --------------------------------------------------------------------------------
        # When AU processes an update for an extension, it evaluates the DAG strictly before
        # starting the updates. If this package suddenly introduces a new dependency that we
        # do not track yet, AU cannot dynamically inject it into the currently running DAG.
        #
        # Strategy:
        # 1. We spawn the Orchestrator to natively scaffold the missing packages into the pool.
        # 2. We intentionally throw a terminating error to fail the parent package update!
        # 3. This guarantees we never push a parent package to Chocolatey before its dependencies.
        # 4. On the NEXT cron run, AU will push the scaffolded dependencies first, then the parent.
        # --------------------------------------------------------------------------------

        $orchestratorPath = Join-Path $workspace "bin\Manage-ExtensionPool.ps1"
        Write-Info "Spawning Orchestrator to scaffold untracked dependencies..."
        Start-Process pwsh -ArgumentList "-NoProfile -NonInteractive -File `"$orchestratorPath`" -Add $($newDeps -join ',')" -NoNewWindow -Wait

        throw "Failing AU Update for $packageName to preserve DAG integrity. Untracked dependencies were successfully scaffolded and will be processed on the next execution cycle."
    }

    Save-NuspecXml -NuspecXml $package.NuspecXml -NuspecPath $nuspecPath

    # =========================================================================
    # Step 5. Validate Required Assets
    # =========================================================================
    # Guarantee icon.png exists to prevent choco pack validation failures (every nuspec includes icon.png in <files>)
    Save-VsCodeIcon -IconUrl $Latest.MarketplaceIconUrl -PackageDir $package.Path -PackageName $package.Name

    # Temporarily hide README.md so AU doesn't dynamically inject it into the nuspec description
    # and bypass our 4000-character truncation logic. We restore it in au_AfterUpdate.
    $readmePath = Join-Path $package.Path "README.md"
    $hiddenReadmePath = Join-Path $package.Path "README.md.bak"
    if (Test-Path $readmePath) {
        Move-Item $readmePath $hiddenReadmePath -Force
    }
}
