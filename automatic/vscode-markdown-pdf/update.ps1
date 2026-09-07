[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "yzane"
$global:ExtensionName = "markdown-pdf"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
