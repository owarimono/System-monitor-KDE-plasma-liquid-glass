import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "components"

// Full desktop representation: a macOS-style glass card with sections for
// CPU (ring + per-core bars + rolling graph), memory, network throughput,
// disk and GPU. Sections appear in a fixed order and can be toggled in
// the widget settings.

Item {
    id: view

    readonly property var cfg: Plasmoid.configuration

    // Self-contained data layer and palette.
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

    // The card grows with its content by default; users may resize freely,
    // overflow is clipped so sections never spill outside the glass.
    implicitWidth: 380
    implicitHeight: content.implicitHeight + content.anchors.margins * 2
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.minimumWidth: 320
    Layout.minimumHeight: 260
    Layout.maximumWidth: 520
    Layout.maximumHeight: 1100
    clip: true

    function pct(v) {
        return Math.max(0, Math.min(100, Math.round(v))) + "%"
    }

    GlassBackground {
        anchors.fill: parent
        radius: 30
        roundness: 5.5

        tint: colors.glassTint
        tintAlpha: colors.glassTintAlpha
        fallbackOpacity: colors.glassFallbackOpacity

        solidMode: cfg.styleMode === 1
        solidColor: colors.solidBackground

        blurRadius: cfg.blurRadius
        refraction: cfg.refraction
        realtimeRefraction: cfg.realtimeRefraction
    }

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        spacing: 16

        // ── Header ────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Kirigami.Icon {
                id: appIcon
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                source: Qt.resolvedUrl("icons/appicon.svg")
            }

            Text {
                text: i18n("System Monitor")
                color: colors.foreground
                font.pixelSize: 15
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }

            Text {
                visible: String(hub.hostname.value ?? "") !== ""
                text: String(hub.hostname.value ?? "")
                color: colors.labelTertiary
                font.pixelSize: 11
            }
        }

        // ── CPU ───────────────────────────────────────────────────────
        ColumnLayout {
            visible: cfg.showCpu
            Layout.fillWidth: true
            spacing: 10

            SectionHeader {
                Layout.fillWidth: true
                title: i18n("CPU")
                iconName: "cpu"
                textColor: colors.foreground
                secondaryColor: colors.labelSecondary
                iconColor: colors.labelSecondary
                value: hub.cpuTempAvailable && cfg.showTemp
                       ? String(hub.cpuTemp.formattedValue ?? "") : ""
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Item {
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64

                    ActivityRing {
                        anchors.fill: parent
                        value: hub.num(hub.cpuUsage.value) / 100
                        ringColor: colors.accent
                        ringColor2: Qt.lighter(colors.accent, 1.35)
                        trackColor: colors.controlFill
                        lineWidth: 7
                    }

                    Text {
                        anchors.centerIn: parent
                        text: view.pct(hub.num(hub.cpuUsage.value))
                        color: colors.foreground
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        visible: hub.cpuFreqAvailable
                        text: String(hub.cpuFreq.formattedValue ?? "")
                        color: colors.foreground
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }
                    Text {
                        visible: hub.cpuFreqAvailable
                        text: i18n("Average frequency")
                        color: colors.labelTertiary
                        font.pixelSize: 11
                    }
                    Text {
                        Layout.fillWidth: true
                        text: cfg.showPerCore
                              ? i18n("Per-core activity below")
                              : i18n("Total CPU utilization")
                        color: colors.labelTertiary
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }
            }

            CoreBars {
                visible: cfg.showPerCore && hub.coreCount > 0
                Layout.fillWidth: true
                count: hub.coreCount
                sensorAt: hub.coreSensorAt
                fillColor: colors.accent
                trackColor: colors.controlFill
            }

            RollingGraph {
                visible: cfg.showCpuGraph
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                values: hub.cpuHistory
                revision: hub.historyRevision
                maxValue: 100
                lineColor: colors.accent
                fillColor: colors.accent
            }
        }

        Hairline { visible: cfg.showCpu && (cfg.showMemory || cfg.showNetwork || cfg.showDisk || view.showGpu) }

        // ── Memory ────────────────────────────────────────────────────
        ColumnLayout {
            visible: cfg.showMemory
            Layout.fillWidth: true
            spacing: 8

            SectionHeader {
                Layout.fillWidth: true
                title: i18n("Memory")
                iconName: "media-memory"
                textColor: colors.foreground
                secondaryColor: colors.labelSecondary
                iconColor: colors.labelSecondary
                value: String(hub.memUsed.formattedValue ?? "")
                       + " / " + String(hub.memTotal.formattedValue ?? "")
            }

            StatBar {
                Layout.fillWidth: true
                level: hub.memLevel
                fillColor: colors.levelColor(hub.memLevel)
                trackColor: colors.controlFill
            }

            RowLayout {
                visible: hub.swapActive
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: i18n("Swap")
                    color: colors.labelTertiary
                    font.pixelSize: 11
                }

                StatBar {
                    Layout.fillWidth: true
                    barHeight: 4
                    level: hub.swapLevel
                    fillColor: colors.labelTertiary
                    trackColor: colors.controlFill
                }

                Text {
                    text: String(hub.swapUsed.formattedValue ?? "")
                    color: colors.labelTertiary
                    font.pixelSize: 11
                }
            }
        }

        Hairline { visible: cfg.showMemory && (cfg.showNetwork || cfg.showDisk || view.showGpu) }

        // ── Network ───────────────────────────────────────────────────
        ColumnLayout {
            visible: cfg.showNetwork
            Layout.fillWidth: true
            spacing: 8

            SectionHeader {
                Layout.fillWidth: true
                title: i18n("Network")
                iconName: "network-wireless"
                textColor: colors.foreground
                secondaryColor: colors.labelSecondary
                iconColor: colors.labelSecondary
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                RateColumn {
                    Layout.fillWidth: true
                    arrow: "↓"
                    arrowColor: colors.accent
                    rateText: String(hub.netDown.formattedValue ?? "")
                    values: hub.downHistory
                    revision: hub.historyRevision
                    lineColor: colors.accent
                    showGraph: cfg.showNetGraph
                    labelColor: colors.labelTertiary
                }

                RateColumn {
                    Layout.fillWidth: true
                    arrow: "↑"
                    arrowColor: colors.green
                    rateText: String(hub.netUp.formattedValue ?? "")
                    values: hub.upHistory
                    revision: hub.historyRevision
                    lineColor: colors.green
                    showGraph: cfg.showNetGraph
                    labelColor: colors.labelTertiary
                }
            }
        }

        Hairline { visible: cfg.showNetwork && (cfg.showDisk || view.showGpu) }

        // ── Disk ──────────────────────────────────────────────────────
        ColumnLayout {
            visible: cfg.showDisk
            Layout.fillWidth: true
            spacing: 8

            SectionHeader {
                Layout.fillWidth: true
                title: i18n("Disk")
                iconName: "drive-harddisk"
                textColor: colors.foreground
                secondaryColor: colors.labelSecondary
                iconColor: colors.labelSecondary
                value: String(hub.diskUsed.formattedValue ?? "")
                       + " / " + String(hub.diskTotal.formattedValue ?? "")
            }

            StatBar {
                Layout.fillWidth: true
                level: hub.num(hub.diskUsedPercent.value) / 100
                fillColor: colors.levelColor(
                               hub.num(hub.diskUsedPercent.value) / 100)
                trackColor: colors.controlFill
            }

            Text {
                text: i18n("R/W") + "  " + String(hub.diskRead.formattedValue ?? "")
                      + "  /  " + String(hub.diskWrite.formattedValue ?? "")
                color: colors.labelTertiary
                font.pixelSize: 11
            }
        }

        Hairline { visible: cfg.showDisk && view.showGpu }

        // ── GPU ───────────────────────────────────────────────────────
        ColumnLayout {
            visible: view.showGpu
            Layout.fillWidth: true
            spacing: 8

            SectionHeader {
                Layout.fillWidth: true
                title: i18n("GPU")
                iconName: "video-display"
                textColor: colors.foreground
                secondaryColor: colors.labelSecondary
                iconColor: colors.labelSecondary
                value: String(hub.gpuVramUsed.formattedValue ?? "")
                       + " / " + String(hub.gpuVramTotal.formattedValue ?? "")
            }

            StatBar {
                Layout.fillWidth: true
                level: hub.num(hub.gpuUsage.value) / 100
                fillColor: colors.accent
                trackColor: colors.controlFill
            }
        }
    }

    // GPU section shows only when the daemon actually exposes GPU sensors.
    readonly property bool showGpu: cfg.showGpu && hub.gpuAvailable

    component Hairline: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: colors.separator
    }

    // One half of the network section: arrow glyph, live rate and an
    // optional rolling throughput sparkline.
    component RateColumn: ColumnLayout {
        id: rateCol

        required property string arrow
        required property color arrowColor
        required property string rateText
        required property var values
        required property real revision
        required property color lineColor
        required property bool showGraph
        required property color labelColor

        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: rateCol.arrow
                color: rateCol.arrowColor
                font.pixelSize: 14
                font.weight: Font.Bold
            }

            Text {
                Layout.fillWidth: true
                text: rateCol.rateText
                color: colors.foreground
                font.pixelSize: 13
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }

        RollingGraph {
            visible: rateCol.showGraph
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            values: rateCol.values
            revision: rateCol.revision
            maxValue: -1
            lineColor: rateCol.lineColor
            fillColor: rateCol.lineColor
        }
    }
}
