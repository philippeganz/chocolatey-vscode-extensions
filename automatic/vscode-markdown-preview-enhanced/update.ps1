[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "shd101wyy"
$global:ExtensionName = "markdown-preview-enhanced"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
