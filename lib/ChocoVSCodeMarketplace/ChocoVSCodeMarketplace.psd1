@{
    RootModule        = 'ChocoVSCodeMarketplace.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'a9d5beeb-7e5a-4c28-9fa9-9ec6d738386a'
    Author            = 'Philippe Ganz'
    CompanyName       = ''
    Copyright         = '(c) Philippe Ganz. All rights reserved.'
    Description       = @'
The `ChocoVSCodeMarketplace` module handles all interactions with the official Visual Studio Code Marketplace API and manages Chocolatey `.nuspec` metadata.

It is responsible for:
- Querying the marketplace for extension metadata, versions, and icons.
- Robustly downloading `.vsix` payloads with intelligent retry mechanisms and rate-limit backoffs.
- Parsing and manipulating `.nuspec` XML files (e.g., updating dependencies, injecting CData descriptions, and syncing icons).
'@
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Expand-VsCodePayload',
        'Get-VsCodeExtensionUrl',
        'Get-VsCodeMarketplaceMetadata',
        'Get-VsCodeNuspecMetadata',
        'Invoke-RobustDownload',
        'Invoke-WithMarketplaceRetry',
        'New-VerificationFile',
        'Save-NuspecXml',
        'Save-VsCodeIcon',
        'Update-NuspecCDataDescription',
        'Update-NuspecDependency',
        'Update-VsCodeNuspecMetadata'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
