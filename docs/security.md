# Security Notes

Doppel's safety model is intentionally conservative.

## Network Boundary

The app has no telemetry, analytics, tracking, or background network calls. The only in-app network path is the manual updater, which contacts official GitHub Releases after the user clicks **Check for Updates**. `scripts/check_secure_entitlements.sh` verifies that Doppel remains sandboxed, keeps user-selected file access, allows client networking for updates, and never requests a network server entitlement.

Update downloads use `URLSessionConfiguration.ephemeral`, are staged in a temporary `DoppelUpdate-*` directory, and are removed after installation. Doppel also removes stale `DoppelUpdate-*` and `DoppelPrevious-*` directories on launch.

Before installing an update, Doppel validates:

1. The app ZIP matches the published SHA-256 checksum.
2. The bundle identifier is `com.junowoz.doppel`.
3. The bundle version matches the release tag.
4. The executable is Apple Silicon only.
5. `codesign --verify --deep --strict` passes.

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
