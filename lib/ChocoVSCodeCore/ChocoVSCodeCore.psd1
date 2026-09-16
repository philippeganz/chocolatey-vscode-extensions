@{
    RootModule        = 'ChocoVSCodeCore.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '1a8286c5-1186-4fd5-a4fd-82b2f205a8d0'
    Author            = 'Philippe Ganz'
    CompanyName       = ''
    Copyright         = '(c) Philippe Ganz. All rights reserved.'
    Description       = @'
The ChocoVSCodeCore module provides foundational utilities, configuration logic, and state management for the entire Chocolatey VS Code Extension ecosystem.

As the foundational dependency for all other modules, it is responsible for:
- Standardizing console output and logging streams with rich styling.
- Reading and persisting the core extensions.json tracker.
- Enforcing global name resolutions (e.g., mapping Marketplace IDs to Chocolatey Package names).
'@
    PowerShellVersion = '7.0'
    ScriptsToProcess  = @()
    FunctionsToExport = @(
        'Get-ChocoVSCodeExtensionState',
        'Get-ChocoVSCodePackageName',
        'Save-ChocoVSCodeExtensionState',
        'Write-Err',
        'Write-Info',
        'Write-Skip',
        'Write-StyledMessage',
        'Write-Success',
        'Write-Warn'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
