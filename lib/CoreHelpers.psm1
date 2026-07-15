<#
.SYNOPSIS
    Core utility functions and helpers used across the repository.
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification='Write-Host is required for cross-platform ANSI colored output in orchestration')]
param()


<#
.SYNOPSIS
A cross-platform helper for rendering colorized, structured console messages using PS7 ANSI strings.
#>
function Write-StyledMessage {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][ConsoleColor]$Color,
        [string]$Prefix = ""
    )

    $colorName = $Color.ToString()
    $ansiColor = $PSStyle.Foreground.$colorName

    if ($Prefix) {
        Write-Host "${ansiColor}${Prefix}$($PSStyle.Reset) $Message"
    }
    else {
        Write-Host "${ansiColor}${Message}$($PSStyle.Reset)"
    }
}

# =============================================================================
# Semantic Logging Wrappers
# =============================================================================

<#
.SYNOPSIS
Writes a green success message to the console.
#>
function Write-Success ([string]$msg) { Write-StyledMessage -Prefix "[SUCCESS]" -Message $msg -Color Green }

<#
.SYNOPSIS
Writes a cyan info message to the console.
#>
function Write-Info    ([string]$msg) { Write-StyledMessage -Prefix "[INFO]"    -Message $msg -Color Cyan }

<#
.SYNOPSIS
Writes a yellow skip message to the console.
#>
function Write-Skip    ([string]$msg) { Write-StyledMessage -Prefix "[SKIP]"    -Message $msg -Color Yellow }

<#
.SYNOPSIS
Writes a red error message to the console.
#>
function Write-Err     ([string]$msg) { Write-StyledMessage -Prefix "[ERROR]"   -Message $msg -Color Red }


# =============================================================================
# Generic Color Wrappers
# =============================================================================

<#
.SYNOPSIS
Writes a raw red message to the console without a semantic prefix.
#>
function Write-Red     ([string]$msg) { Write-StyledMessage -Message $msg -Color Red }

<#
.SYNOPSIS
Writes a raw cyan message to the console without a semantic prefix.
#>
function Write-Cyan    ([string]$msg) { Write-StyledMessage -Message $msg -Color Cyan }

<#
.SYNOPSIS
Writes a raw yellow message to the console without a semantic prefix.
#>
function Write-Yellow  ([string]$msg) { Write-StyledMessage -Message $msg -Color Yellow }

<#
.SYNOPSIS
Writes a raw green message to the console without a semantic prefix.
#>
function Write-Green   ([string]$msg) { Write-StyledMessage -Message $msg -Color Green }

<#
.SYNOPSIS
Writes a raw gray message to the console without a semantic prefix.
#>
function Write-Gray    ([string]$msg) { Write-StyledMessage -Message $msg -Color Gray }

<#
.SYNOPSIS
Writes a raw magenta message to the console without a semantic prefix.
#>
function Write-Magenta ([string]$msg) { Write-StyledMessage -Message $msg -Color Magenta }

<#
.SYNOPSIS
Writes a raw white message to the console without a semantic prefix.
#>
function Write-White   ([string]$msg) { Write-StyledMessage -Message $msg -Color White }


Export-ModuleMember -Function Write-StyledMessage, Write-Success, Write-Info, Write-Skip, Write-Err, Write-Red, Write-Cyan, Write-Yellow, Write-Green, Write-Gray, Write-Magenta, Write-White
