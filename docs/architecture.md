# Architecture

Doppel is organized around a testable core and a native SwiftUI shell.

## Core Target

- `Models`: file metadata, duplicate groups, options, results, actions, and settings.
- `Services`: scanning, hashing, byte comparison, duplicate detection, recommendations, file actions, reports, previews, and settings persistence.
- `ViewModels`: app state and UI orchestration.

## App Target

- `App`: SwiftUI app entrypoint.
- `Views`: sidebar, duplicate groups, file rows, preview, settings, progress, and summary surfaces.
- `Support`: formatting helpers.

## Detection Pipeline

1. Scan user-selected folders.
2. Skip hidden files, symlinks, and macOS packages according to options.
3. Group by size.
4. Hash candidates.
5. Confirm with byte-by-byte comparison in Safe and Paranoid modes.
6. Recommend one keep file and zero or more removable duplicates.

## Safety Boundary

Only `FileActionService` moves files. It validates existence, size, SHA-256, and optional byte comparison before calling `FileManager.trashItem`.
