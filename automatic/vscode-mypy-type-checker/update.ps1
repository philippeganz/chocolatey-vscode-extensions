[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-python"
$global:ExtensionName = "mypy-type-checker"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
