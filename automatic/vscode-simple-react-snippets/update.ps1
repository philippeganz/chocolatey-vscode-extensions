[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "burkeholland"
$global:ExtensionName = "simple-react-snippets"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
