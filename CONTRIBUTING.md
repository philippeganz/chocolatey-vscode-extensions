# Contributing to Chocolatey VS Code Extensions

First off, thank you for considering contributing to this project!

## Code of Conduct

By participating in this project, you agree to abide by our organization's Code of Conduct and professional engineering standards.

## Branching Strategy (Trunk-Based Development)

This repository is an Automatic Updater (AU) Mono-Repo. Because extensions update asynchronously and independently via our CI bot, we use **Trunk-Based Development** rather than strict Gitflow.

### Primary Branch

- **`main`**: The single source of truth. The AU bot continuously pushes automated commits directly to this branch.

### Supporting Branches

- **`feature/*`**: Branches for adding new extensions or enhancing the factory scripts.
- **`bugfix/*`**: Branches for fixing broken templates or factory logic.

## Pull Request Process

1. Create a **`feature/*`** or **`bugfix/*`** branch for your work.
2. Ensure you have tested your changes locally by running the Factory to scaffold the extension.
3. Update the `README.md` if you are adding new dependencies or making architectural changes.
4. Submit a Pull Request **targeting the `main` branch**.
5. The `Lint and Test` CI pipeline will automatically run `PSScriptAnalyzer`, `markdownlint`, and a Chocolatey pack validation. Your CI pipeline must be entirely green before a merge will be considered.
6. Provide a clear, detailed description of what your code does and why it was necessary.
7. You may merge the Pull Request once you have the sign-off of at least one core maintainer.
