[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Variables are declared for AU hooks and module scope but not read within this script block')]
param()
$ExtensionPublisher = "PKief"
$ExtensionName = "material-icon-theme"
. "$PSScriptRoot\..\..\bin\AuExtensionHooks.ps1"
