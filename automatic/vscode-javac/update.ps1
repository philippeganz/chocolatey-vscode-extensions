[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "georgewfraser"
$global:ExtensionName = "vscode-javac"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
