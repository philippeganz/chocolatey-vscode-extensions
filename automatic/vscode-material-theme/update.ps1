[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "zhuangtongfa"
$global:ExtensionName = "material-theme"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
