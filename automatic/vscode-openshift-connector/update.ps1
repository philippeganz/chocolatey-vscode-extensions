[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "redhat"
$global:ExtensionName = "vscode-openshift-connector"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
