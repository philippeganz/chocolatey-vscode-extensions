[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "visualstudioexptteam"
$global:ExtensionName = "intellicode-api-usage-examples"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
