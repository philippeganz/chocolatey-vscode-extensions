[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

Import-Module au

$au_NoCheckRegistry = $true
$au_Push = $false

function global:au_GetLatest {
    $marketplaceUrl = "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
    $body = @{
        filters = @(
            @{
                criteria   = @(
                    @{ filterType = 7; value = "{{Publisher}}.{{ExtensionName}}" }
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

    $res = Invoke-RestMethod -Uri $marketplaceUrl -Method Post -Body $body -Headers $headers
    $ext = $res.results[0].extensions[0]
    
    if (-not $ext) { throw "Extension not found on Marketplace" }

    $version = $ext.versions[0].version
    # Simple SemVer sanitization
    $version = $version -replace '[^\d\.-]', ''

    # Download URL for the vsix
    $vsixUrl = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/{{Publisher}}/vsextensions/{{ExtensionName}}/$version/vspackage"

    return @{
        Version = $version
        URL32   = $vsixUrl
        URL64   = $vsixUrl
    }
}

function global:au_UpdatePackage {
    param($Latest)
    
    $toolsDir = Join-Path $PSScriptRoot 'tools'
    if (-not (Test-Path $toolsDir)) { New-Item -ItemType Directory -Path $toolsDir | Out-Null }
    
    $vsixPath = Join-Path $toolsDir "{{Publisher}}.{{ExtensionName}}-$($Latest.Version).vsix"
    
    # Download the payload
    Invoke-WebRequest -Uri $Latest.URL64 -OutFile $vsixPath
    
    # The actual factory will inject VSIX extraction logic here later
    # to crack the zip and update README/LICENSE/package.json
}

update
