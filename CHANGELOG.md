# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Air-Gap Package Factory**: `Invoke-VsCodeExtensionFactory.ps1` dynamically scrapes the Microsoft Marketplace to generate offline-capable Chocolatey packages with `.vsix` payloads natively embedded.
- **Deep Recursive Auto-Discovery**: The Factory natively unrolls `extensionPack` and `extensionDependencies` metadata, automatically traversing and scaffolding complete missing dependency trees.
- **Self-Healing Configuration**: The Factory automatically updates, deduplicates, and alphabetically sorts `config.yaml` to guarantee a perfectly synchronized, flattened source of truth for all tracked extensions.
- **Cyclic Dependency Protection**: Resolves infinite resolution loops during Chocolatey installation by actively filtering out malformed self-referential dependencies in upstream VS Code packages.
- **Smart CI Versioning**: Prevents pipeline collisions during hotfix regeneration by natively preserving existing `.nuspec` versions, while automatically bootstrapping new extensions at `0.0.0` to trigger initial publication.
- **Fully Automated AU CI/CD**: A scheduled GitHub Action that natively runs `Test-Package` validations (by pre-installing VS Code on the runner), automatically publishes secure updates to the Community Gallery, and commits version bumps back to `main`.
- **Trunk-Based Enforcements**: Automated workflows to enforce strict branch-naming conventions and robust PR code validation.
