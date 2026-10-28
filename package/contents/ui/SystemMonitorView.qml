import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "components"
import "components/kstats" as KStats

// Full desktop representation, modeled on the macOS Tahoe liquid-glass
// widget mockup: a host card with a live clock, then one glass section
// card per metric (icon + title + mono percentage header, sparkline /
// tiles / dotted breakdown rows inside). Stat components are adapted
// from KStats (oowl/kstats, MIT — see LICENSES/KStats-MIT.txt); the
// glass background, data layer and configuration are this widget's own.

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

    readonly property string monoFamily: "JetBrains Mono"

    // Per-metric accents, following the macOS Stats convention of one
    // signature color per metric instead of a single theme accent.
    readonly property color cpuColor: colors.accent
    readonly property color memoryColor: "#bf5af2"
    readonly property color netDownColor: colors.green
    readonly property color netUpColor: colors.orange
    readonly property color gpuColor: "#ff375f"

    // Backdrop for the mini meters: dark like KStats' original so the
    // colored lines stay readable on any glass tint.
    readonly property color meterBackdrop: colors.isLight
        ? Qt.rgba(0, 0, 0, 0.82)
        : Qt.rgba(0, 0, 0, 0.45)

    // Dynamic ceilings for the network sparklines (bytes/s history).
    readonly property real netDownMax: netPeak(hub.downHistory)
    readonly property real netUpMax: netPeak(hub.upHistory)

    function netPeak(history) {
        let peak = 1024
        for (let i = 0; i < history.length; i++)
            peak = Math.max(peak, history[i])
        return peak * 1.15
    }

    // Live clock for the host card.
    property string clockText: Qt.formatDateTime(new Date(), "HH:mm:ss")
    property string dateText: Qt.formatDateTime(new Date(), "dddd, d MMM")

    Timer {
        interval: 1000
        repeat: true
        running: view.visible
        onTriggered: {
            view.clockText = Qt.formatDateTime(new Date(), "HH:mm:ss")
            view.dateText = Qt.formatDateTime(new Date(), "dddd, d MMM")
        }
    }

    implicitWidth: 380
    implicitHeight: content.implicitHeight + content.anchors.margins * 2
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.minimumWidth: 320
    Layout.minimumHeight: 260
    Layout.maximumWidth: 520
    Layout.maximumHeight: 1200
    clip: true

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

    // Section header row: monochrome icon, semibold title, mono value on
    // the trailing edge — the pattern every glass card opens with.
    component SectionHeader: RowLayout {
        property string title
        property string iconName
        property string value
        property color accent: colors.foreground

        Layout.fillWidth: true
        spacing: 8

        Kirigami.Icon {
            visible: iconName !== ""
            source: iconName
            isMask: true
            color: colors.labelSecondary
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
        }

        Text {
            text: title
            color: colors.foreground
            font.family: "Inter"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            Layout.fillWidth: true
        }

        Text {
            visible: value !== ""
            text: value
            color: accent
            font.family: view.monoFamily
            font.pixelSize: 13
            font.weight: Font.SemiBold
        }
    }

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        spacing: 12

        // ── Host card ─────────────────────────────────────────────────
        GlassCard {
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        text: String(hub.hostname.value ?? "…")
                        color: colors.foreground
                        font.family: "Inter"
                        font.pixelSize: 19
                        font.weight: Font.SemiBold
                    }

                    Text {
                        text: i18n("Linux") + "  ·  " + String(hub.memTotal.formattedValue ?? "") + " " + i18n("RAM")
                        color: colors.labelSecondary
                        font.family: "Inter"
                        font.pixelSize: 12
                    }

                    Text {
                        visible: hub.cpuFreqAvailable
                        text: i18n("Processor") + "  ·  " + String(hub.cpuFreq.formattedValue ?? "")
                        color: colors.labelTertiary
                        font.family: "Inter"
                        font.pixelSize: 11
                    }
                }

                ColumnLayout {
                    spacing: 2

                    Text {
                        anchors.right: parent.right
                        text: view.clockText
                        color: colors.foreground
                        font.family: view.monoFamily
                        font.pixelSize: 22
                        font.weight: Font.SemiBold
                    }

                    Text {
                        anchors.right: parent.right
                        text: view.dateText
                        color: colors.labelSecondary
                        font.family: "Inter"
                        font.pixelSize: 12
                    }
                }
            }
        }

        // ── CPU ───────────────────────────────────────────────────────
        GlassCard {
            visible: cfg.showCpu
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                SectionHeader {
                    title: i18n("CPU")
                    iconName: "cpu"
                    value: view.pct(hub.num(hub.cpuUsage.value))
                    accent: view.cpuColor
                }

                Rectangle {
                    visible: cfg.showCpuGraph
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 3.2
                    radius: 12
                    color: view.meterBackdrop
                    border.width: 1
                    border.color: colors.separator

                    KStats.Sparkline {
                        anchors.fill: parent
                        anchors.margins: 6
                        samples: hub.cpuHistory
                        autoSample: false
                        maxValue: 100
                        lineColor: view.cpuColor
                        showFill: true
                    }
                }

                CoreTiles {
                    visible: cfg.showPerCore && hub.coreCount > 0
                    Layout.fillWidth: true
                    count: hub.coreCount
                    sensorAt: hub.coreSensorAt
                    fillColor: view.cpuColor
                    trackColor: colors.controlFill
                    labelColor: colors.labelTertiary
                }
            }
        }

        // ── Memory ────────────────────────────────────────────────────
        GlassCard {
            visible: cfg.showMemory
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                SectionHeader {
                    title: i18n("Memory")
                    iconName: "media-memory"
                    value: view.pct(hub.memLevel * 100)
                    accent: view.memoryColor
                }

                KStats.DetailRow {
                    label: i18n("Used")
                    value: String(hub.memUsed.formattedValue ?? "")
                    labelColor: colors.labelSecondary
                    valueColor: colors.foreground
                    dotColor: colors.green
                }

                KStats.DetailRow {
                    label: i18n("Free")
                    value: String(hub.memFree.formattedValue ?? "")
                    labelColor: colors.labelSecondary
                    valueColor: colors.foreground
                    dotColor: colors.labelTertiary
                }

                KStats.DetailRow {
                    visible: hub.swapActive
                    label: i18n("Swap")
                    value: String(hub.swapUsed.formattedValue ?? "") + " / "
                           + String(hub.swapTotal.formattedValue ?? "")
                    labelColor: colors.labelSecondary
                    valueColor: colors.foreground
                    dotColor: colors.orange
                }
            }
        }

        // ── Network ───────────────────────────────────────────────────
        GlassCard {
            visible: cfg.showNetwork
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                SectionHeader {
                    title: i18n("Network")
                    iconName: "network-wireless"
                    value: ""
                }

                KStats.BarStat {
                    Layout.fillWidth: true
                    label: i18n("Down")
                    value: String(hub.netDown.formattedValue ?? "")
                    valueSlot: "888.8 MiB/s"
                    percent: view.netDownMax > 0
                             ? hub.num(hub.netDown.value) / view.netDownMax * 100 : 0
                    stretch: true
                    fixedLabelWidth: Kirigami.Units.gridUnit * 2.2
                    accentColor: view.netDownColor
                    valueColor: colors.foreground
                    meterColor: view.meterBackdrop
                    meterBorderColor: colors.separator
                }

                KStats.BarStat {
                    Layout.fillWidth: true
                    label: i18n("Up")
                    value: String(hub.netUp.formattedValue ?? "")
                    valueSlot: "888.8 KiB/s"
                    percent: view.netUpMax > 0
                             ? hub.num(hub.netUp.value) / view.netUpMax * 100 : 0
                    stretch: true
                    fixedLabelWidth: Kirigami.Units.gridUnit * 2.2
                    accentColor: view.netUpColor
                    valueColor: colors.foreground
                    meterColor: view.meterBackdrop
                    meterBorderColor: colors.separator
                }

                KStats.Sparkline {
                    visible: cfg.showNetGraph
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.8
                    samples: hub.downHistory
                    autoSample: false
                    maxValue: view.netDownMax
                    lineColor: view.netDownColor
                    showFill: true
                    scaleColor: colors.labelTertiary
                }
            }
        }

        // ── Disk ──────────────────────────────────────────────────────
        GlassCard {
            visible: cfg.showDisk
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                SectionHeader {
                    title: i18n("Disk")
                    iconName: "drive-harddisk"
                    value: view.pct(hub.num(hub.diskUsedPercent.value))
                    accent: colors.levelColor(hub.num(hub.diskUsedPercent.value) / 100)
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        spacing: 1

                        Text {
                            text: i18n("Used")
                            color: colors.labelTertiary
                            font.family: "Inter"
                            font.pixelSize: 11
                        }

                        Text {
                            text: String(hub.diskUsed.formattedValue ?? "")
                            color: colors.foreground
                            font.family: view.monoFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 1

                        Text {
                            anchors.right: parent.right
                            text: i18n("Total")
                            color: colors.labelTertiary
                            font.family: "Inter"
                            font.pixelSize: 11
                        }

                        Text {
                            anchors.right: parent.right
                            text: String(hub.diskTotal.formattedValue ?? "")
                            color: colors.foreground
                            font.family: view.monoFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 10
                    radius: 5
                    color: colors.controlFill

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.max(0, Math.min(1, hub.num(hub.diskUsedPercent.value) / 100))
                        radius: 5
                        color: colors.levelColor(hub.num(hub.diskUsedPercent.value) / 100)

                        Behavior on width {
                            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "↗  R:  " + String(hub.diskRead.formattedValue ?? "")
                        color: colors.labelSecondary
                        font.family: view.monoFamily
                        font.pixelSize: 11
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "↘  W:  " + String(hub.diskWrite.formattedValue ?? "")
                        color: colors.labelSecondary
                        font.family: view.monoFamily
                        font.pixelSize: 11
                    }
                }
            }
        }

        // ── GPU ───────────────────────────────────────────────────────
        GlassCard {
            visible: view.showGpu
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                SectionHeader {
                    title: i18n("GPU")
                    iconName: "video-display"
                    value: view.pct(hub.num(hub.gpuUsage.value))
                    accent: view.gpuColor
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 10
                    radius: 5
                    color: colors.controlFill

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.max(0, Math.min(1, hub.num(hub.gpuUsage.value) / 100))
                        radius: 5
                        color: view.gpuColor

                        Behavior on width {
                            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                        }
                    }
                }

                KStats.DetailRow {
                    label: i18n("VRAM")
                    value: String(hub.gpuVramUsed.formattedValue ?? "") + " / "
                           + String(hub.gpuVramTotal.formattedValue ?? "")
                    labelColor: colors.labelSecondary
                    valueColor: colors.foreground
                }
            }
        }
    }

    function pct(v) {
        return Math.max(0, Math.min(100, Math.round(v))) + "%"
    }

    // GPU section shows only when the daemon actually exposes GPU sensors.
    readonly property bool showGpu: cfg.showGpu && hub.gpuAvailable
}
