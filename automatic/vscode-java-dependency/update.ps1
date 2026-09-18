[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "vscjava"
$global:ExtensionName = "vscode-java-dependency"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
