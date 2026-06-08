# Security Policy

## Supported Versions

The first public version is v0.1.0. Security fixes target the latest released version.

## Reporting A Vulnerability

Please open a private security advisory on GitHub or email the maintainer if private disclosure is needed.

Include:

- Affected version or commit.
- Reproduction steps.
- Expected and actual behavior.
- Security impact.

## Security Principles

- Doppel must not make telemetry, analytics, tracking, or background network calls.
- Doppel may use client networking only when the user manually checks GitHub Releases for updates.
- Doppel must never request a network server entitlement.
- Doppel must only operate on user-selected folders.
- Doppel must never permanently delete files.
- Doppel must move files to Trash with `FileManager.trashItem`.
- Doppel must revalidate files before moving them.
- Doppel must keep at least one file in every duplicate group.
- Doppel must validate update ZIP checksums, app bundle identity, version, architecture, and code signature before installation.

## Release Integrity

Release artifacts include SHA-256 checksums. The in-app updater downloads the app ZIP and checksum from official GitHub Releases, validates them, stages the app in a temporary directory, and removes update files after installation. Public releases should use Apple Developer ID signing and notarization when available.
