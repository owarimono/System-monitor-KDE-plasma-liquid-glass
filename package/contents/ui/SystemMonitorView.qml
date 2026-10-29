import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "components"
import "components/kstats" as KStats

// Full desktop representation, modeled on the macOS Tahoe liquid-glass
// widget mockup: a host card with a live clock, then one glass section
// card per metric (icon + title + mono percentage header, sparkline /
// tiles / dotted breakdown rows inside). Sections are orderable and
// individually toggleable from the settings.
//
// Mini mode: the same morphing glass card renders a compact
// percentages-only layout; clicking it expands to the full card with a
// fluid glass resize. Stat components are adapted from KStats
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
        tintScale: cfg.tintStrength / 100
    }

    readonly property string monoFamily: "JetBrains Mono"
    readonly property bool compact: cfg.density === 1

    // ── Mini / full mode machine ───────────────────────────────────────
    // mode     = target state (persisted via cfg.miniMode)
    // rendered = what the root size currently reflects (root snaps to mini
    //            only AFTER the collapse morph, so nothing jumps mid-flight)
    property string mode: cfg.miniMode ? "mini" : "full"
    property string renderedMode: mode
    readonly property bool isMini: mode === "mini"

    readonly property real miniW: 300
    readonly property real miniH: miniContent.implicitHeight + view.cardPad * 2

    function setMode(m) {
        if (view.mode === m)
            return
        if (Plasmoid.formFactor !== PlasmaCore.Types.Planar)
            return
        view.mode = m
        cfg.miniMode = (m === "mini")
        if (m === "full") {
            // Root grows first (transparent — invisible), then the card
            // morphs into the new bounds.
            view.renderedMode = "full"
        } else {
            // Collapse: card morphs first; root snaps to mini at the end
            // (morphTimer), so the glass never appears outside the widget.
            morphTimer.restart()
        }
    }

    Timer {
        id: morphTimer
        interval: 470                 // card morph duration + 1 frame
        onTriggered: view.renderedMode = "mini"
    }

    // ── Per-metric colors — empty config values follow the accent theme.
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
    readonly property var defaultOrder: ["cpu", "memory", "network", "disk", "gpu", "battery"]
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
        case "battery": return cfg.showBattery
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

    implicitWidth: renderedMode === "mini" ? view.miniW : 380
    implicitHeight: renderedMode === "mini"
                    ? view.miniH
                    : fullContent.implicitHeight + fullContent.anchors.margins * 2
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.minimumWidth: isMini ? view.miniW : 320
    Layout.minimumHeight: isMini ? view.miniH : 260
    Layout.maximumWidth: isMini ? view.miniW : 520
    Layout.maximumHeight: isMini ? view.miniH : 1300
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

    // Load fade-in (composited with the mini/full mode crossfade).
    property real loadOpacity: 0

    Component.onCompleted: loadAnimation.start()

    ParallelAnimation {
        id: loadAnimation
        NumberAnimation { target: view; property: "loadOpacity"; to: 1; duration: 400; easing.type: Easing.OutCubic }
    }

    // ── The morphing glass card ────────────────────────────────────────
    Item {
        id: card
        x: 0
        y: 0
        width: view.isMini ? view.miniW : view.width
        height: view.isMini ? view.miniH : view.height

        Behavior on width {
            NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
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

        MultiEffect {
            anchors.fill: glassBg
            source: glassBg
            shadowEnabled: cfg.shadowEnabled
            shadowBlur: 0.9
            shadowColor: Qt.rgba(0, 0, 0, 0.45 * cfg.shadowStrength / 60)
            shadowVerticalOffset: 12
            autoPaddingEnabled: true
        }

        // ── Full content ───────────────────────────────────────────────
        ColumnLayout {
            id: fullContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: view.contentMargin
            spacing: view.contentSpacing

            opacity: (view.isMini ? 0 : 1) * view.loadOpacity
            enabled: !view.isMini
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            transform: Translate { id: fullShift; y: (view.isMini ? 10 : 0) + (1 - view.loadOpacity) * 12 }

            // ── Host card ─────────────────────────────────────────────
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

                    QQC2.ToolButton {
                        Layout.alignment: Qt.AlignTop
                        icon.name: "go-down"
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: i18n("Switch to mini mode")
                        onClicked: view.setMode("mini")
                    }
                }
            }

            // ── Ordered sections ──────────────────────────────────────
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

        // ── Mini content (percentages only) ────────────────────────────
        ColumnLayout {
            id: miniContent

            anchors.fill: parent
            anchors.margins: view.cardPad
            spacing: 6

            opacity: (view.isMini ? 1 : 0) * view.loadOpacity
            enabled: view.isMini
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: view.setMode("full")

                QQC2.ToolTip.visible: containsMouse
                QQC2.ToolTip.text: i18n("Click to expand")
            }

            Repeater {
                model: view.miniRows

                delegate: RowLayout {
                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 8

                    Image {
                        visible: modelData.icon !== ""
                        source: modelData.icon
                        sourceSize: Qt.size(14, 14)
                        Layout.preferredWidth: 14
                        Layout.preferredHeight: 14
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        text: modelData.label
                        color: colors.labelSecondary
                        font.family: "Inter"
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }

                    Text {
                        text: modelData.value
                        color: modelData.valueColor
                        font.family: view.monoFamily
                        font.pixelSize: 13
                        font.weight: Font.SemiBold
                    }
                }
            }

            // Expand affordance at the bottom.
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: i18n("Click to expand")
                color: colors.labelTertiary
                font.family: "Inter"
                font.pixelSize: 10
            }
        }
    }

    function pct(v) {
        return Math.max(0, Math.min(100, Math.round(v))) + "%"
    }

    // Mini rows: percentages of the enabled sections (network has no
    // percentage — excluded by design).
    readonly property var miniRows: {
        var rows = []
        if (cfg.showCpu)
            rows.push({ label: i18n("CPU"), icon: Qt.resolvedUrl("icons/sf/cpu.svg"),
                        value: pct(hub.num(hub.cpuUsage.value)), valueColor: colors.foreground })
        if (cfg.showMemory)
            rows.push({ label: i18n("RAM"), icon: Qt.resolvedUrl("icons/sf/memory.svg"),
                        value: pct(hub.memLevel * 100), valueColor: colors.foreground })
        if (cfg.showDisk)
            rows.push({ label: i18n("Disk"), icon: Qt.resolvedUrl("icons/sf/disk.svg"),
                        value: pct(hub.num(hub.diskUsedPercent.value)),
                        valueColor: colors.levelColor(hub.num(hub.diskUsedPercent.value) / 100) })
        if (cfg.showGpu && hub.gpus.length > 0)
            rows.push({ label: i18n("GPU"), icon: Qt.resolvedUrl("icons/sf/gpu.svg"),
                        value: pct(hub.num(hub.gpus[0].usage.value)),
                        valueColor: colors.foreground })
        if (cfg.showBattery && hub.hasBattery)
            rows.push({ label: i18n("Battery"), icon: Qt.resolvedUrl("icons/sf/battery.svg"),
                        value: hub.batteryPercent + "%",
                        valueColor: view.batteryColor(hub.batteryPercent / 100, hub.batteryState) })
        return rows
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
                    radius: 10
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

                // macOS bar-style rows: label + inset track sparkline +
                // mono rate.
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

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: compact ? 20 : 24
                        radius: 8
                        color: colors.controlFill
                        border.width: 1
                        border.color: colors.separator

                        KStats.Sparkline {
                            anchors.fill: parent
                            anchors.margins: 3
                            samples: hub.downHistory
                            autoSample: false
                            maxValue: hub.downScale
                            lineColor: colors.accent
                            showFill: true
                        }
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

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: compact ? 20 : 24
                        radius: 8
                        color: colors.controlFill
                        border.width: 1
                        border.color: colors.separator

                        KStats.Sparkline {
                            anchors.fill: parent
                            anchors.margins: 3
                            samples: hub.upHistory
                            autoSample: false
                            maxValue: hub.upScale
                            lineColor: netUpColor
                            showFill: true
                        }
                    }

                    Text {
                        text: String(hub.netUp.formattedValue ?? "")
                        color: colors.foreground
                        font.family: view.monoFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }

                Rectangle {
                    visible: cfg.showNetGraph
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * (compact ? 1.8 : 2.2)
                    radius: 10
                    color: colors.controlFill
                    border.width: 1
                    border.color: colors.separator

                    KStats.Sparkline {
                        anchors.fill: parent
                        anchors.margins: 5
                        samples: hub.downHistory
                        autoSample: false
                        maxValue: hub.downScale
                        lineColor: colors.accent
                        showFill: true
                        scaleColor: colors.labelTertiary
                    }
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
                        id: gpuBlock
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
                                width: parent.width * Math.max(0, Math.min(1, gpuBlock.level))
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

    component BatterySection: ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        GlassCard {
            visible: hub.hasBattery
            Layout.fillWidth: true
            pad: view.cardPad

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                SectionHeader {
                    title: i18n("Battery")
                    iconName: Qt.resolvedUrl("icons/sf/battery.svg")
                    value: hub.batteryPercent + "%"
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Item {
                        Layout.preferredWidth: 58
                        Layout.preferredHeight: 16

                        // Battery body outline
                        Rectangle {
                            anchors.fill: parent
                            anchors.rightMargin: 3
                            radius: 4.5
                            color: "transparent"
                            border.width: 1.5
                            border.color: Qt.rgba(colors.foreground.r, colors.foreground.g, colors.foreground.b, 0.55)

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: 2.5
                                color: view.batteryColor(hub.batteryPercent / 100, hub.batteryState)
                                width: (parent.width - 4) * Math.max(0, Math.min(1, hub.batteryPercent / 100))

                                Behavior on width {
                                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                }
                            }
                        }

                        // Terminal nub
                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 2.5
                            height: parent.height * 0.45
                            radius: 1.25
                            color: Qt.rgba(colors.foreground.r, colors.foreground.g, colors.foreground.b, 0.55)
                        }
                    }

                    Text {
                        text: {
                            var state = hub.batteryState
                            if (hub.batteryPlugged && (state === 3 || hub.batteryPercent >= 100))
                                return i18n("Fully charged")
                            return view.batteryStateText(state, hub.batteryRemainingMsec)
                        }
                        color: colors.labelSecondary
                        font.family: "Inter"
                        font.pixelSize: 12
                    }
                }
            }
        }
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

    // Ordered section card map, consumed by the content Repeater.
    readonly property var sectionComponents: ({
        "cpu": cpuSectionComp,
        "memory": memorySectionComp,
        "network": networkSectionComp,
        "disk": diskSectionComp,
        "gpu": gpuSectionComp,
        "battery": batterySectionComp
    })

    Component { id: cpuSectionComp; CpuSection {} }
    Component { id: memorySectionComp; MemorySection {} }
    Component { id: networkSectionComp; NetworkSection {} }
    Component { id: diskSectionComp; DiskSection {} }
    Component { id: gpuSectionComp; GpuSection {} }
    Component { id: batterySectionComp; BatterySection {} }
}
