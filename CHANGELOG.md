# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [2.0.0] - 2026-05-28

### Added

- Configurable timestamp server with ⚙ button that opens a settings dialog
- Timestamp Server section in README explaining why timestamps matter
- Table of common public timestamp servers (DigiCert, Sectigo, GlobalSign, SSL.com)
- Documentation for smart card certificate selection behavior

### Changed

- Timestamp server URL is now read from the UI field instead of being hardcoded
- Window height increased to accommodate the timestamp server controls

## [1.1.0] - 2026-04-20

### Added

- Smart card code-signing certificate support (Microsoft Smart Card Key Storage Provider)
- Automatic deduplication of certificates by thumbprint across store and smart card
- Expired certificate filtering with notification in the UI
- Step-by-step usage guide with annotated screenshots
- Certificate trust documentation for standalone servers and Active Directory environments
- README badges (PowerShell, Platform, Stars, Issues, Last Commit, License)

### Changed

- Certificate discovery now merges software-based and smart card certificates into a single dropdown

## [1.0.0] - 2025-04-01

### Added

- WPF GUI for browsing and selecting PowerShell files
- Code-signing certificate discovery from `Cert:\CurrentUser\My`
- Authenticode signing with SHA-256 and DigiCert timestamp
- Full certificate chain inclusion in signatures
- Multi-file selection and batch signing
- Compiled standalone executable (`CodeSigningTool.exe`) via ps2exe

## [0.1.0] - 2019-07-22

### Added

- Initial release with basic PowerShell script signing functionality

[Unreleased]: https://github.com/BetaHydri/SignPoshScripts/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/BetaHydri/SignPoshScripts/compare/v1.1.0...v2.0.0
[1.1.0]: https://github.com/BetaHydri/SignPoshScripts/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/BetaHydri/SignPoshScripts/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/BetaHydri/SignPoshScripts/releases/tag/v0.1.0
