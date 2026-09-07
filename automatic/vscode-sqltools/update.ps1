[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "mtxr"
$global:ExtensionName = "sqltools"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
