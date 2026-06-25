# Support Guide

First off, thank you for using these Air-Gapped VS Code Extensions!

## General Support & Bug Reports

If you encounter issues with a packaged extension, please first verify whether the issue is related to the **Chocolatey packaging/installation process** or the **extension itself**.

### 1. Packaging & Installation Issues

If an extension fails to install offline, or the AU script fails to download the `.vsix` payload, please use the **GitHub Issues** tab in this repository.

- Search first to see if the issue is already reported.
- Provide the full Chocolatey installation log (`choco install <package> -dv`).
- Provide your OS version and Chocolatey version.

### 2. VS Code Extension Issues

If the extension installs correctly but crashes or fails to function inside Visual Studio Code, this is likely an issue with the upstream extension codebase. Please report those bugs directly to the extension's original author on their respective GitHub repository or marketplace page.

## Feature Requests (New Extensions)

To request a new VS Code extension be added to this AU Mono-Repo:

1. Open a new GitHub Issue using the "Extension Request" title.
2. Provide the exact `Publisher.ExtensionName` ID from the Visual Studio Marketplace.
3. A maintainer will update the Factory `config.yaml` to include it in the next AU cycle.
