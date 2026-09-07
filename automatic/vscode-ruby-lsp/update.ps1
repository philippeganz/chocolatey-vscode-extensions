[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "shopify"
$global:ExtensionName = "ruby-lsp"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
