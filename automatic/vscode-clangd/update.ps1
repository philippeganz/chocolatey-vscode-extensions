[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "llvm-vs-code-extensions"
$global:ExtensionName = "vscode-clangd"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
