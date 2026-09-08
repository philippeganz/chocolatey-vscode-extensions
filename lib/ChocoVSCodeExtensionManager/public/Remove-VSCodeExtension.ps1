<#
.SYNOPSIS
    The Execution Engine for safely removing VS Code extensions from the local pool.

.DESCRIPTION
    A highly robust, stateless PowerShell function designed to surgically remove extensions
    from the target ecosystem. It performs reverse-lookups on extension IDs, strictly validates
    local dependency trees to prevent the creation of orphaned packages, safely deletes the
    scaffolded directories, and updates the `extensions.json` state tracker.

    [Dependency Protection]
    By default, the Shredder will refuse to delete a package if it parses local `.nuspec`
    files and discovers that another extension in the pool explicitly requires it.

    [Shared Ownership Protection]
    Prevents the deletion of a package directory if multiple different extension IDs in the
    `extensions.json` state file resolve to the exact same Chocolatey package name.

.PARAMETER ExtensionId
    An array of extension identifiers or package names to cleanly remove from the pool.

.PARAMETER StatePath
    The absolute path to the main `extensions.json` state file used to track dependency graphs.

.PARAMETER AutomaticDir
    The absolute path to the target automatic directory where the generated packages reside.

.PARAMETER Force
    If specified, aggressively overrides the dependency protection mechanism and deletes
    the package even if it is actively required by other extensions.

.EXAMPLE
    Remove-VSCodeExtension -ExtensionId "ms-python.python" -StatePath "C:\var\state\extensions.json" -AutomaticDir "C:\git\automatic"

.INPUTS
    [System.String[]]
    Accepts pipeline input for ExtensionId by value.

.OUTPUTS
    None
#>
function Remove-VSCodeExtension {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ExtensionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $StatePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $AutomaticDir,

        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )

    begin {
        $ErrorActionPreference = 'Stop'
        $mutated = $false
        $stateArray = Get-ChocoVSCodeExtensionState -StatePath $StatePath
        $stateList = [System.Collections.Generic.List[string]]::new()
        if ($stateArray) { $stateList.AddRange([string[]]$stateArray) }
    }

    process {
        Write-Info "Extensions to Process: $($ExtensionId.Count)" -Indent 1

        $removePackageNames = [System.Collections.Generic.List[string]]::new()
        $removeIds = [System.Collections.Generic.List[string]]::new()

        foreach ($id in $ExtensionId) {
            $cleanId = $id.ToLower()
            if (-not $cleanId.Contains('.')) {
                $matchedExtId = $null
                foreach ($trackedId in $stateList) {
                    if ((Get-ChocoVSCodePackageName -ExtensionId $trackedId) -eq $cleanId) {
                        $matchedExtId = $trackedId
                        break
                    }
                }
                if ($matchedExtId) {
                    Write-Info "Reverse lookup resolved '$cleanId' to extension ID '$matchedExtId'."
                    $cleanId = $matchedExtId
                }
            }
            $removeIds.Add($cleanId)
            $pkgName = Get-ChocoVSCodePackageName -ExtensionId $cleanId
            if ($pkgName) {
                if (-not $PSCmdlet.ShouldProcess($cleanId, "Shred VSCode Extension")) {
                    continue
                } $removePackageNames.Add($pkgName)
            }
        }

        foreach ($cleanId in $removeIds) {
            Write-StyledMessage -Message "
----------------------------------------" -Color DarkGray
            Write-StyledMessage -Message "Shredding: $cleanId" -Color Cyan
            $pkgName = Get-ChocoVSCodePackageName -ExtensionId $cleanId
            if ($pkgName) {
                if (-not $PSCmdlet.ShouldProcess($cleanId, "Shred VSCode Extension")) {
                    continue
                }
                $pkgDir = Join-Path $AutomaticDir $pkgName

                $isDependency = $false
                $dependents = [System.Collections.Generic.List[string]]::new()

                if (Test-Path $AutomaticDir) {
                    $allNuspecs = Get-ChildItem -Path $AutomaticDir -Filter "*.nuspec" -Recurse
                    foreach ($nuspec in $allNuspecs) {
                        $nuspecPkgName = $nuspec.Directory.Name
                        if ($removePackageNames.Contains($nuspecPkgName)) { continue }

                        $xml = [System.Xml.XmlDocument]::new()
                        $xml.Load($nuspec.FullName)

                        $deps = $xml.package.metadata.dependencies.dependency
                        if ($deps) {
                            foreach ($dep in @($deps)) {
                                if ($dep.id -eq $pkgName) {
                                    $isDependency = $true
                                    $dependents.Add($nuspecPkgName)
                                }
                            }
                        }
                    }
                }

                if ($isDependency -and -not $Force) {
                    Write-Err "Cannot safely remove '$cleanId'. It is declared as a dependency by: $($dependents -join ', ')."
                    Write-Err "Use -Force to override this protection."
                    continue
                }
                elseif ($isDependency -and $Force) {
                    Write-Warn "Overriding dependency protection! Removing '$cleanId' despite being required by: $($dependents -join ', ')." -Indent 1
                }

                if ($stateList.Contains($cleanId)) {
                    [void]$stateList.Remove($cleanId)
                    $mutated = $true
                    Write-Success "Removed '$cleanId' from state tracking."
                }
                else {
                    Write-Skip "'$cleanId' was not found in state tracking."
                }

                if (Test-Path $pkgDir) {
                    $sharedOwners = $stateList | Where-Object { (Get-ChocoVSCodePackageName -ExtensionId $_) -eq $pkgName }
                    if ($sharedOwners.Count -gt 0) {
                        Write-Warn "Skipping directory deletion for '$pkgName'. It is still owned by: $($sharedOwners -join ', ')." -Indent 1
                    }
                    else {
                        $maxRetries = 3
                        $retryCount = 0
                        $removed = $false
                        while (-not $removed -and $retryCount -lt $maxRetries) {
                            try {
                                Remove-Item -Path $pkgDir -Recurse -Force -ErrorAction Stop
                                $removed = $true
                            }
                            catch {
                                $retryCount++
                                if ($retryCount -lt $maxRetries) {
                                    Start-Sleep -Milliseconds 500
                                }
                                else {
                                    throw $_
                                }
                            }
                        }
                        Write-Success "Deleted local package directory: $pkgName"
                    }
                }
            }
        }
    }

    end {
        if ($mutated) {
            Write-StyledMessage -Message "
>>> Finalizing and Syncing state..." -Color Cyan
            Save-ChocoVSCodeExtensionState -StatePath $StatePath -ExtensionsList $stateList.ToArray()
        }
        Write-StyledMessage -Message "
>>> Shredder Run Complete!" -Color Cyan
    }

}


