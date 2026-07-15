[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Variables are declared for AU hooks and module scope but not read within this script block')]
param()
$ExtensionPublisher = "njpwerner"
$ExtensionName = "autodocstring"
. "$PSScriptRoot\..\..\bin\AuExtensionHooks.ps1"