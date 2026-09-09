[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-toolsai"
$global:ExtensionName = "jupyter-renderers"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
