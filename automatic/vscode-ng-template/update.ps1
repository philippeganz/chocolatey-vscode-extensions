[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "angular"
$global:ExtensionName = "ng-template"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
