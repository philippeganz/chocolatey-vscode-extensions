# Repository Architecture

This document describes the architectural logic and data flows that power the Chocolatey VS Code Extensions mono-repo.

Our pipeline is built on a hyper-DRY paradigm and strict separation of concerns, divided into two distinct lifecycle phases: **Bootstrapping (The Factory)** and **Maintenance (The AU Engine)**.

## High-Level Lifecycle Flow

```mermaid
flowchart TD
    subgraph The CLI Orchestrator
        A[User invokes CLI] --> B(Manage-ExtensionPool.ps1)
        B -->|Add new extension| C{Invoke-ExtensionFactory.ps1}
        B -->|Remove extension| Z{Invoke-ExtensionShredder.ps1}
    end

    subgraph Day 0: The Factory (Bootstrapping)
        C -->|Scrapes VS Code Marketplace| D[Extracts Initial Metadata]
        D -->|Validates & Deep-Scans VSIX| E[Generates Scaffolding]
        E -->|Drops template.nuspec with 0.0.0| F[automatic/vscode-new-extension]
        E -->|Generates update.ps1 stub| F
        E -->|Generates chocolateyInstall.ps1| F
    end

    subgraph Day 0: The Shredder (Teardown)
        Z -->|Validates Dependencies| Y[Checks local .nuspecs]
        Y -->|Safe to remove| X[Wipes package directory]
        X -->|Cleans State| W[Updates config.yaml]
    end

    subgraph Day 1 to Infinity: The AU Engine (Maintenance)
        F -.->|6-hour Cron Job| G(Invoke-AuUpdater.ps1)
        G -->|Bypasses Chocolatey API Check| H{au_BeforeUpdate Hook}
        H -->|Fetches latest payload| I[Extracts README.md & LICENSE]
        H -->|Centralized Logic| J[Overwrites Dynamic Metadata]
        J -->|Bumps Version & IconUrl| K[Packs .nupkg]
        K --> L[Publishes to Chocolatey Gallery]
        L -.->|If Local Changed| N(GitHub Action: Granular Git Commits)
        N -->|Commits 1 by 1| O[Pushes natively to main via PAT]
    end

    subgraph Auto-Discovery & Dependency Resolution
        H -.->|Detects missing nested dependency in package.json| M[Update-NuspecDependencies]
        M -->|Queues new dependency| B
    end
```

## Directory Structure

- `.github/workflows/`: Contains the AU CI/CD pipelines (which natively run `Invoke-AuUpdater.ps1` and inject granular git commits), testing pipelines, and the MkDocs GitHub Pages deployment pipeline.
- `automatic/`: Contains the AU templates for every managed extension. **(All packages use an optimized 3-line stub pattern instead of bloated scripts, pointing to a shared logic engine).**
- `bin/`: Contains the core executable engineering scripts (Factory, Updater, Documentation Generators).
- `lib/`: Contains shared PowerShell modules (e.g., `VsCodeMarketplace.psm1`) that power both the Factory and the AU Engine.
- `docs/`: Houses the MkDocs Material site and the auto-generated PlatyPS Markdown reference documentation.

## Core Modules

### 1. The Master Orchestrator: `Manage-ExtensionPool.ps1`

The single CLI entry point for humans and CI/CD pipelines to modify the state of the repository. It acts as a master router, abstracting away the complex engineering modules.

- **`-Add`**: Routes the parameters to the Factory for package creation.
- **`-Remove`**: Routes the parameters to the Shredder for package dismantling.
- **`-AutoCommit`**: Evaluates the Git diff after the child scripts finish and commits the changes.

### 2. The Scaffolder: `Invoke-ExtensionFactory.ps1`

Responsible exclusively for **Day 0 Bootstrapping (Creation)**.

- It auto-discovers dependencies, extracts ZIP payloads for documentation, and generates the baseline packages.
- **Smart CI Bootstrapping:** Extensions are explicitly scaffolded with `<version>0.0.0</version>` in their `.nuspec`. This inherently triggers the AU Engine to push the pristine upstream version on its first run without requiring manual intervention.
- **Deep Recursive Auto-Discovery:** If the extension has internal dependencies (like Extension Packs), the Factory natively unrolls them, dynamically scaffolds the complete missing dependency tree, and employs **Cyclic Dependency Protection**.

### 3. The Destroyer: `Invoke-ExtensionShredder.ps1`

Responsible exclusively for **Day 0 Teardown (Removal)**.

