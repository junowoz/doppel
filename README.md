# Doppel

**Exact duplicate finder for macOS. Private, local, safe.**

<p align="center">
  <img src="docs/assets/doppel-app-icon-256.png" width="128" alt="Doppel app icon">
</p>

![Doppel main window](docs/screenshots/doppel-main-window.png)

Doppel is a native Apple Silicon macOS app for finding exact duplicate files in one or more folders. It is built for local-first use: no login, no in-app internet access, no analytics, no telemetry, no tracking, and no external SDKs.

## Download

Download the latest Apple Silicon build from [GitHub Releases](https://github.com/junowoz/doppel/releases).

- `Doppel.app.zip`: app bundle archive.
- `Doppel.dmg`: optional disk image.
- `.sha256` files: checksums for verification.

After downloading, unzip the app and move `Doppel.app` to Applications. Builds are Apple Silicon only (`arm64`) and target modern macOS.

## Features

- Recursive folder scanning with user-selected folders.
- Duplicate detection by size, SHA-256, and byte-by-byte confirmation in Safe and Paranoid modes.
- Conservative recommendations that keep at least one file in every group.
- Hardlinked files are marked for review instead of being automatically recommended for removal.
- iPhone-style copy name handling such as `IMG_4472.HEIC` and `IMG_4472 2.heic`.
- Native SwiftUI interface with sidebar, duplicate groups, and preview details.
- Move selected duplicates to Trash. Doppel never deletes files permanently.
- Export JSON reports.
- Safe update entrypoint that opens the official GitHub Releases page without adding network access inside the app.

## Screenshots

Screenshots live in [`docs/screenshots`](docs/screenshots). Replace them with polished release screenshots when the UI is staged exactly how you want it.

## Security And Privacy

Doppel is designed to be private by default.

- No in-app network calls.
- No network entitlements.
- No telemetry, analytics, or tracking.
- No login.
- No cloud service.
- No permanent deletion in v0.1.0.
- File actions are performed through native `FileManager` APIs.
- Selected files are moved to Trash, never permanently deleted.
- At least one file is always kept in each duplicate group.
- Safe and Paranoid modes revalidate selected files before moving them.

Always review before moving files to the Trash.

## How Detection Works

The MVP scans files, groups candidates by logical file size, calculates SHA-256 for same-sized candidates, and confirms matches byte by byte in Safe and Paranoid modes. Before moving files, Doppel revalidates the keep file and selected duplicate files.

Verification levels shown in the app:

- Same size only.
- Partial hash match.
- SHA-256 match.
- Byte-by-byte confirmed.

## How To Use

1. Open Doppel.
2. Click **Add Folder** and choose the folder you want to scan.
3. Review the scan options in the sidebar.
4. Click **Scan**.
5. Review each duplicate group and the recommended keep/remove badges.
6. Move selected duplicates to Trash only after reviewing them.
7. Export a JSON report if you want an audit trail.

## Updates

Doppel does not auto-download or execute updates inside the app. The **Check for Updates** command opens the official GitHub Releases page in your browser. This keeps the app itself network-free and avoids a hidden update channel.

## Build Locally

Requirements:

- macOS 14 or newer.
- Xcode 26 or newer recommended.
- Swift 6 toolchain.
- Apple Silicon Mac.

Build and test:

```bash
swift test
swift build --arch arm64
```

Run through the Codex/macOS helper script:

```bash
./script/build_and_run.sh
```

Build a release app bundle:

```bash
./scripts/build_release.sh
```

The release script builds an `arm64` app bundle, embeds the app icon, performs ad-hoc signing by default, and writes ZIP/checksum artifacts under `dist/`.

## Tests

```bash
swift test
```

The test suite covers SHA-256 hashing, partial hashing, byte comparison, duplicate detection, package skipping, recommendation rules, JSON/CSV export, and pre-action validation.

## Signing And Notarization

Local release builds are ad-hoc signed by default and include SHA-256 checksums. This verifies bundle integrity, but it does not replace Apple Developer ID signing or notarization.

For a download that opens with the smoothest Gatekeeper experience, configure Apple Developer ID signing and notarization before publishing the release. Without that, macOS may ask users to confirm opening the app manually.

The project is prepared for signing/notarization secrets, but the open source repository does not include real secrets:

- `APPLE_TEAM_ID`
- `APPLE_ID`
- `APP_SPECIFIC_PASSWORD`
- `CODESIGN_IDENTITY`
- `DEVELOPER_ID_CERTIFICATE_P12_BASE64`
- `DEVELOPER_ID_CERTIFICATE_PASSWORD`

Do not commit real secrets.

## Known Limitations

- v0.1.x focuses on one or more selected folders, exact duplicates, Trash moves, and JSON export.
- CSV export exists in the core service and is planned for the UI in v0.2.0.
- Review-folder moves, richer progress controls, security-scoped bookmark persistence, video thumbnails, and iCloud-specific handling are planned after the MVP.
- APFS clone savings can differ from logical file size.
- Hardlinks are detected as same underlying files and should be reviewed carefully.

## Roadmap

- v0.1.0: MVP with scanning, byte confirmation, recommendations, Trash moves, JSON export, tests, docs, and CI.
- v0.1.1: Launch polish, Apple Silicon release packaging, app icon, screenshot assets, safe update entrypoint, and hardlink recommendation hardening.
- v0.2.0: Multiple folder polish, CSV export UI, image previews, review folder moves, progress improvements.
- v0.3.0: Video previews, file filters, minimum size polish, security-scoped bookmark persistence, iCloud handling.
- v1.0.0: Signing, notarization, polished DMG, expanded tests, stable security and privacy policies.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
