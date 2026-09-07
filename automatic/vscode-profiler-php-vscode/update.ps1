[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "devsense"
$global:ExtensionName = "profiler-php-vscode"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
