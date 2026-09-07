@{
    RootModule        = 'ChocoVSCodeExtensionManager.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '889ede4d-d2d7-4523-8559-9fb133bd17f2'
    Author            = 'Philippe Ganz'
    CompanyName       = ''
    Copyright         = '(c) Philippe Ganz. All rights reserved.'
    Description       = @'
The `ChocoVSCodeExtensionManager` module serves as the primary orchestrator for extension lifecycle management (Scaffolding and Shredding).

It is responsible for:
- **Scaffolding:** Generating new Chocolatey packages for untracked extensions using the `Add-VSCodeExtension` API, injecting custom variables, and syncing the `extensions.yaml` state.
- **Shredding:** Safely destroying deprecated or failing extensions, wiping their directory footprints, and untracking them from the state.
'@
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Add-VSCodeExtension',
        'Checkpoint-GitRepository',
        'Remove-VSCodeExtension'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
