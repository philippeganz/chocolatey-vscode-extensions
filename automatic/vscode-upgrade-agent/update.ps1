[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-dotnettools"
$global:ExtensionName = "upgrade-agent"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
