[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-vscode-remote"
$global:ExtensionName = "remote-ssh-edit"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
