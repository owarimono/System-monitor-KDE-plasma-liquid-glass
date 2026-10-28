import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // macOS-grade typography: bundled Inter (SIL OFL — LICENSES/Inter-OFL.txt).
    // Loaded once here; the family registers for the whole engine.
    FontLoader { source: Qt.resolvedUrl("../fonts/Inter-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("../fonts/Inter-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("../fonts/Inter-SemiBold.ttf") }

    // A full glass card on the desktop, a small ring pill in a panel.
    // Each representation is self-contained: it builds its own data layer
    // and palette, because bindings to ids declared here do not resolve
    // inside representation components.
    preferredRepresentation:
        (Plasmoid.formFactor === PlasmaCore.Types.Horizontal
         || Plasmoid.formFactor === PlasmaCore.Types.Vertical)
        ? compactRepresentation : fullRepresentation

    compactRepresentation: CompactPanel { }
    fullRepresentation: SystemMonitorView { }
}
