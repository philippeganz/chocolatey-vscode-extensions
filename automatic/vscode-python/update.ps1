[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-python"
$global:ExtensionName = "python"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
