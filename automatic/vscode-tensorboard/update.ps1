[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-toolsai"
$global:ExtensionName = "tensorboard"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
