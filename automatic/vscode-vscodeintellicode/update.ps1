[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "VisualStudioExptTeam"
$global:ExtensionName = "vscodeintellicode"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
