[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "svelte"
$global:ExtensionName = "svelte-vscode"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
