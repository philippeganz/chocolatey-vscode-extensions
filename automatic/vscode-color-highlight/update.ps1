[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "naumovs"
$global:ExtensionName = "color-highlight"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
