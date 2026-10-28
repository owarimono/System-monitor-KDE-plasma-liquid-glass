import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "components"
import "components/kstats" as KStats

// Full desktop representation, modeled on the macOS Tahoe liquid-glass
// widget mockup: a host card with a live clock, then one glass section
// card per metric (icon + title + mono percentage header, sparkline /
// tiles / dotted breakdown rows inside). Sections are orderable and
// individually toggleable from the settings. Stat components are adapted
// from KStats (oowl/kstats, MIT — see LICENSES/KStats-MIT.txt); the glass
// background, data layer and configuration are this widget's own.

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
        tintScale: cfg.tintStrength / 100
    }

    readonly property string monoFamily: "JetBrains Mono"
    readonly property bool compact: cfg.density === 1

    // Per-metric colors — empty config values follow the accent theme.
    function metricColor(custom) {
        return custom === "" ? colors.accent : custom
    }
    readonly property color cpuColor: metricColor(cfg.cpuColor)
    readonly property color memoryColor: metricColor(cfg.memoryColor)
    readonly property color netDownColor: metricColor(cfg.netDownColor)
    readonly property color netUpColor: cfg.netUpColor === ""
        ? Qt.lighter(colors.accent, 1.25) : cfg.netUpColor
    readonly property color gpuColor: metricColor(cfg.gpuColor)

    // Density-driven metrics.
    readonly property int contentMargin: compact ? 16 : 20
    readonly property int contentSpacing: compact ? 10 : 12
    readonly property int cardPad: compact ? 12 : 16
    readonly property real graphHeight: compact ? 2.2 : 2.8

    // Section order + membership: the persisted order is normalized so
    // every known section is present exactly once, then filtered by the
    // per-section toggles.
    readonly property var defaultOrder: ["cpu", "memory", "network", "disk", "gpu"]
    readonly property var orderedSections: {
        const saved = Array.isArray(cfg.sectionOrder)
            ? cfg.sectionOrder.map(String) : []
        let order = defaultOrder.filter(k => saved.indexOf(k) >= 0)
        for (const k of defaultOrder)
            if (order.indexOf(k) < 0)
                order.push(k)
        return order.filter(k => sectionEnabled(k))
    }

    function sectionEnabled(key) {
        switch (key) {
        case "cpu": return cfg.showCpu
        case "memory": return cfg.showMemory
        case "network": return cfg.showNetwork
        case "disk": return cfg.showDisk
        case "gpu": return cfg.showGpu
        }
        return false
    }

    function clockFormat() {
        if (cfg.clock24)
            return cfg.clockSeconds ? "HH:mm:ss" : "HH:mm"
        return cfg.clockSeconds ? "h:mm:ss AP" : "h:mm AP"
    }

    // Live clock for the host card.
    property string clockText: Qt.formatDateTime(new Date(), clockFormat())
    property string dateText: Qt.formatDateTime(new Date(), "dddd, d MMM")

    Timer {
        interval: 1000
        repeat: true
        running: view.visible
        onTriggered: {
            view.clockText = Qt.formatDateTime(new Date(), view.clockFormat())
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
    Layout.maximumHeight: 1300
    clip: true

    // macOS-style floating drop shadow: MultiEffect renders a blurred
    // copy of the glass silhouette behind it; the copy sits exactly under
    // the real glass, so only the soft shadow ring is ever visible.
    MultiEffect {
        anchors.fill: glassBg
        source: glassBg
        shadowEnabled: cfg.shadowEnabled
        shadowBlur: 0.9
        shadowColor: Qt.rgba(0, 0, 0, 0.45 * cfg.shadowStrength / 60)
        shadowVerticalOffset: 12
        autoPaddingEnabled: true
    }

    GlassBackground {
        id: glassBg
        anchors.fill: parent
        radius: cfg.cornerRadius

        tint: colors.glassTint
        tintAlpha: colors.glassTintAlpha
        fallbackOpacity: colors.glassFallbackOpacity

        solidMode: cfg.styleMode === 1
        solidColor: colors.solidBackground

        blurRadius: cfg.blurRadius
        refraction: cfg.refraction
        realtimeRefraction: cfg.realtimeRefraction
    }

    // Section header row: monochrome SF-style icon, semibold title, mono
    // value on the trailing edge — every glass card opens with one.
    component SectionHeader: RowLayout {
        property string title
        property string iconName
        property string value
        property color valueColor: colors.foreground

        Layout.fillWidth: true
        spacing: 8

        Image {
            visible: source !== ""
            source: iconName
            sourceSize: Qt.size(17, 17)
            Layout.preferredWidth: 17
            Layout.preferredHeight: 17
            fillMode: Image.PreserveAspectFit
            antialiasing: true
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
            color: valueColor
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
        anchors.margins: view.contentMargin
        spacing: view.contentSpacing

        opacity: 0
        transform: Translate { id: appearShift; y: 14 }

        Component.onCompleted: appearAnimation.start()

        ParallelAnimation {
            id: appearAnimation
            NumberAnimation { target: content; property: "opacity"; to: 1; duration: 380; easing.type: Easing.OutCubic }
            NumberAnimation { target: appearShift; property: "y"; to: 0; duration: 380; easing.type: Easing.OutCubic }
        }

        // ── Host card ─────────────────────────────────────────────────
        GlassCard {
            visible: cfg.showHostCard
            Layout.fillWidth: true
            pad: view.cardPad

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
                        font.pixelSize: 23
                        font.weight: Font.Bold
                    }

                    Text {
                        text: i18n("Linux") + "  ·  " + String(hub.memTotal.formattedValue ?? "") + " " + i18n("RAM")
                        color: colors.labelSecondary
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.Medium
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
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        text: view.clockText
                        color: colors.foreground
                        font.family: view.monoFamily
                        font.pixelSize: 22
                        font.weight: Font.SemiBold
                    }

                    Text {
                        visible: cfg.showDate
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        text: view.dateText
                        color: colors.labelSecondary
                        font.family: "Inter"
                        font.pixelSize: 12
                    }
                }
            }
        }

        // ── Ordered sections ──────────────────────────────────────────
        Repeater {
            model: view.orderedSections

            delegate: Loader {
                required property string modelData
                Layout.fillWidth: true
                Layout.preferredHeight: item ? item.implicitHeight : 0
                sourceComponent: view.sectionComponents[modelData]
            }
        }
    }

    function pct(v) {
        return Math.max(0, Math.min(100, Math.round(v))) + "%"
    }

    // ── Section components ────────────────────────────────────────────

    component CpuSection: ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: view.contentSpacing

        GlassCard {
            Layout.fillWidth: true
            pad: view.cardPad

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                SectionHeader {
                    title: i18n("CPU")
                    iconName: Qt.resolvedUrl("icons/sf/cpu.svg")
                    value: pct(hub.num(hub.cpuUsage.value))
                }

                Rectangle {
                    visible: cfg.showCpuGraph
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * view.graphHeight
                    radius: 12
                    color: colors.controlFill
                    border.width: 1
                    border.color: colors.separator

                    KStats.Sparkline {
                        anchors.fill: parent
                        anchors.margins: 6
                        samples: hub.cpuHistory
                        autoSample: false
                        maxValue: 100
                        lineColor: colors.accent
                        showFill: true
                    }
                }

                CoreTiles {
                    visible: cfg.showPerCore && hub.coreCount > 0
                    Layout.fillWidth: true
                    count: hub.coreCount
                    sensorAt: hub.coreSensorAt
                    revision: hub.coreRevision
                    tileHeight: compact ? 24 : 30
                    fillColor: colors.accent
                    trackColor: colors.controlFill
                    labelColor: colors.labelTertiary
                }
            }
        }
    }

    component MemorySection: ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        GlassCard {
            Layout.fillWidth: true
            pad: view.cardPad

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                SectionHeader {
                    title: i18n("Memory")
                    iconName: Qt.resolvedUrl("icons/sf/memory.svg")
                    value: pct(hub.memLevel * 100)
                }

                KStats.DetailRow {
                    label: i18n("Used")
                    value: String(hub.memUsed.formattedValue ?? "")
                    labelColor: colors.labelSecondary
                    valueColor: colors.foreground
                    dotColor: colors.accent
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
    }

    component NetworkSection: ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        GlassCard {
            Layout.fillWidth: true
            pad: view.cardPad

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                SectionHeader {
                    title: i18n("Network")
                    iconName: Qt.resolvedUrl("icons/sf/network.svg")
                }

                // Transparent rows: label + bare sparkline + mono rate,
                // directly on the glass like the history graph below.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: i18n("Down")
                        color: colors.accent
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    KStats.Sparkline {
                        Layout.fillWidth: true
                        Layout.preferredHeight: compact ? 14 : 18
                        smoothing: 6
                        samples: hub.downHistory
                        autoSample: false
                        maxValue: netDownMax
                        lineColor: colors.accent
                        showFill: true
                    }

                    Text {
                        text: String(hub.netDown.formattedValue ?? "")
                        color: colors.foreground
                        font.family: view.monoFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: i18n("Up")
                        color: netUpColor
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    KStats.Sparkline {
                        Layout.fillWidth: true
                        Layout.preferredHeight: compact ? 14 : 18
                        smoothing: 6
                        samples: hub.upHistory
                        autoSample: false
                        maxValue: netUpMax
                        lineColor: netUpColor
                        showFill: true
                    }

                    Text {
                        text: String(hub.netUp.formattedValue ?? "")
                        color: colors.foreground
                        font.family: view.monoFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }

                KStats.Sparkline {
                    visible: cfg.showNetGraph
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * (compact ? 1.8 : 2.2)
                    smoothing: 6
                    samples: hub.downHistory
                    autoSample: false
                    maxValue: netDownMax
                    lineColor: colors.accent
                    showFill: true
                    scaleColor: colors.labelTertiary
                }
            }
        }
    }

    component DiskSection: ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        GlassCard {
            Layout.fillWidth: true
            pad: view.cardPad

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                SectionHeader {
                    title: i18n("Disk")
                    iconName: Qt.resolvedUrl("icons/sf/disk.svg")
                    value: pct(hub.num(hub.diskUsedPercent.value))
                    valueColor: colors.levelColor(hub.num(hub.diskUsedPercent.value) / 100)
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
                            Layout.alignment: Qt.AlignRight
                            horizontalAlignment: Text.AlignRight
                            text: i18n("Total")
                            color: colors.labelTertiary
                            font.family: "Inter"
                            font.pixelSize: 11
                        }

                        Text {
                            Layout.alignment: Qt.AlignRight
                            horizontalAlignment: Text.AlignRight
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
                    Layout.preferredHeight: 8
                    radius: 4
                    color: colors.controlFill

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.max(0, Math.min(1, hub.num(hub.diskUsedPercent.value) / 100))
                        radius: 4
                        color: colors.levelColor(hub.num(hub.diskUsedPercent.value) / 100)

                        Behavior on width {
                            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: cfg.showDiskRates

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
    }

    component GpuSection: ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        GlassCard {
            visible: hub.gpus.length > 0
            Layout.fillWidth: true
            pad: view.cardPad

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                SectionHeader {
                    title: i18n("GPU")
                    iconName: Qt.resolvedUrl("icons/sf/gpu.svg")
                }

                Repeater {
                    model: hub.gpus

                    delegate: ColumnLayout {
                        required property int index
                        required property var modelData
                        // NOTE: ids are not reachable through other ids in
                        // QML — reference `hub` bare, never `view.hub`.
                        readonly property real level:
                            hub.num(modelData.usage.value) / 100

                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: String(modelData.name.value ?? ("GPU " + (index + 1)))
                                color: colors.labelSecondary
                                font.family: "Inter"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                spacing: 6

                                Text {
                                    visible: cfg.showGpuTemp
                                    text: hub.num(modelData.temperature.value) > 0
                                          ? Math.round(hub.num(modelData.temperature.value)) + "°" : ""
                                    color: colors.labelTertiary
                                    font.family: view.monoFamily
                                    font.pixelSize: 11
                                }

                                Text {
                                    text: view.pct(hub.num(modelData.usage.value))
                                    color: colors.foreground
                                    font.family: view.monoFamily
                                    font.pixelSize: 12
                                    font.weight: Font.SemiBold
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                            radius: 4
                            color: colors.controlFill

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * Math.max(0, Math.min(1, parent.parent.level))
                                radius: 4
                                color: colors.accent

                                Behavior on width {
                                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                }
                            }
                        }

                        KStats.DetailRow {
                            visible: cfg.showVram && hub.num(modelData.vramTotal.value) > 0
                            label: i18n("VRAM")
                            value: String(modelData.vramUsed.formattedValue ?? "") + " / "
                                   + String(modelData.vramTotal.formattedValue ?? "")
                            labelColor: colors.labelSecondary
                            valueColor: colors.foreground
                        }
                    }
                }
            }
        }
    }

    // Ordered section card map, consumed by the content Repeater.
    readonly property var sectionComponents: ({
        "cpu": cpuSectionComp,
        "memory": memorySectionComp,
        "network": networkSectionComp,
        "disk": diskSectionComp,
        "gpu": gpuSectionComp
    })

    Component { id: cpuSectionComp; CpuSection {} }
    Component { id: memorySectionComp; MemorySection {} }
    Component { id: networkSectionComp; NetworkSection {} }
    Component { id: diskSectionComp; DiskSection {} }
    Component { id: gpuSectionComp; GpuSection {} }
}
