[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "prisma"
$global:ExtensionName = "prisma-insider"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
