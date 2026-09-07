[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "codezombiech"
$global:ExtensionName = "gitignore"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
