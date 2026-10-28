#!/usr/bin/env bash
# Compile the GLSL fragment shaders of the widget into Qt .qsb bundles.
#
# Requires the Qt shader baker: qsb (package qt6-shadertools on Arch,
# qt6-shadertools-dev on Debian/Ubuntu). The generated .qsb files ARE
# committed, so end users installing a release do not need this script —
# only contributors who change a .frag file do.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHADER_DIR="$SCRIPT_DIR/package/contents/ui/components/shaders"

QSB="$(command -v qsb || true)"
if [[ -z "$QSB" ]]; then
    for candidate in /usr/lib/qt6/bin/qsb /usr/lib/qt6/libexec/qsb; do
        if [[ -x "$candidate" ]]; then
            QSB="$candidate"
            break
        fi
    done
fi
if [[ -z "$QSB" ]]; then
    echo "error: qsb not found. Install qt6-shadertools." >&2
    exit 1
fi

echo "Using $("$QSB" --version 2>&1 | head -1)"

shopt -s nullglob
frag_files=("$SHADER_DIR"/*.frag)
if [[ ${#frag_files[@]} -eq 0 ]]; then
    echo "error: no .frag shaders found in $SHADER_DIR" >&2
    exit 1
fi

for frag in "${frag_files[@]}"; do
    out="${frag}.qsb"
    echo "  baking $(basename "$frag") -> $(basename "$out")"
    # Target every backend plasmashell can run on: GL ES2/GL2/GL3, D3D
    # (HLSL 50) and Metal (MSL 12).
    "$QSB" --glsl 100es,120,150 --hlsl 50 --msl 12 -o "$out" "$frag"
done

echo "done."
