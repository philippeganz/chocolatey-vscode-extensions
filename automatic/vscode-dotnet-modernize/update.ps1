[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-dotnettools"
$global:ExtensionName = "vscode-dotnet-modernize"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
