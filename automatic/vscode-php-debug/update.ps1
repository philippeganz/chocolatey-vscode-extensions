[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "xdebug"
$global:ExtensionName = "php-debug"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
