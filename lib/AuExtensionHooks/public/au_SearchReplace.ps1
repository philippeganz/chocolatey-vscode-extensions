<#
.SYNOPSIS
    The String Replacer hook for Chocolatey AU.

.DESCRIPTION
    AU executes this function to natively update the hardcoded version strings
    inside our runtime scripts (like chocolateyInstall.ps1) so the new binaries are properly targeted.

    It constructs a dictionary of RegEx rules that AU applies directly to the file paths
    specified in the dictionary keys.

.EXAMPLE
    # This function is not meant to be called directly. It is invoked natively by AU.

.INPUTS
    None

.OUTPUTS
    [System.Collections.Hashtable]
    Returns a hashtable mapping file paths to their respective RegEx replacement rules.
#>
function global:au_SearchReplace {
    [OutputType([System.Collections.Hashtable])]
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for AU Engine state')]
    param()

    $packageName = Get-ChocoVSCodePackageName -ExtensionId "$global:ExtensionPublisher.$global:ExtensionName"
    $targetIconUrl = "https://cdn.jsdelivr.net/gh/philippeganz/chocolatey-vscode-extensions@main/automatic/$packageName/icon.png"

    $rules = @{
        "tools\chocolateyInstall.ps1" = @{
            "(?i)($global:ExtensionPublisher\.$global:ExtensionName-)[\d\.]+(\.vsix)" = "`${1}$($Latest.Version)`${2}"
        }
        "*.nuspec"                    = @{
            "(?is)<iconUrl>.*?</iconUrl>" = "<iconUrl>$targetIconUrl</iconUrl>"
        }
    }

    return $rules
}
