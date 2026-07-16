[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Variables are declared for AU hooks and module scope but not read within this script block')]
param()
$ExtensionPublisher = "ms-ceintl"
$ExtensionName = "vscode-language-pack-en-gb"
. "$PSScriptRoot\..\..\bin\AuExtensionHooks.ps1"
