# Changelog

All notable changes to Doppel will be documented in this file.

## [0.1.1] - 2026-06-08

### Added

- App icon and release bundle icon embedding.
- Screenshot assets folder and README screenshot references.
- Safe **Check for Updates** entrypoint that opens GitHub Releases in the browser without adding app network entitlements.
- Apple Silicon-only release packaging checks.

### Changed

- Improved README for OSS launch readiness, usage, downloads, updates, security, and Apple Silicon builds.
- Release scripts now embed the icon and ad-hoc sign local builds by default.

### Fixed

- Hardlinked files are no longer automatically recommended for removal.
- Safe mode now repeats byte-by-byte validation before moving selected files.

## [0.1.0] - 2026-06-08

### Added

- Native SwiftUI macOS app scaffold.
- Exact duplicate detection using size, SHA-256, and byte-by-byte checks.
- Safe recommendation rules that keep at least one file.
- Move selected duplicates to Trash with pre-action validation.
- JSON and CSV report export services.
- Unit tests for hashing, comparison, duplicate detection, recommendation, export, and action validation.
- GitHub Actions CI and release workflows.
- Security, privacy, contribution, and release documentation.
