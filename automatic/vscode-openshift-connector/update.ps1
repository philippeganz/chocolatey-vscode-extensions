[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Variables are declared for AU hooks and module scope but not read within this script block')]
param()
$ExtensionPublisher = "redhat"
$ExtensionName = "vscode-openshift-connector"
. "$PSScriptRoot\..\..\bin\AuExtensionHooks.ps1"