# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com),
and this project adheres to [Semantic Versioning](https://semver.org).

## [Unreleased]

### Added

- **The Extension Pool Manager (`Manage-ExtensionPool.ps1`)**
  - *Unified CLI*: A highly robust, state-aware CLI tool for managing the entire repository's extension pool.
  - *Marketplace Pre-Flight (`-Search` & `-Add`)*: Dynamically queries the VS Code API to validate extension existence before explicitly managing state in `config.yaml` and delegating scaffolding to the Factory API.
  - *Automated Garbage Collection (`-Remove`)*: Safely drops tracked extensions from state and purges their scaffolding directories.
  - *Ecosystem Auditing (`-Audit` & `-CheckStale`)*: Cross-references the local repository state against generated files, and interrogates the Chocolatey Community API (OData) to identify packages lagging >3 months behind upstream.
  - *Environment Agnosticism*: Respects the `$env:CHOCO_VSCODE_AUTOMATIC_DIR` variable to allow dynamic redirection of all package operations for safe, isolated CI testing without mutating real repository state.
  - *PS7 Elegance*: Natively detects PowerShell 7 to emit rich ANSI console styling, while maintaining graceful fallbacks for legacy PS5 environments.

- **The Factory Engine (`Invoke-VsCodeExtensionFactory.ps1`)**
  - *Automated Scaffolding*: Generates full offline Chocolatey packages for VS Code extensions natively from the VS Code Marketplace API.
  - *Dependency Auto-Discovery*: Recursively parses `extensionPacks` and `extensionDependencies`, mapping them to Chocolatey packages and automatically queuing missing dependencies.
  - *Dependency Drift Protection*: Natively synchronizes with upstream Microsoft changes, automatically stripping out legacy dependencies that get dropped from modern `package.json` arrays.
  - *XML Serialization Integrity*: Enforces strict data-typing pipelines for raw vs pre-escaped strings to guarantee pristine `.nuspec` generation without double-escaping corruption.

- **The Auto-Update Engine (AU Framework)**
  - *DRY Orchestration (`Invoke-AuUpdater.ps1`)*: Powers the Chocolatey Automatic Updater (AU) using a centralized module architecture.
  - *Topological Dependency Sorter*: Implements a DFS Kahn's algorithm variant (`Resolve-PackageDependency`) to strictly build upstream dependencies before their downstream consumers, preventing local compilation failures.
  - *3-Line Stubs (`AuExtensionHooks.ps1`)*: Replaces 100-line AU templates with highly optimized 3-line pointer scripts for every package, making updates instant and centralized.
  - *Dynamic Icon Synchronization*: Natively injects regex replacements to update `.nuspec` `<iconUrl>` strings on every run, preventing broken package images when Microsoft rotates CDN assets.

- **The Marketplace API Abstraction (`VsCodeMarketplace.psm1`)**
  - *HTML-Aware Truncation*: Automatically truncates massive VS Code Marketplace descriptions cleanly at the nearest structural HTML tag to remain comfortably under Chocolatey's strict 4,000 character limit.
  - *Markdig Compatibility*: Surgically strips problematic raw HTML tags (e.g., `<div>`, `<img>`, `<picture>`) from the final generated `.nuspec` to prevent rendering crashes on the Chocolatey Gallery, while perfectly preserving the raw HTML inside the packaged `.nupkg` itself.
  - *Air-Gap Compliance*: Automatically downloads `.vsix` payloads, extracts them, and scrubs embedded documentation (e.g., stripping emails) without requiring local VS Code installations.
  - *Platform-Aware Targeting*: Dynamically queries the Marketplace for platform-specific extension binaries (e.g., `win32-x64`) for extensions with multiple runtime builds.
  - *Robust Error Handling*: Implements 600s timeouts and exponential retry loops to bypass Microsoft CDN rate limits and random TCP connection drops.

- **Documentation & Publishing**
  - *MkDocs Material CI/CD*: Full integration with GitHub Pages via a dedicated `.github/workflows/docs.yml` action, automatically pushing a beautiful, modern documentation site on every commit.
  - *PlatyPS API Reference*: Dynamically parses the AST of all engineering scripts in `bin/` and shared modules in `lib/` to output complete Markdown documentation for the API reference site.

- **Testing & Quality Assurance**
  - *Pester 5 Lifecycle Suite (`Workflow.Tests.ps1`)*: A fully isolated, end-to-end Pester 5 integration test that spins up a sandbox (`test_automatic`), validates the Factory and AU Engine builds, and perfectly cleans up after itself.
  - *Hardened CI Pipelines*: Enhanced GitHub Actions that inject the AU module into the environment prior to testing, forcefully inject the absolute latest `PSScriptAnalyzer` to resolve legacy linting false-positives natively, and use dynamic API queries to stay strictly pinned to real-world latest Action versions (e.g., `@v8`).
