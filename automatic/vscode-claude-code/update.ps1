[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()
$ExtensionPublisher = "anthropic"
$ExtensionName = "claude-code"
. "$PSScriptRoot\..\..\bin\AuExtensionHooks.ps1"