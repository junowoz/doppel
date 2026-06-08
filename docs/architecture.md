# Architecture

Doppel is organized around a testable core and a native SwiftUI shell.

## Core Target

- `Models`: file metadata, duplicate groups, options, results, actions, and settings.
- `Services`: scanning, hashing, byte comparison, duplicate detection, recommendations, file actions, reports, previews, and settings persistence.
- `ViewModels`: app state and UI orchestration.

## App Target

- `App`: SwiftUI app entrypoint.
- `Views`: sidebar, duplicate groups, file rows, preview, settings, progress, and summary surfaces.
- `Support`: formatting helpers, update notifications, and updater helper launch code.

## Updater Target

`DoppelUpdater` is a small helper app embedded in `Doppel.app/Contents/Library/Helpers`. It does not perform network requests. The main app downloads and validates the update, then launches the helper so it can wait for Doppel to quit, replace the app bundle, reopen Doppel, and remove temporary update files.

## Detection Pipeline

1. Scan user-selected folders.
2. Skip hidden files, symlinks, and macOS packages according to options.
3. Group by size.
4. Hash candidates.
5. Confirm with byte-by-byte comparison in Safe and Paranoid modes.
6. Recommend one keep file and zero or more removable duplicates.

## Safety Boundary

Only `FileActionService` moves files. It validates existence, size, SHA-256, and byte comparison in Safe and Paranoid modes before calling `FileManager.trashItem`.

Only `AppUpdateService` downloads updates. It uses an ephemeral URL session, validates the release ZIP checksum, validates the extracted app bundle, and stages files in a temporary directory before installation.
