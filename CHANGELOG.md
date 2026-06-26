# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Fully automated Chocolatey AU Mono-Repo architecture for managing Air-Gapped, offline-capable Visual Studio Code extensions.
- PowerShell Factory (`Invoke-VsCodeExtensionFactory.ps1`) to dynamically scrape the VS Code Marketplace and bootstrap pristine Chocolatey package templates.
- Native Zero-Version scaffolding (`0.0.0`) in the Factory to inherently trigger AU updates for new packages without manual interference.
- Dynamic `au-updater.yml` GitHub Action that routinely synchronizes packages, downloads `.vsix` payloads using the `au_BeforeUpdate` native hook, and manages automated commits.
- Robust CI testing mechanism that silently pre-installs VS Code and core helper extensions on the runner to perform native `Test-Package` validations prior to community deployment.
- Initial support and templating for the `vscode-prettier-vscode` extension.
- Strict Trunk-Based Development workflows and PR branch-naming enforcement pipelines.
