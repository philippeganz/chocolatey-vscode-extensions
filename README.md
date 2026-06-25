# Chocolatey VS Code Extensions (Mono-Repo)

[![AU Updater](https://github.com/philippeganz/chocolatey-vscode-extensions/actions/workflows/au-updater.yml/badge.svg)](https://github.com/philippeganz/chocolatey-vscode-extensions/actions)
[![Lint and Test](https://github.com/philippeganz/chocolatey-vscode-extensions/actions/workflows/lint-and-test.yml/badge.svg)](https://github.com/philippeganz/chocolatey-vscode-extensions/actions)
![VS Code](https://img.shields.io/badge/Visual%20Studio%20Code-Extensions-007ACC?style=flat-square&logo=visual-studio-code)
![Chocolatey](https://img.shields.io/badge/Chocolatey-AU%20Automation-81C5EE?style=flat-square&logo=chocolatey)
![Air-Gap Ready](https://img.shields.io/badge/Air--Gapped-100%25%20Compliant-brightgreen?style=flat-square)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=flat-square)](LICENSE)

This repository is the central Automatic Updater (AU) Mono-Repo for Visual Studio Code extensions packaged for the Chocolatey Community Repository.

## Table of Contents

- [Overview](#overview)
- [The Air-Gap Problem](#the-air-gap-problem)
- [Repository Architecture](#repository-architecture)
- [How to Add a New Extension](#how-to-add-a-new-extension)
- [Continuous Integration (AU)](#continuous-integration-au)
- [Limitations](#limitations)
- [Contributing](#contributing)
- [License](#license)

## Overview

Visual Studio Code extensions are highly sought after by developers in enterprise environments. However, public Chocolatey packages for VS Code extensions often rely on the `code --install-extension` CLI command. This command forces the local machine to reach out to the internet to download the `.vsix` payload, which completely fails in offline, proxy-restricted, or air-gapped environments.

This repository solves that. We maintain **"Pure Packages"** where the `.vsix` payload is automatically downloaded by the AU script and fully embedded *inside* the Chocolatey `.nupkg`.

## The Air-Gap Problem

When you install an extension from this repository:

1. No internet connection is required at install time.
2. Extensions are mapped 1:1 to their Chocolatey dependencies.
3. Metadata, `README.md`, and `LICENSE` files are extracted directly from the `.vsix` archive ensuring perfect upstream compliance.
4. Deep scanning is employed to ensure packages do not invoke hidden runtime network triggers (e.g., `wget`, `npm install`).

## Repository Architecture

This is a standard Chocolatey AU Mono-Repo powered by a custom PowerShell Factory.

- `.github/workflows/`: Contains the AU CI/CD pipelines and the Branch Naming PR enforcer.
- `automatic/`: Contains the AU templates for every managed extension.
- `bin/`: Contains the `Invoke-VsCodeExtensionFactory.ps1` script and its YAML configuration.

## How to Add a New Extension

We welcome community contributions to expand the list of managed extensions! Because we use an automated factory, adding a new extension requires zero manual templating.

1. Create a new branch: `feature/add-my-extension` (Strict Branch Naming is enforced).
2. Open `bin/config.yaml` and add the `Publisher.ExtensionName` to the `extensions` array.
3. Run the factory locally:

   ```powershell
   cd bin
   .\Invoke-VsCodeExtensionFactory.ps1
   ```

4. The factory will scrape the VS Code Marketplace, extract the `.vsix`, and automatically generate the Chocolatey templates in the `automatic/` directory.
5. Commit the generated folder and open a Pull Request!

## Continuous Integration (AU)

Once an extension is merged into the `main` branch, the `au-updater.yml` GitHub Action takes over.

Every 6 hours, it crawls the `automatic/` directory. If a new version of an extension is released on the VS Code Marketplace, AU will automatically download the new `.vsix`, pack the `.nupkg`, push it to Chocolatey, and commit the version bump back to this repository.

## Limitations

- Extensions that require OS-level toolchains (e.g., Python, Git) will list them as separate Chocolatey dependencies (Meta-Packages).
- This repository strictly targets the `win32-x64` architecture (and universal extensions).

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the Pull Request process.

### Contributors

- Philippe Ganz (@philippeganz)

## License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.
