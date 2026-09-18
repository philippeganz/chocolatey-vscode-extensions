@{
    RootModule        = 'ChocoVSCodeExtensionManager.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '889ede4d-d2d7-4523-8559-9fb133bd17f2'
    Author            = 'Philippe Ganz'
    CompanyName       = ''
    Copyright         = '(c) Philippe Ganz. All rights reserved.'
    Description       = @'
The ChocoVSCodeExtensionManager module serves as the primary orchestrator for extension lifecycle management and repository health enforcement.

It is responsible for:
- **Eligibility & Health:** Enforcing strict compliance checks, evaluating Marketplace abandonware, tracking package ownership, and emitting strongly-typed Eligibility Enums.
- **Scaffolding:** Securely generating new Chocolatey packages for extensions using the Add-VSCodeExtension API and syncing the tracker state.
- **Shredding:** Safely destroying deprecated extensions via Remove-VSCodeExtension, wiping their physical footprints, and maintaining repository hygiene.
'@
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Add-VSCodeExtension',
        'Checkpoint-GitRepository',
        'Get-ChocolateyPackageMetadata',
        'Measure-VsCodeExtensionEligibility',
        'Measure-VsCodeExtensionHealth',
        'Remove-VSCodeExtension'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    ScriptsToProcess  = @('public\ExtensionEligibilityState.ps1')
    AliasesToExport   = @()
}
