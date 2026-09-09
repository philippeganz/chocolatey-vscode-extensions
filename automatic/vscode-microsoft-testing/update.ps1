[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-azure-load-testing"
$global:ExtensionName = "microsoft-testing"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
