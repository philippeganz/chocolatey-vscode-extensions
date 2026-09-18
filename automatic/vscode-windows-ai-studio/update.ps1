[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-windows-ai-studio"
$global:ExtensionName = "windows-ai-studio"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
