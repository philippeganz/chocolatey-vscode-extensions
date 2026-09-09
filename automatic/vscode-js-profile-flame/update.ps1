[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-vscode"
$global:ExtensionName = "vscode-js-profile-flame"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
