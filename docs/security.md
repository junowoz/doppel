# Security Notes

Doppel's safety model is intentionally conservative.

## No In-App Network

The app has no in-app network code and no network entitlements. `scripts/check_no_network_entitlements.sh` fails if common network entitlement keys are introduced. The update command opens the official GitHub Releases page in the user's browser instead of downloading or executing updates inside Doppel.

## File Access

The user chooses folders through `NSOpenPanel`. Future persistence should use security-scoped bookmarks.

## File Actions

The app does not permanently delete files. The default action is moving selected files to Trash through native Foundation APIs.

Before a move:

1. The keep file must still exist.
2. Each selected removal file must still exist.
3. Sizes must still match.
4. SHA-256 must still match.
5. Paranoid mode repeats byte-by-byte comparison.
6. A group cannot move every file.

## Packages, Symlinks, Hardlinks

macOS packages and symlinks are ignored by default. Hardlinks are marked as same underlying files so users can review them carefully.
