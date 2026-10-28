#!/usr/bin/env bash
# Install (or upgrade) the widget into the current user's Plasma.
#
# Usage: ./install.sh [--no-restart]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$SCRIPT_DIR/package"
WIDGET_ID="$(python3 -c 'import json;print(json.load(open("'"$PACKAGE_DIR"'/metadata.json"))["KPlugin"]["Id"])')"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "error: kpackagetool6 not found (install plasma-sdk or plasma-workspace)." >&2
    exit 1
fi

# Upgrade when an older version is present, install otherwise.
if kpackagetool6 --type=Plasma/Applet --list | grep -q "^${WIDGET_ID}$"; then
    echo "Upgrading existing installation of $WIDGET_ID ..."
    kpackagetool6 --type=Plasma/Applet --upgrade "$PACKAGE_DIR"
else
    echo "Installing $WIDGET_ID ..."
    kpackagetool6 --type=Plasma/Applet --install "$PACKAGE_DIR"
fi

echo "Installed successfully."

if [[ "${1:-}" != "--no-restart" ]]; then
    echo "Restarting plasmashell (run ./install.sh --no-restart to skip this)."
    systemctl --user restart plasma-plasmashell.service
fi
