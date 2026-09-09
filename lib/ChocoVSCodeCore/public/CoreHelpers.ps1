<#
.SYNOPSIS
    Resolves the canonical name of the Chocolatey package based on the VS Code extension ID.

.DESCRIPTION
    Extracts the extension name from a fully qualified publisher.extension identifier,
    converts it to lowercase, and prepends the 'vscode-' prefix to generate the
    canonical Chocolatey package name.

    If a bare extension name is provided instead of a publisher-qualified ID, it gracefully
    lowercases and prefixes it.

.PARAMETER ExtensionId
    The VS Code marketplace identifier (e.g., 'ms-python.python' or 'eamodio.gitlens').

.EXAMPLE
    Get-ChocoVSCodePackageName -ExtensionId "eamodio.gitlens"
    # Returns "vscode-gitlens"

.INPUTS
    [System.String]

.OUTPUTS
    [System.String]
#>
function Get-ChocoVSCodePackageName {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $ExtensionId
    )

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
    Reads and parses the extensions.json state tracker natively.

.DESCRIPTION
    Uses a highly optimized native pipeline to read the extensions.json state file,
    which is a pure root-level YAML array of extension IDs.

.PARAMETER StatePath
    The absolute path to the extensions.json file.

.EXAMPLE
    $extensions = Get-ChocoVSCodeExtensionState -StatePath "C:\var\state\extensions.json"

.INPUTS
    None

.OUTPUTS
    [string[]]
    An array of tracked extension identifiers.
#>
function Get-ChocoVSCodeExtensionState {
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $StatePath
    )

    if (-not (Test-Path $StatePath)) {
        $fileName = Split-Path $StatePath -Leaf
        throw "$fileName not found at $StatePath"
    }

    $extensions = Get-Content $StatePath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($null -eq $extensions) { return [string[]]@() }

    return [string[]]$extensions
}

<#
.SYNOPSIS
    Saves the modified extension pool back to extensions.json safely.

.DESCRIPTION
    Takes an array of extension IDs, sorts them alphabetically, and writes them
    directly to the extensions.json file as a pure root-level YAML array.

.PARAMETER StatePath
    The absolute path to the extensions.json file.

.PARAMETER ExtensionsList
    The updated array of active extensions. Can be empty to clear the pool.

.EXAMPLE
    Save-ChocoVSCodeExtensionState -StatePath "C:\var\state\extensions.json" -ExtensionsList @("foo.bar", "ms-python.python")

.INPUTS
    None

.OUTPUTS
    None
#>
function Save-ChocoVSCodeExtensionState {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $StatePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [AllowEmptyCollection()]
        [string[]]
        $ExtensionsList
    )

    $sortedExtensions = @($ExtensionsList | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)

    if ($sortedExtensions.Count -gt 0) {
        $sortedExtensions | ConvertTo-Json -Depth 3 | Out-File -FilePath $StatePath -Encoding UTF8 -Force
    }
    else {
        "[]" | Out-File -FilePath $StatePath -Encoding UTF8 -Force
    }

    Write-Success "State saved to $StatePath ($($sortedExtensions.Count) total extensions tracked)."
}
