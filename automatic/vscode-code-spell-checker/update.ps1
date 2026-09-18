[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "streetsidesoftware"
$global:ExtensionName = "code-spell-checker"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
