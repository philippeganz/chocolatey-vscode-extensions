@{
    RootModule        = 'AuExtensionHooks.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '9d4f0d6b-76b3-4f9e-bd4e-7b7e3e7f4c3a'
    Author            = 'Philippe Ganz'
    CompanyName       = 'Etat de Genève'
    Copyright         = '(c) Philippe Ganz. All rights reserved.'
    Description       = @'
The `AuExtensionHooks` module is a dedicated, sandboxed execution environment that interfaces directly with the Chocolatey Automatic Updater (AU) engine.

It provides the mandatory hook implementations (`au_BeforeUpdate`, `au_GetLatest`, `au_SearchReplace`) required by the AU framework. This module uses a state-injection pattern to securely receive context from the execution trigger, allowing it to remain completely isolated while orchestrating the automated package updates.
'@
    FunctionsToExport = @('au_GetLatest', 'au_SearchReplace', 'au_BeforeUpdate')
}
