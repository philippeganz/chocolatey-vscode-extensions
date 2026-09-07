[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "tomoki1207"
$global:ExtensionName = "pdf"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
