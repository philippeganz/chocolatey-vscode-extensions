<#
.SYNOPSIS
    A cross-platform helper for rendering colorized, structured console messages using PS7 ANSI strings.

.DESCRIPTION
    Leverages $PSStyle.Foreground to output correctly colorized strings that bypass legacy Write-Host
    console color limitations, particularly in CI/CD pipeline environments. Supports custom prefixes
    and multi-level indentation for orchestrated logs.

    The colorization logic dynamically adapts based on the provided parameters:
    - If only -Message and -Color are provided, the entire message is colorized.
    - If -Prefix and -Color are provided, ONLY the prefix is colorized, and the message remains default text.
    - If -Color is omitted entirely, the message prints in plain text.

.PARAMETER Message
    The primary text content of the log message.

.PARAMETER Prefix
    An optional prefix tag (e.g., [INFO]) rendered before the message text.

.PARAMETER Color
    The optional System.ConsoleColor enum dictating the ANSI foreground color.

.PARAMETER Indent
    The zero-based indentation level. Each level adds 4 spaces of padding to the left of the message.

.EXAMPLE
    Write-StyledMessage -Message "Initialization complete" -Color Green
    # The entire string is rendered in green.

.EXAMPLE
    Write-StyledMessage -Message "Deploying payload" -Prefix "[OK]" -Color Green
    # Only the [OK] prefix is rendered in green; the message text is default terminal color.

.EXAMPLE
    Write-StyledMessage -Message "Dry run enabled"
    # The message is printed in plain text with no ANSI color sequences injected.

.INPUTS
    None

.OUTPUTS
    None
#>
function Write-StyledMessage {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is required for cross-platform ANSI colored output in orchestration')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $Message,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $Prefix,

        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]
        $Color,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 10)]
        [int]
        $Indent = 0
    )

    $spacing = ' ' * ($Indent * 4)

    if ($PSBoundParameters.ContainsKey('Color')) {
        if ($Prefix) {
            Write-Host "$spacing$($PSStyle.Foreground.$Color)$Prefix$($PSStyle.Reset) $Message"
        }
        else {
            Write-Host "$spacing$($PSStyle.Foreground.$Color)$Message$($PSStyle.Reset)"
        }
    }
    else {
        Write-Host "$spacing$($Prefix ? `"$Prefix `" : '')$Message"
    }
}

<#
.SYNOPSIS
    Writes a fatal error message to the console in red.

.DESCRIPTION
    A semantic wrapper around Write-StyledMessage.
    It forces full-line colorization by injecting the [ERROR] prefix directly into the message body.

.PARAMETER Message
    The error text to display.

.PARAMETER Indent
    The zero-based indentation level (each level adds 4 spaces).
#>
function Write-Err {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $Message,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 10)]
        [int]
        $Indent = 0
    )

    Write-StyledMessage -Message "[ERROR] $Message" -Color Red -Indent $Indent
}

<#
.SYNOPSIS
    Writes an informational message to the console in cyan.

.DESCRIPTION
    A semantic wrapper around Write-StyledMessage.
    It applies the [INFO] prefix and colors only the prefix cyan.

.PARAMETER Message
    The informational text to display.

.PARAMETER Indent
    The zero-based indentation level (each level adds 4 spaces).
#>
function Write-Info {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $Message,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 10)]
        [int]
        $Indent = 0
    )

    Write-StyledMessage -Prefix '[INFO]' -Message $Message -Color Cyan -Indent $Indent
}

<#
.SYNOPSIS
    Writes a bypass/skip message to the console in yellow.

.DESCRIPTION
    A semantic wrapper around Write-StyledMessage.
    It applies the [SKIP] prefix and colors only the prefix yellow.

.PARAMETER Message
    The skip reason or text to display.

.PARAMETER Indent
    The zero-based indentation level (each level adds 4 spaces).
#>
function Write-Skip {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $Message,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 10)]
        [int]
        $Indent = 0
    )

    Write-StyledMessage -Prefix '[SKIP]' -Message $Message -Color Yellow -Indent $Indent
}

<#
.SYNOPSIS
    Writes a success message to the console in green.

.DESCRIPTION
    A semantic wrapper around Write-StyledMessage.
    It applies the [SUCCESS] prefix and colors only the prefix green.

.PARAMETER Message
    The success text to display.

.PARAMETER Indent
    The zero-based indentation level (each level adds 4 spaces).
#>
function Write-Success {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $Message,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 10)]
        [int]
        $Indent = 0
    )

    Write-StyledMessage -Prefix '[SUCCESS]' -Message $Message -Color Green -Indent $Indent
}

<#
.SYNOPSIS
    Writes a warning message to the console in yellow.

.DESCRIPTION
    A semantic wrapper around Write-StyledMessage.
    It applies the [WARNING] prefix and colors only the prefix yellow.

.PARAMETER Message
    The warning text to display.

.PARAMETER Indent
    The zero-based indentation level (each level adds 4 spaces).
#>
function Write-Warn {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]
        $Message,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 10)]
        [int]
        $Indent = 0
    )

    Write-StyledMessage -Prefix '[WARNING]' -Message $Message -Color Yellow -Indent $Indent
}
