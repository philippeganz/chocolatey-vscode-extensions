[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='Variables are declared for AU hooks and module scope but not read within this script block')]
param()
$ExtensionPublisher = "f5devcentral"
$ExtensionName = "vscode-f5"
. "$PSScriptRoot\..\..\bin\AuExtensionHooks.ps1"