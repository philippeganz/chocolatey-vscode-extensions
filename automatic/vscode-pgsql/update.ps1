[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-ossdata"
$global:ExtensionName = "vscode-pgsql"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
