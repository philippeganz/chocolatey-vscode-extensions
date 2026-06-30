# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.0.0] - 2026-06-30

### Added

- **Automated Factory (`Invoke-VsCodeExtensionFactory.ps1`)**: Scaffolds full offline Chocolatey packages for VS Code extensions natively from the VS Code Marketplace API.
- **Air-Gap Compliance (`VsCodeMarketplace.psm1`)**: Automatically downloads `.vsix` payloads, extracts them, and scrubs embedded documentation (e.g., stripping emails) without requiring local VS Code installations.
- **Platform-Aware Binary Targeting**: Dynamically queries the Marketplace for platform-specific extension binaries (e.g., `win32-x64`) for extensions with multiple runtime builds.
- **Dependency Auto-Discovery Engine**: Recursively parses `extensionPacks` and `extensionDependencies` inside `.vsix` archives, maps them to Chocolatey packages, and automatically queues missing dependencies for scaffolding.
- **Robust Error Handling & Auto-Healing**: Implements 600s timeouts and exponential retry loops to bypass Microsoft CDN rate limits and random TCP connection drops.
- **DRY Orchestration Engine (`Invoke-AuUpdater.ps1`)**: Powers the Chocolatey Automatic Updater (AU) using a centralized module architecture.
- **3-Line Stubs (`AuExtensionHooks.ps1`)**: Replaces 100-line AU templates with highly optimized 3-line pointer scripts for every package, making updates instant and centralized.
- **CI/CD Integration**: Fully integrated GitHub Actions pipeline (`au-updater.yml`) to scan the Marketplace every 6 hours and automatically publish Chocolatey packages.
