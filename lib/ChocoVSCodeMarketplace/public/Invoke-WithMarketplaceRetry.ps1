<#
.SYNOPSIS
    A generic retry wrapper for executing network actions against the VS Code Marketplace.

.DESCRIPTION
    Encapsulates the standard exponential backoff and transient error-handling logic
    required when interfacing with the heavily rate-limited VS Code Marketplace API.
    Identifies common throttling signatures (e.g. 503, 429) and correctly applies
    retries without leaking internal implementation details across the codebase.

.PARAMETER Action
    The ScriptBlock to execute. If it throws an exception, the wrapper catches it
    and determines if a retry is justified.

.PARAMETER ErrorMessage
    A custom error prefix for the warning log when a transient failure occurs.
    Defaults to "VS Code Marketplace API failed".

.PARAMETER MaxRetries
    The maximum number of times to retry a failed transient request. Defaults to 3.

.EXAMPLE
    $res = Invoke-WithMarketplaceRetry -Action {
        Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $headers
    }

.NOTES
    Throws a terminating MarketplaceThrottlingError if the maximum retry threshold
    is breached. Hard fails immediately on 404s.
#>
function Invoke-WithMarketplaceRetry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]
        $Action,

        [Parameter(Mandatory = $false)]
        [string]
        $ErrorMessage = "VS Code Marketplace API failed",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 10)]
        [int]
        $MaxRetries = 3
    )

    $attemptCount = 0
    $success = $false
    $res = $null

    if (-not $PSBoundParameters.ContainsKey('MaxRetries')) {
        $MaxRetries = if ($env:CHOCO_VSCODE_MAX_RETRIES) { [int]$env:CHOCO_VSCODE_MAX_RETRIES } else { 3 }
    }

    # Total attempts equals 1 initial execution + N retries
    $MaxAttempts = 1 + $MaxRetries

    while (-not $success -and $attemptCount -lt $MaxAttempts) {
        try {
            # Execute the provided script block in the caller's scope so variables map correctly
            $res = . $Action
            $success = $true
        }
        catch {
            $errMessage = $_.Exception.Message
            # 404s are hard failures, not transient network drops. Never retry.
            if ($errMessage -match '404') {
                throw $_
            }
            $isThrottling = ($errMessage -match '503|500|429|CircuitBreakerExceededConcurrencyException|Service Unavailable|Internal Server Error')

            $attemptCount++
            if ($attemptCount -ge $MaxAttempts) {
                Write-Err "$ErrorMessage. Exhausted all $MaxAttempts attempts ($MaxRetries retries)."
                if ($isThrottling) {
                    throw "MarketplaceThrottlingError: VS Code Marketplace API rate limit reached after $MaxAttempts attempts. ($errMessage)"
                }
                throw $_
            }

            # Exponential backoff base 2 (2, 4, 8, 16...)
            $sleepSeconds = [Math]::Pow(2, $attemptCount)
            Write-Warn "$ErrorMessage. Retry attempt $attemptCount of $MaxRetries in $sleepSeconds seconds..."
            Start-Sleep -Seconds $sleepSeconds
        }
    }

    return $res
}
