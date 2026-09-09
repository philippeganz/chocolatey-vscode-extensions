[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "vscjava"
$global:ExtensionName = "vscode-spring-initializr"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
