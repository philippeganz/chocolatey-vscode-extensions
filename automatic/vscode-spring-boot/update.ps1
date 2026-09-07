[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "vmware"
$global:ExtensionName = "vscode-spring-boot"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
