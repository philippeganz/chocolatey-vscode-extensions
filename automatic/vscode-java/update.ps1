[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='Variables are declared for AU hooks and module scope but not read within this script block')]
param()
$ExtensionPublisher = "redhat"
$ExtensionName = "java"
. "$PSScriptRoot\..\..\bin\AuExtensionHooks.ps1"
