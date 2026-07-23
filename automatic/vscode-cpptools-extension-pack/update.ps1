[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Variables are declared for AU hooks and module scope but not read within this script block')]
param()
$ExtensionPublisher = "ms-vscode"
$ExtensionName = "cpptools-extension-pack"
. "$PSScriptRoot\..\..\bin\AuExtensionHooks.ps1"
