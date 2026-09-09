[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "saoudrizwan"
$global:ExtensionName = "claude-dev"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
