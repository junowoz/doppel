# Release Process

1. Update `CHANGELOG.md`.
2. Run tests.
3. Run `./scripts/check_no_network_entitlements.sh`.
4. Run `./scripts/build_release.sh`.
5. Optionally run `./scripts/package_dmg.sh`.
6. Create and push a SemVer tag:

```bash
git tag v0.1.0
git push origin v0.1.0
```

The release workflow builds the app, creates a ZIP, optionally creates a DMG, generates SHA-256 checksums, and publishes a GitHub Release.
