[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "dracula-theme"
$global:ExtensionName = "theme-dracula"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
