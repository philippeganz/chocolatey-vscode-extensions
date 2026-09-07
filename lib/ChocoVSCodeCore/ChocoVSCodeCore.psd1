@{
    RootModule        = 'ChocoVSCodeCore.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '1a8286c5-1186-4fd5-a4fd-82b2f205a8d0'
    Author            = 'Philippe Ganz'
    CompanyName       = ''
    Copyright         = '(c) Philippe Ganz. All rights reserved.'
    Description       = @'
The `ChocoVSCodeCore` module provides foundational utilities, configuration logic, and state management for the entire Chocolatey VS Code Extension ecosystem.

It is responsible for:
- Standardizing console output and logging streams with rich styling.
- Reading and persisting the global `extensions.yaml` state file.
- Providing robust file system and path resolution helpers.
'@
    PowerShellVersion = '7.0'
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
