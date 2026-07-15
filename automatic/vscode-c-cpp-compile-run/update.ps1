[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='Variables are declared for AU hooks and module scope but not read within this script block')]
param()
$ExtensionPublisher = "danielpinto8zz6"
$ExtensionName = "c-cpp-compile-run"
. "$PSScriptRoot\..\..\bin\AuExtensionHooks.ps1"