# Contributing

Thanks for helping make Doppel safer and more useful.

## Development

```bash
swift test
./script/build_and_run.sh
```

## Guidelines

- Keep the app local-first.
- Do not add network calls or network entitlements.
- Do not add analytics, telemetry, tracking, or external SDKs without a public design discussion.
- Do not implement permanent deletion in v0.1.x.
- Use native macOS APIs where possible.
- Add tests for file-moving, hashing, comparison, and recommendation changes.
- Keep file actions conservative and transparent.

## Pull Requests

- Explain the user-facing change.
- Include tests for behavior changes.
- Mention privacy or security implications.
- Keep unrelated refactors out of feature PRs.