- **Dependency Validation**: Scans all local `.nuspec` files to ensure the package you are trying to remove is not actively required by another package in the pool. It blocks removal to prevent silent breakages unless explicitly overridden via `-Force`.
- **State De-sync**: Neatly deletes the physical `automatic/` directory and updates the flat `config.yaml` to ensure the package is purged from both the local disk and the pool registry.

### 4. The Maintainer: `Invoke-AuUpdater.ps1`

Responsible exclusively for **Day 1 Maintenance**.
It sweeps the repository every 6 hours, triggering the native Chocolatey Automatic Updater (AU) framework for all existing packages in the `automatic/` directory.

- **Source of Truth Enforcement:** By explicitly enabling `$global:au_NoCheckChocoVersion = $true`, the orchestrator completely ignores the Chocolatey Registry. It forces local versions to sync exclusively with the VS Code Marketplace.
- **Granular Git Pipeline:** AU does not manage Git natively. The GitHub Action loops over `git status --porcelain` after AU finishes, executing individual commits for every modified package and pushing them natively via a repository PAT.

### 5. The Logic Engine: `AuExtensionHooks.ps1` & `VsCodeMarketplace.psm1`

This is where the magic happens. Rather than duplicating logic, both the Factory and the AU hooks pull from a centralized data-driven helper (`Get-VsCodeNuspecMetadata`).

- During an update, `au_BeforeUpdate` dynamically rips the newest `README.md` and `package.json` from the payload.
- It overwrites structural metadata (`Title`, `Summary`, `IconUrl`, `ProjectUrl`, `Authors`) dynamically, achieving **Zero Maintenance** synchronization with the VS Code Marketplace.

### 6. The Documentation Engine: `Update-Documentation.ps1`

Responsible exclusively for generating the internal API reference.

- It dynamically parses the Abstract Syntax Trees (AST) and Comment-Based Help of all scripts in `bin/` and modules in `lib/`.
- It seamlessly translates them into beautiful Markdown via `platyPS`, dropping them into the `docs/reference` folder for immediate rendering by MkDocs Material.

## Design Principles & Rules

To ensure long-term stability and security, this repository adheres to strict architectural mandates. Any future PRs or automated refactoring must respect these rules:

1. **Strict Dependency Minimization (No External Binaries):**
   We rely natively on PowerShell. External binaries (like `yq` or `jq`) are strictly forbidden to minimize supply-chain risk and pipeline bloat. For YAML parsing, we exclusively use the `powershell-yaml` module which is invoked natively.

2. **The Flat State (`config.yaml`):**
   The `config.yaml` file is designed to be a completely flat array of tracked extensions. It does not track state, output directories, or versions. The physical directories in `automatic/` serve as the actual state.

3. **The Air-Gap Mandate (Pure Packages):**
   Packages must never reach out to the internet during `choco install`. The `.vsix` payload is strictly downloaded during the Factory/AU build phase and embedded *inside* the `.nupkg`. Because the binary is internal, native AU checksum generation is explicitly bypassed (`-ChecksumFor none`); the package is protected by Chocolatey's native SHA512 hash instead.

4. **Continuous Validation (Pester):**
   The entire E2E Factory -> AU -> Cleanup lifecycle is wrapped in a comprehensive Pester test suite (`tests/Workflow.Tests.ps1`). Every logic change must pass these tests in the GitHub Actions pipeline.

## Managing Existing Extensions

### Regenerating Packages (`-Force`)

If you need to completely nuke a package and rebuild it from scratch, use the `-Force` flag in the Factory. This will obliterate the directory, wipe any custom `.nuspec` tweaks, and bootstrap a fresh package starting at `0.0.0`.

*Fail-Safe:* Because `-Force` completely nukes the package and resets the version to `0.0.0`, you should **never** use the Factory to roll out mass structural changes to existing templates (e.g., adding a flag to `chocolateyInstall.ps1`). Doing so would destroy your injected READMEs. Instead, use a native PowerShell loop (`Get-ChildItem | ForEach-Object { $_ -replace ... }`) across the `automatic/` directory to push template changes without disturbing AU's state.

### Emergency Hotfixes (Forced Updates)

If you need to manually push a hotfix to a package (e.g., you fixed a typo in the installer script) but the upstream software version hasn't changed, you must trigger the **Chocolatey AU Updater** workflow manually via the GitHub Actions UI. Supply the package name in the `forced_packages` input. The orchestrator will inject `$global:au_Force = $true` to bypass the version math, trigger AU to append a timestamp, rebuild the binary, and push the revision directly to the gallery.
