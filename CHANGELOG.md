# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com),
and this project adheres to [Semantic Versioning](https://semver.org).

## [Unreleased]

### Added

- **The Factory Engine (`Invoke-VsCodeExtensionFactory.ps1`)**
  - *Automated Scaffolding*: Generates full offline Chocolatey packages for VS Code extensions natively from the VS Code Marketplace API.
  - *Dependency Auto-Discovery*: Recursively parses `extensionPacks` and `extensionDependencies`, mapping them to Chocolatey packages and automatically queuing missing dependencies.
  - *Dependency Drift Protection*: Natively synchronizes with upstream Microsoft changes, automatically stripping out legacy dependencies that get dropped from modern `package.json` arrays.
  - *Surgical Metadata Updates (`-UpdateMetadata`)*: Natively mutates `.nuspec` structures to dynamically refresh tags, summaries, and dependencies while preserving manual descriptions and AU version states.
  - *Nuke & Bootstrap Operations*: Resilient `-Force` flag to guarantee complete package obliteration and pristine `0.0.0` initialization.
  - *XML Serialization Integrity*: Enforces strict data-typing pipelines for raw vs pre-escaped strings to guarantee pristine `.nuspec` generation without double-escaping corruption.
- **The Auto-Update Engine (AU Framework)**
  - *DRY Orchestration (`Invoke-AuUpdater.ps1`)*: Powers the Chocolatey Automatic Updater (AU) using a centralized module architecture.
  - *3-Line Stubs (`AuExtensionHooks.ps1`)*: Replaces 100-line AU templates with highly optimized 3-line pointer scripts for every package, making updates instant and centralized.
  - *Dynamic Icon Synchronization*: Natively injects regex replacements to update `.nuspec` `<iconUrl>` strings on every run, preventing broken package images when Microsoft rotates CDN assets.
  - *Strict Separation of Concerns*: Explicit isolation where AU exclusively handles chronological updates (`README.md`, `LICENSE`, version strings, and binaries) while the Factory owns structural metadata.
- **The Marketplace API Abstraction (`VsCodeMarketplace.psm1`)**
  - *Air-Gap Compliance*: Automatically downloads `.vsix` payloads, extracts them, and scrubs embedded documentation (e.g., stripping emails) without requiring local VS Code installations.
  - *Platform-Aware Targeting*: Dynamically queries the Marketplace for platform-specific extension binaries (e.g., `win32-x64`) for extensions with multiple runtime builds.
  - *Robust Error Handling*: Implements 600s timeouts and exponential retry loops to bypass Microsoft CDN rate limits and random TCP connection drops.
- **CI/CD Infrastructure**
  - *GitHub Actions Integration*: Fully integrated pipeline (`au-updater.yml`) to scan the Marketplace every 6 hours and automatically publish Chocolatey packages.
