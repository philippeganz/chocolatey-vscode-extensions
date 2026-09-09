[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "yzhang"
$global:ExtensionName = "markdown-all-in-one"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
