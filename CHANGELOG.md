# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initialized AU Mono-Repo structure.
- Established `automatic/` directory for Chocolatey packages.
- Created `lint-and-test.yml` CI pipeline (PSScriptAnalyzer, MarkdownLint, and choco pack validation).

### Changed

- Transitioned architecture from Gitflow to Trunk-Based Development.
- Renamed and refactored PR validation action to `enforce-branch-naming.yml`.
- Configured `.gitignore` to explicitly block embedded `.vsix` payloads from committing to Git history.
