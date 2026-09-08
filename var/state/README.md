# State Tracking Directory

> [!CAUTION]
> **DO NOT EDIT ANY FILES IN THIS DIRECTORY MANUALLY.**

This directory (`var/state/`) is strictly used by the repository's backend automation engines (The Factory, The Shredder, and the AU Engine) to persist state between runs.

## `extensions.json`

This is a machine-to-machine tracking file containing a flat array of all extensions currently managed in the repository.

If you want to add or remove an extension, you MUST use the Pool Manager CLI (or open a GitHub Issue):

```powershell
.\bin\Manage-ExtensionPool.ps1 -Add "ms-python.python"
.\bin\Manage-ExtensionPool.ps1 -Remove "ms-python.python"
```

The CLI orchestrates the physical package scaffolding and deletion natively, and will automatically update `extensions.json` for you. Manually editing `extensions.json` will cause fatal desynchronizations in the CI/CD pipeline!
