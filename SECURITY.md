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

- Doppel must not make network calls.
- Doppel must not request network entitlements.
- Doppel must only operate on user-selected folders.
- Doppel must never permanently delete files in v0.1.0.
- Doppel must move files to Trash with `FileManager.trashItem`.
- Doppel must revalidate files before moving them.
- Doppel must keep at least one file in every duplicate group.
