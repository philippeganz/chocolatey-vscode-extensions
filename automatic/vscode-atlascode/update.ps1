[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "atlassian"
$global:ExtensionName = "atlascode"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
