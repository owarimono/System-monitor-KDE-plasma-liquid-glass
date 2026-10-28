#!/usr/bin/env bash
# Package the widget into an installable .plasmoid bundle.
# Output: dist/SystemMonitor-Glass-v<version>.plasmoid

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$SCRIPT_DIR/package"
DIST_DIR="$SCRIPT_DIR/dist"

VERSION="$(python3 -c 'import json;print(json.load(open("'"$PACKAGE_DIR"'/metadata.json"))["KPlugin"]["Version"])')"
OUT="$DIST_DIR/SystemMonitor-Glass-v${VERSION}.plasmoid"

# Rebuild shaders when the tool is available so the bundle is never stale;
# otherwise trust the committed .qsb files.
if command -v qsb >/dev/null 2>&1 || [[ -x /usr/lib/qt6/bin/qsb ]]; then
    "$SCRIPT_DIR/build-shaders.sh"
else
    echo "warning: qsb not found, shipping committed .qsb files" >&2
fi

mkdir -p "$DIST_DIR"
rm -f "$OUT"

# .plasmoid is a zip whose root holds metadata.json — kpackagetool6 and the
# GUI installer both expect that layout.
(cd "$PACKAGE_DIR" && zip -qr "$OUT" metadata.json icon.svg icon.png contents)

echo "Created $OUT"
