# Release Process

1. Update `CHANGELOG.md` and `AppMetadata.version`.
2. Run tests.
3. Run `./scripts/check_secure_entitlements.sh`.
4. Run `./scripts/build_release.sh`.
5. Optionally run `./scripts/package_dmg.sh`.
6. Create and push a SemVer tag:

```bash
git tag v0.1.0
git push origin v0.1.0
```

The release workflow builds the app, embeds the updater helper, creates a ZIP, optionally creates a DMG, generates SHA-256 checksums, and publishes a GitHub Release.

Release artifacts are Apple Silicon only. Ad-hoc signing is the default for local and CI builds unless `CODESIGN_IDENTITY` is set to a Developer ID Application identity. Gatekeeper-friendly public releases require Developer ID signing and notarization.

The in-app updater expects these release assets:

- `Doppel.app.zip`
- `Doppel.app.zip.sha256`

The updater downloads both assets from the latest stable GitHub Release, validates the checksum, validates the extracted app bundle, and installs through the embedded `DoppelUpdater.app` helper.
