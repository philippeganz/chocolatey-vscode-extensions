# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com),
and this project adheres to [Semantic Versioning](https://semver.org).

## [Unreleased]

### Added

- **Extension Pool Manager**: Unified CLI tool (`Manage-ExtensionPool.ps1`) for managing tracked VS Code extensions, featuring Marketplace validation, automated garbage collection, and state auditing.
- **Factory Engine**: Automated scaffolding system (`Invoke-ExtensionFactory.ps1`) that dynamically generates offline, air-gap compliant Chocolatey packages directly from the VS Code Marketplace, including recursive dependency auto-discovery.
- **Shredder Engine**: Destruction engine (`Invoke-ExtensionShredder.ps1`) that provides automated teardown of extensions with topological dependency protection and state desyncing.
- **Auto-Update Engine (AU Framework)**: A decoupled orchestrator (`Invoke-AuUpdater.ps1`) utilizing 3-line stubs and topological dependency sorting to synchronize packages with the VS Code Marketplace. It pushes natively to Chocolatey and maintains the repository as the absolute source of truth via granular Git commits.
- **Marketplace API Integration**: Robust abstraction layer (`VsCodeMarketplace.psm1`) handling HTML-aware description truncation, Markdig compliance, platform-specific VSIX payloads, and exponential retry loops to bypass rate limits.
- **Documentation Pipeline**: Fully automated MkDocs Material site deployment (`docs.yml`), featuring dynamic AST-based PlatyPS Markdown generation for the complete API reference.
- **Quality Assurance**: Hardened GitHub Actions CI/CD pipelines running an isolated, end-to-end Pester 5 lifecycle suite to validate Factory and AU builds natively.
