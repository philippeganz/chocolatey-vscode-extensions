[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "prisma"
$global:ExtensionName = "prisma"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
