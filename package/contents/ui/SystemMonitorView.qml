import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "components"
import "components/kstats" as KStats

// Full desktop representation: a macOS Stats-style breakdown inside our
// liquid glass card. The stat components are adapted from KStats
// (oowl/kstats, MIT — see LICENSES/KStats-MIT.txt); the glass background,
// data layer and configuration are this widget's own.

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

    // Per-metric accents, following the macOS Stats convention of one
    // signature color per metric instead of a single theme accent.
    readonly property color cpuColor: colors.accent
    readonly property color memoryColor: "#bf5af2"
    readonly property color netDownColor: colors.green
    readonly property color netUpColor: colors.orange
    readonly property color gpuColor: "#ff375f"

    // Dynamic ceilings for the network sparklines (bytes/s history).
    readonly property real netDownMax: netPeak(hub.downHistory)
    readonly property real netUpMax: netPeak(hub.upHistory)

    function netPeak(history) {
        let peak = 1024
        for (let i = 0; i < history.length; i++)
            peak = Math.max(peak, history[i])
        return peak * 1.15
    }

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

    component StatCard: Rectangle {
        default property alias content: cardLayout.data
        property string caption: ""

        Layout.fillWidth: true
        radius: Kirigami.Units.cornerRadius
        color: colors.controlFill
        border.width: 1
        border.color: colors.separator

        ColumnLayout {
            id: cardLayout
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            Text {
                visible: caption !== ""
                text: caption
                color: colors.labelSecondary
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
        }
    }

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 18
        spacing: 14

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
            spacing: Kirigami.Units.smallSpacing

            StatCard {
                implicitHeight: Kirigami.Units.gridUnit * 4.4

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Kirigami.Units.smallSpacing * 2

                    KStats.RingGauge {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 3.6
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 3.6
                        value: hub.num(hub.cpuUsage.value)
                        label: i18n("CPU")
                        accentColor: view.cpuColor
                        trackColor: colors.controlFill
                        labelColor: colors.foreground
                        subLabelColor: colors.labelTertiary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            visible: hub.cpuFreqAvailable
                            text: String(hub.cpuFreq.formattedValue ?? "")
                            color: colors.foreground
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            font.features: { "tnum": 1 }
                        }

                        Text {
                            visible: hub.cpuFreqAvailable
                            text: i18n("Average frequency")
                            color: colors.labelTertiary
                            font.pixelSize: 11
                        }

                        KStats.DetailRow {
                            visible: hub.cpuTempAvailable && cfg.showTemp
                            label: i18n("Temperature")
                            value: String(hub.cpuTemp.formattedValue ?? "")
                            labelColor: colors.labelTertiary
                            valueColor: colors.foreground
                        }

                        KStats.DetailRow {
                            visible: hub.coreCount > 0
                            label: i18n("Cores")
                            value: i18np("%1 core", "%1 cores", hub.coreCount)
                            labelColor: colors.labelTertiary
                            valueColor: colors.foreground
                        }
                    }
                }
            }

            StatCard {
                visible: cfg.showCpuGraph
                implicitHeight: Kirigami.Units.gridUnit * 4.6
                caption: i18n("Usage history")

                KStats.Sparkline {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    samples: hub.cpuHistory
                    autoSample: false
                    maxValue: 100
                    lineColor: view.cpuColor
                    showFill: true
                    showScale: true
                    scaleTicks: [100, 50, 0]
                    scaleSuffix: "%"
                    scaleColor: colors.labelTertiary
                }
            }

            KStats.CpuCoreBars {
                visible: cfg.showPerCore && hub.coreCount > 0
                count: hub.coreCount
                sensorAt: hub.coreSensorAt
                refreshInterval: Math.max(1000, hub.updateInterval)
                barColor: view.cpuColor
                trackColor: colors.foreground
                gridColor: colors.labelTertiary
            }
        }

        // ── Memory ────────────────────────────────────────────────────
        ColumnLayout {
            visible: cfg.showMemory
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            StatCard {
                implicitHeight: Kirigami.Units.gridUnit * 4.4

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Kirigami.Units.smallSpacing * 2

                    KStats.RingGauge {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 3.6
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 3.6
                        value: hub.memLevel * 100
                        label: i18n("RAM")
                        accentColor: view.memoryColor
                        trackColor: colors.controlFill
                        labelColor: colors.foreground
                        subLabelColor: colors.labelTertiary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        KStats.DetailRow {
                            label: i18n("Used")
                            value: String(hub.memUsed.formattedValue ?? "")
                            labelColor: colors.labelTertiary
                            valueColor: colors.foreground
                        }

                        KStats.DetailRow {
                            label: i18n("Total")
                            value: String(hub.memTotal.formattedValue ?? "")
                            labelColor: colors.labelTertiary
                            valueColor: colors.foreground
                        }

                        KStats.DetailRow {
                            visible: hub.swapActive
                            label: i18n("Swap")
                            value: String(hub.swapUsed.formattedValue ?? "") + " / "
                                   + String(hub.swapTotal.formattedValue ?? "")
                            labelColor: colors.labelTertiary
                            valueColor: colors.foreground
                        }
                    }
                }
            }
        }

        // ── Network ───────────────────────────────────────────────────
        ColumnLayout {
            visible: cfg.showNetwork
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            StatCard {
                implicitHeight: Kirigami.Units.gridUnit * 3.4

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Kirigami.Units.smallSpacing

                    KStats.BarStat {
                        label: i18n("Down")
                        value: String(hub.netDown.formattedValue ?? "")
                        valueSlot: "888.8 MiB/s"
                        percent: view.netDownMax > 0
                                 ? hub.num(hub.netDown.value) / view.netDownMax * 100 : 0
                        meterWidth: Kirigami.Units.gridUnit * 3.2
                        accentColor: view.netDownColor
                        valueColor: colors.foreground
                        meterColor: colors.controlFill
                        meterBorderColor: colors.separator
                    }

                    KStats.BarStat {
                        label: i18n("Up")
                        value: String(hub.netUp.formattedValue ?? "")
                        valueSlot: "888.8 KiB/s"
                        percent: view.netUpMax > 0
                                 ? hub.num(hub.netUp.value) / view.netUpMax * 100 : 0
                        meterWidth: Kirigami.Units.gridUnit * 3.2
                        accentColor: view.netUpColor
                        valueColor: colors.foreground
                        meterColor: colors.controlFill
                        meterBorderColor: colors.separator
                    }
                }
            }

            StatCard {
                visible: cfg.showNetGraph
                implicitHeight: Kirigami.Units.gridUnit * 4.6
                caption: i18n("Download history")

                KStats.Sparkline {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
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
        StatCard {
            visible: cfg.showDisk
            Layout.fillWidth: true
            implicitHeight: Kirigami.Units.gridUnit * 3.6

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing

                KStats.BarStat {
                    label: i18n("Disk")
                    value: String(hub.diskUsed.formattedValue ?? "") + " / "
                           + String(hub.diskTotal.formattedValue ?? "")
                    valueSlot: "888.8 GiB / 888.8 GiB"
                    percent: hub.num(hub.diskUsedPercent.value)
                    previewMode: "bar"
                    meterWidth: Kirigami.Units.gridUnit * 7
                    accentColor: colors.levelColor(hub.num(hub.diskUsedPercent.value) / 100)
                    valueColor: colors.foreground
                    meterColor: colors.controlFill
                    meterBorderColor: colors.separator
                }

                KStats.DetailRow {
                    label: i18n("Read / Write")
                    value: String(hub.diskRead.formattedValue ?? "") + "  /  "
                           + String(hub.diskWrite.formattedValue ?? "")
                    labelColor: colors.labelTertiary
                    valueColor: colors.foreground
                }
            }
        }

        // ── GPU ───────────────────────────────────────────────────────
        StatCard {
            visible: view.showGpu
            Layout.fillWidth: true
            implicitHeight: Kirigami.Units.gridUnit * 2.6

            KStats.BarStat {
                Layout.fillWidth: true
                label: i18n("GPU")
                value: String(hub.gpuVramUsed.formattedValue ?? "") + " / "
                       + String(hub.gpuVramTotal.formattedValue ?? "")
                valueSlot: "888.8 GiB / 888.8 GiB"
                percent: hub.num(hub.gpuUsage.value)
                previewMode: "bar"
                meterWidth: Kirigami.Units.gridUnit * 7
                accentColor: view.gpuColor
                valueColor: colors.foreground
                meterColor: colors.controlFill
                meterBorderColor: colors.separator
            }
        }
    }

    // GPU section shows only when the daemon actually exposes GPU sensors.
    readonly property bool showGpu: cfg.showGpu && hub.gpuAvailable
}
