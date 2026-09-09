#!/bin/bash
set -euo pipefail

DEB="${1:-$(find packages -maxdepth 1 -type f -name '*.deb' | head -n 1)}"
if [[ -z "${DEB}" || ! -f "${DEB}" ]]; then
  echo "No .deb found" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
ar -x "$DEB" --output "$TMP/ar"
tar -xf "$TMP/ar/data.tar*" -C "$TMP"

for f in \
  "$TMP/Library/MobileSubstrate/DynamicLibraries/LinguaTweak.dylib" \
  "$TMP/Library/PreferenceBundles/LinguaTweakPrefs.bundle/LinguaTweakPrefs"; do
  test -f "$f"
  echo "=== $f ==="
  file "$f"
  xcrun lipo -info "$f"
  xcrun otool -hv "$f" | head -10
  xcrun otool -l "$f" | grep -A5 -E 'LC_BUILD_VERSION|LC_CODE_SIGNATURE' || true
done
