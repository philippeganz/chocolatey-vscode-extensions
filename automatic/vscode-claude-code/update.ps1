[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "anthropic"
$global:ExtensionName = "claude-code"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
