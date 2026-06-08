#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENTITLEMENTS="$ROOT_DIR/DoppelApp/Resources/Doppel.entitlements"

if [[ ! -f "$ENTITLEMENTS" ]]; then
  echo "Missing entitlements file: $ENTITLEMENTS" >&2
  exit 1
fi

if ! /usr/libexec/PlistBuddy -c "Print :com.apple.security.app-sandbox" "$ENTITLEMENTS" | grep -q "true"; then
  echo "Doppel must remain sandboxed." >&2
  exit 1
fi

if ! /usr/libexec/PlistBuddy -c "Print :com.apple.security.files.user-selected.read-write" "$ENTITLEMENTS" | grep -q "true"; then
  echo "Doppel must keep user-selected file access only." >&2
  exit 1
fi

if ! /usr/libexec/PlistBuddy -c "Print :com.apple.security.network.client" "$ENTITLEMENTS" | grep -q "true"; then
  echo "Doppel needs client networking for manual GitHub Releases updates." >&2
  exit 1
fi

if /usr/libexec/PlistBuddy -c "Print :com.apple.security.network.server" "$ENTITLEMENTS" >/dev/null 2>&1; then
  echo "Network server entitlement is not allowed." >&2
  exit 1
fi

echo "Entitlements are limited to sandbox, user-selected files, and update client networking."
