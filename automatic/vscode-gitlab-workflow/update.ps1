[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "gitlab"
$global:ExtensionName = "gitlab-workflow"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
