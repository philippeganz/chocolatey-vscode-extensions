[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-python"
$global:ExtensionName = "flake8"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
