[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
param()

Import-Module au

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
    $marketplaceUrl = "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"

    # The Marketplace requires a highly specific, undocumented payload to query extensions.
    $body = @{
        filters = @(
            @{
                criteria   = @(
                    @{ filterType = 7; value = "vmware.vscode-spring-boot" }
                )
                pageNumber = 1
                pageSize   = 1
            }
        )
        flags   = 914
    } | ConvertTo-Json -Depth 10

    $headers = @{
        "Accept"       = "application/json;api-version=3.0-preview.1"
        "Content-Type" = "application/json"
    }

    $retryCount = 0
    $success = $false
    $res = $null

    while (-not $success -and $retryCount -lt 5) {
        try {
            $res = Invoke-RestMethod -Uri $marketplaceUrl -Method Post -Body $body -Headers $headers -ErrorAction Stop
            $success = $true
        } catch {
            Write-Host "    [WARNING] VS Code Marketplace API failed (Rate Limit/Network). Retrying in 5 seconds..." -ForegroundColor Yellow
            $retryCount++
            if ($retryCount -ge 5) { throw $_ }
            Start-Sleep -Seconds 5
        }
    }

    $ext = $res.results[0].extensions[0]

    if (-not $ext) { throw "Extension not found on Marketplace" }

    $version = $ext.versions[0].version
    # Simple SemVer sanitization
    $version = $version -replace '[^\d\.-]', ''

    # Construct the direct download URL for the .vsix payload.
    $vsixUrl = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/vmware/vsextensions/vscode-spring-boot/$version/vspackage"

    return @{
        Version = $version
        URL32   = $vsixUrl
        URL64   = $vsixUrl
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
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Write-Host ">>> Pre-loading Test Dependencies for CI Environment..." -ForegroundColor Cyan
        choco install vscode chocolatey-vscode.extension -y --no-progress
    }

    $toolsDir = Join-Path $package.Path 'tools'
    if (-not (Test-Path $toolsDir)) { New-Item -ItemType Directory -Path $toolsDir | Out-Null }

    $vsixPath = Join-Path $toolsDir "vmware.vscode-spring-boot-$($Latest.Version).vsix"

    # Purge any old VSIX payloads to prevent package bloat
    Get-ChildItem -Path $toolsDir -Filter "*.vsix" | Remove-Item -Force

    # Download the new payload
    $retryCount = 0
    $success = $false
    while (-not $success -and $retryCount -lt 3) {
        try {
            Invoke-WebRequest -Uri $Latest.URL64 -OutFile $vsixPath -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -ErrorAction Stop
            $success = $true
        } catch {
            Write-Host "    [WARNING] Download failed. Retrying in 5 seconds..." -ForegroundColor Yellow
            $retryCount++
            if ($retryCount -ge 3) { throw }
            Start-Sleep -Seconds 5
        }
    }

    # The actual factory will inject VSIX extraction logic here later
    # to crack the zip and update README/LICENSE/package.json
}

# -----------------------------------------------------------------------------
# au_SearchReplace: The String Replacer
#
# AU executes this function to natively update the hardcoded version strings
# inside our scripts (like chocolateyInstall.ps1) so the new binaries are used.
# -----------------------------------------------------------------------------
function global:au_SearchReplace {
    @{
        "tools\chocolateyInstall.ps1" = @{
            "(?i)(vmware\.vscode-spring-boot-)[\d\.]+(\.vsix)" = "`${1}$($Latest.Version)`${2}"
        }
    }
}

update -ChecksumFor none
