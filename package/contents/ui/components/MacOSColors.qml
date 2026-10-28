import QtQuick
import org.kde.kirigami as Kirigami

// macOS system palette for the widget.
//
// Two independent switches:
//   styleMode:  0 = liquid glass (shader background), 1 = solid panel
//   appearance: 0 = dark, 1 = light, 2 = follow system theme
//
// In glass mode the tint deepens the wallpaper; content colors must
// contrast with the *tint*, which is why dark glass keeps white labels
// and light glass switches to Apple's near-black.

QtObject {
    id: root

    property int styleMode: 0
    property int appearance: 0
    property color accentColor: "#0a84ff"

    readonly property bool useSystem: appearance === 2
    readonly property bool systemIsDark: {
        const bg = Kirigami.Theme.backgroundColor
        return (0.299 * bg.r + 0.587 * bg.g + 0.114 * bg.b) < 0.5
    }
    readonly property bool isLight: useSystem ? !systemIsDark : appearance === 1
    readonly property bool isGlass: styleMode === 0

    // ── Glass material ────────────────────────────────────────────────
    readonly property color glassTint: isLight ? "#ffffff" : "#000000"
    readonly property real glassTintAlpha: isLight ? 0.50 : 0.24
    readonly property real glassFallbackOpacity: isLight ? 0.72 : 0.55

    // ── Solid material ────────────────────────────────────────────────
    readonly property color solidBackground: isLight ? "#f5f5f7" : "#1c1c1e"

    // ── Typography colors (Apple system grays) ────────────────────────
    readonly property color foreground: isLight ? "#1d1d1f" : "#ffffff"
    readonly property color labelSecondary: isLight
        ? Qt.rgba(0.235, 0.235, 0.263, 0.62)
        : Qt.rgba(0.922, 0.922, 0.961, 0.62)
    readonly property color labelTertiary: isLight
        ? Qt.rgba(0.235, 0.235, 0.263, 0.36)
        : Qt.rgba(0.922, 0.922, 0.961, 0.36)

    // ── Chrome ────────────────────────────────────────────────────────
    readonly property color separator: isLight
        ? Qt.rgba(0.235, 0.235, 0.263, 0.16)
        : Qt.rgba(1, 1, 1, 0.12)

    // Fill of inner cards / bars, contrasted against the material.
    readonly property color controlFill: isLight
        ? Qt.rgba(0, 0, 0, 0.07)
        : Qt.rgba(1, 1, 1, 0.10)

    // Glass section cards (Tahoe style: a second glass layer on the glass).
    readonly property color cardFillTop: isLight
        ? Qt.rgba(1, 1, 1, 0.58)
        : Qt.rgba(1, 1, 1, 0.19)
    readonly property color cardFillBottom: isLight
        ? Qt.rgba(1, 1, 1, 0.40)
        : Qt.rgba(1, 1, 1, 0.11)
    readonly property color cardBorder: isLight
        ? Qt.rgba(0, 0, 0, 0.08)
        : Qt.rgba(1, 1, 1, 0.15)
    readonly property color cardHighlight: isLight
        ? Qt.rgba(1, 1, 1, 0.9)
        : Qt.rgba(1, 1, 1, 0.22)

    // ── Semantics (macOS system colors) ───────────────────────────────
    readonly property color accent: accentColor
    readonly property color green: isLight ? "#34c759" : "#32d74b"
    readonly property color orange: isLight ? "#ff9500" : "#ff9f0a"
    readonly property color red: isLight ? "#ff3b30" : "#ff453a"

    // Level color ramps used by bars and rings (memory, disk usage...).
    function levelColor(level) {
        if (level >= 0.9) return root.red
        if (level >= 0.75) return root.orange
        return root.accent
    }
}
