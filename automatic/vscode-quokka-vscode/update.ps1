[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "wallabyjs"
$global:ExtensionName = "quokka-vscode"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
