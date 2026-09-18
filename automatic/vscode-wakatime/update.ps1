[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "WakaTime"
$global:ExtensionName = "vscode-wakatime"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
