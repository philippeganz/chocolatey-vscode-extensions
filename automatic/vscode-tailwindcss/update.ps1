[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "bradlc"
$global:ExtensionName = "vscode-tailwindcss"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
