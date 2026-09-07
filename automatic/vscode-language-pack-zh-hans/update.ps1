[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-ceintl"
$global:ExtensionName = "vscode-language-pack-zh-hans"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
