# Security Policy

## Supported Versions

Because this repository operates as an Automated Updater (AU) factory, there are no tagged releases. We strictly support and patch only the **latest `main` branch** of the factory scripts.

| Version | Supported          |
| ------- | ------------------ |
| `main`  | :white_check_mark: |
| Older   | :x:                |

## Scope of Responsibility

Please note that this repository **only maintains the Chocolatey packaging scripts**. It acts as an automated passthrough that downloads `.vsix` files directly from the official Microsoft VS Code Marketplace.

- **Vulnerabilities in an Extension:** If you discover a vulnerability inside an actual VS Code extension, **do not report it here**. Please report it directly to the upstream extension publisher on their respective repository.
- **Vulnerabilities in the Factory:** If you discover a vulnerability in the *packaging process itself* (e.g., our scripts fetching from insecure HTTP endpoints, or manipulating the package insecurely), please report it here.

## Reporting a Vulnerability

If you discover a security vulnerability within the AU scripts or templates in this repository, please **open a new GitHub Issue** and apply the `security` label. 

As an open-source project maintained by an individual, there is no dedicated security team or private disclosure bounty program. Issues will generally be tracked and addressed openly in the issue tracker. *If you wish to privately disclose a critical infrastructure vulnerability before it is made public, you may use GitHub's native "Report a vulnerability" feature located under the repository's **Security** tab.*
