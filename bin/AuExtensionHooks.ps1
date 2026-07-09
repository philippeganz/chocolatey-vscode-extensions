[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
<#
.SYNOPSIS
    The centralized Logic Engine for Chocolatey AU packages.

.DESCRIPTION
    Instead of maintaining massive 100-line update.ps1 scripts in every package folder,
    all packages use a tiny 3-line stub that dot-sources this file. This script injects
    the global AU hooks (au_GetLatest, au_BeforeUpdate) into the runtime context so AU
    knows how to update the package.
#>
param()

Import-Module au
Import-Module "$PSScriptRoot\VsCodeMarketplace.psm1" -Global -Force -ErrorAction Stop

# We bypass the registry checks since these are portable VS Code extensions.
# Push settings are natively inherited from the global orchestrator.
$au_NoCheckRegistry = $true


# -----------------------------------------------------------------------------
# au_GetLatest: The Metadata Resolver
#
# AU executes this function every 6 hours. We send a raw REST API POST request
# to the Visual Studio Code Marketplace to query the absolute latest version
# of the extension.
# -----------------------------------------------------------------------------
function global:au_GetLatest {
    $ext = Get-VsCodeMarketplaceMetadata -Publisher $ExtensionPublisher -ExtensionName $ExtensionName

    $version = $ext.versions[0].version
    # Simple SemVer sanitization
    $version = $version -replace '[^\d\.-]', ''

    $vsixUrl = Get-VsCodeExtensionUrl -Publisher $ExtensionPublisher -ExtensionName $ExtensionName -Version $version -ExtMeta $ext
    $iconUrl = $ext.versions[0].files | Where-Object { $_.assetType -eq "Microsoft.VisualStudio.Services.Icons.Default" } | Select-Object -ExpandProperty source

    return @{
        Version = $version
        URL32   = $vsixUrl
        URL64   = $vsixUrl
        IconUrl = $iconUrl
    }
}

# -----------------------------------------------------------------------------
# au_BeforeUpdate: The Payload Downloader
#
# If AU detects that the version returned by au_GetLatest is newer than the
# current package (or is forced), it triggers this hook to download the new binaries.
# -----------------------------------------------------------------------------
function global:au_BeforeUpdate {
    param($package)

    # Intelligent CI Bootstrapper: Only install VS Code test dependencies if an update is actively happening
    if (-not (Get-Command code -ErrorAction SilentlyContinue) -and -not $global:VsCodeDependenciesLoaded) {
        Write-Host ">>> Pre-loading Test Dependencies for CI Environment..." -ForegroundColor Cyan
        choco install vscode chocolatey-vscode.extension -y --no-progress
        $global:VsCodeDependenciesLoaded = $true
    }

    $toolsDir = Join-Path $package.Path 'tools'
    if (-not (Test-Path $toolsDir)) { New-Item -ItemType Directory -Path $toolsDir | Out-Null }

    $vsixPath = Join-Path $toolsDir "$ExtensionPublisher.$ExtensionName-$($Latest.Version).vsix"

    # Purge any old VSIX payloads to prevent package bloat
    Get-ChildItem -Path $toolsDir -Filter "*.vsix" | Remove-Item -Force

    # Download the new payload
    Invoke-RobustDownload -Url $Latest.URL64 -OutFile $vsixPath

    # Automatically extract the newest README.md and LICENSE from the ZIP payload
    # so AU can natively inject the updated documentation into the Chocolatey package.
    $payloadResult = Expand-VsCodePayload -VsixPath $vsixPath -DestinationDir $package.Path

    # Inject the semantically truncated CDATA description into the nuspec
    if ($payloadResult.TruncatedReadme) {
        $cdataSafe = $payloadResult.TruncatedReadme -replace '\]\]>', ']]]]><![CDATA[>'
        
        # Update AU's in-memory XML DOM so it doesn't overwrite our changes later
        if ($package -and $package.NuspecXml) {
            $descNode = $package.NuspecXml.SelectSingleNode("//*[local-name()='description']")
            if ($descNode) {
                $descNode.RemoveAll()
                $cdata = $package.NuspecXml.CreateCDataSection("`n" + $cdataSafe + "`n")
                $descNode.AppendChild($cdata) | Out-Null
            }
        }

        # Update the physical file on disk for immediate tools
        $descriptionEscaped = "<![CDATA[`n" + $cdataSafe + "`n]]>"
        $nuspecPath = Join-Path $package.Path "$($package.Name).nuspec"
        if (Test-Path $nuspecPath) {
            $nuspecContent = Get-Content $nuspecPath -Raw -Encoding UTF8
            $nuspecContent = $nuspecContent -replace '(?is)<description>.*?</description>', "<description>$descriptionEscaped</description>"
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($nuspecPath, $nuspecContent, $utf8NoBom)
        }
    }
}

# -----------------------------------------------------------------------------
# au_SearchReplace: The String Replacer
#
# AU executes this function to natively update the hardcoded version strings
# inside our scripts (like chocolateyInstall.ps1) so the new binaries are used.
# -----------------------------------------------------------------------------
function global:au_SearchReplace {
    # We conditionally build the replacement rules so we don't accidentally write empty icon URLs if the extension lacks one
    $rules = @{
        "tools\chocolateyInstall.ps1" = @{
            "(?i)($ExtensionPublisher\.$ExtensionName-)[\d\.]+(\.vsix)" = "`${1}$($Latest.Version)`${2}"
        }
    }

    if ($Latest.IconUrl) {
        $rules["*.nuspec"] = @{
            "(?is)<iconUrl>.*?</iconUrl>" = "<iconUrl>$($Latest.IconUrl)</iconUrl>"
        }
    }

    return $rules
}

update -ChecksumFor none
