[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "ms-dynamics-smb"
$global:ExtensionName = "al"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
