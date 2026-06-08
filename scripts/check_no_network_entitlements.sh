#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENTITLEMENTS="$ROOT_DIR/DoppelApp/Resources/Doppel.entitlements"

if [[ ! -f "$ENTITLEMENTS" ]]; then
  echo "Missing entitlements file: $ENTITLEMENTS" >&2
  exit 1
fi

if grep -E "com\\.apple\\.security\\.network\\.(client|server)" "$ENTITLEMENTS" >/dev/null; then
  echo "Network entitlement found in $ENTITLEMENTS" >&2
  exit 1
fi

echo "No network entitlements found."
