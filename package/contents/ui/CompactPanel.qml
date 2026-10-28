import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import "components"

// Compact panel representation: a glass pill with the CPU activity ring
// and the live percentage.

Item {
    id: panel

    readonly property var cfg: Plasmoid.configuration

    SensorHub {
        id: hub
        updateInterval: cfg.updateInterval
        graphDuration: cfg.graphDuration
    }

    MacOSColors {
        id: colors
        styleMode: cfg.styleMode
        appearance: cfg.appearance
        accentColor: cfg.accentColor
    }

    implicitWidth: 118
    implicitHeight: 34
    Layout.minimumWidth: 64

    GlassBackground {
        anchors.fill: parent
        radius: Math.min(20, panel.height / 2 - 2)

        tint: colors.glassTint
        tintAlpha: colors.glassTintAlpha
        fallbackOpacity: colors.glassFallbackOpacity

        solidMode: cfg.styleMode === 1
        solidColor: colors.solidBackground

        blurRadius: Math.min(12, cfg.blurRadius)
        refraction: cfg.refraction
        realtimeRefraction: cfg.realtimeRefraction
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 7

        Item {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22

            ActivityRing {
                anchors.fill: parent
                value: hub.num(hub.cpuUsage.value) / 100
                ringColor: colors.accent
                ringColor2: Qt.lighter(colors.accent, 1.35)
                trackColor: colors.controlFill
                lineWidth: 3.5
            }

            Text {
                anchors.centerIn: parent
                text: "C"
                color: colors.foreground
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }
        }

        Text {
            text: Math.max(0, Math.min(100, Math.round(hub.num(hub.cpuUsage.value)))) + "%"
            color: colors.foreground
            font.family: "JetBrains Mono"
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
    }
}
