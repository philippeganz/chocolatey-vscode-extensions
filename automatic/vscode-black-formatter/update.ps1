[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-python"
$global:ExtensionName = "black-formatter"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
