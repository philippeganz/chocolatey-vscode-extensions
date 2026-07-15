[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='Variables are declared for AU hooks and module scope but not read within this script block')]
param()
$ExtensionPublisher = "angular"
$ExtensionName = "ng-template"
. "$PSScriptRoot\..\..\bin\AuExtensionHooks.ps1"