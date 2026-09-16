@{
    RootModule        = 'ChocoVSCodeMarketplace.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'a9d5beeb-7e5a-4c28-9fa9-9ec6d738386a'
    Author            = 'Philippe Ganz'
    CompanyName       = ''
    Copyright         = '(c) Philippe Ganz. All rights reserved.'
    Description       = @'
The ChocoVSCodeMarketplace module handles all interactions with the official Visual Studio Code Marketplace API and manages Chocolatey package metadata.

It is responsible for:
- Querying the Marketplace for authoritative JSON metadata, remote versions, and icons.
- Downloading .vsix payloads with intelligent retry mechanics, checksum generation, and rate-limit backoffs.
- Parsing and manipulating .nuspec XML files (updating dependencies, injecting CData, and ensuring Chocolatey feed compliance).
'@
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Convert-MixedMarkdownToPure',
        'Expand-VsCodePayload',
        'Get-VsCodeExtensionUrl',
        'Get-VsCodeMarketplaceMetadata',
        'Get-VsCodeNuspecMetadata',
        'Invoke-RobustDownload',
        'Invoke-WithMarketplaceRetry',
        'New-VerificationFile',
        'Save-NuspecXml',
        'Save-VsCodeIcon',
        'Search-VsCodeMarketplace',
        'Update-NuspecCDataDescription',
        'Update-NuspecDependency',
        'Update-VsCodeNuspecMetadata'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
