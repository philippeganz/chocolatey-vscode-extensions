[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "esbenp"
$global:ExtensionName = "prettier-vscode"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
