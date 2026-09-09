[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "formulahendry"
$global:ExtensionName = "code-runner"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
