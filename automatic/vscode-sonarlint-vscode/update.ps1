[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Required for module state propagation')]
param()
$global:ExtensionPublisher = "sonarsource"
$global:ExtensionName = "sonarlint-vscode"
. "$PSScriptRoot\..\..\bin\Update-ExtensionPackage.ps1"
