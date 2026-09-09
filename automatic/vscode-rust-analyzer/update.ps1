[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "rust-lang"
$global:ExtensionName = "rust-analyzer"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
