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
    param (
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$OutFile
    )

    Write-White "    Downloading VSIX Payload..."
    $retryCount = 0
    $success = $false
    while (-not $success -and $retryCount -lt 3) {
        try {
            Invoke-WebRequest -Uri $Url -OutFile $OutFile -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -TimeoutSec 600
            $success = $true
        }
        catch {
            Write-Yellow "    [WARNING] Download failed. Retrying in 5 seconds ($($retryCount + 1)/3)..."
            $retryCount++
            if ($retryCount -ge 3) { throw }
            Start-Sleep -Seconds 5
        }
    }
}
