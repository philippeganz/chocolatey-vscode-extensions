[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "amazonwebservices"
$global:ExtensionName = "aws-toolkit-vscode"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
