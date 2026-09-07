[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "openai"
$global:ExtensionName = "chatgpt"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
