<#
.SYNOPSIS
    Wraps Invoke-WebRequest with robust, auto-healing retry logic to survive CDN rate-limits and timeouts.

.DESCRIPTION
    The VS Code CDN will frequently throttle CI nodes or throw HTTP 502/503 during mass automated pulls.
    This wrapper enforces a strict 600s timeout per attempt, retrying up to 3 times with exponential
    backoff to guarantee payload delivery.

.PARAMETER Url
    The absolute direct download link for the .vsix payload.

.PARAMETER OutFile
    The local destination path to save the .vsix archive.

.PARAMETER LogMessage
    Optional custom console message to display during the download phase.

.EXAMPLE
    Invoke-RobustDownload -Url "https://example.com/payload.vsix" -OutFile "C:\temp\payload.vsix"

.INPUTS
    None

.OUTPUTS
    None

.NOTES
    Deliberately sets the UserAgent to emulate a standard browser, avoiding silent blocks.
#>
function Invoke-RobustDownload {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Variables are consumed dynamically inside the dot-sourced ScriptBlock')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $Url,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $OutFile,

        [Parameter(Mandatory = $false)]
        [string]
        $LogMessage = "Downloading VSIX Payload..."
    )

    Write-Verbose $LogMessage
    Invoke-WithMarketplaceRetry -Action {
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -TimeoutSec 600
    } -ErrorMessage "Download failed"
}
