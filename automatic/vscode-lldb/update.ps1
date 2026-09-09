[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "vadimcn"
$global:ExtensionName = "vscode-lldb"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
