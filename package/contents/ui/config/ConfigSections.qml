import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Which sections appear, in which order, plus every per-section toggle
// and the data refresh settings.

Kirigami.FormLayout {
    id: page

    property int cfg_updateInterval: 2000
    property int cfg_graphDuration: 120
    property var cfg_sectionOrder: ["cpu", "memory", "network", "disk", "gpu"]

    // NOTE: plain properties, not aliases — the order-row checkboxes
    // assign these directly.
    property bool cfg_showHostCard: true
    property bool cfg_clock24: true
    property bool cfg_clockSeconds: true
    property bool cfg_showDate: true
    property bool cfg_showCpu: true
    property bool cfg_showPerCore: true
    property bool cfg_showCpuGraph: true
    property bool cfg_showTemp: true
    property bool cfg_showMemory: true
    property bool cfg_showNetwork: true
    property bool cfg_showNetGraph: true
    property bool cfg_showDisk: true
    property bool cfg_showDiskRates: true
    property bool cfg_showGpu: true
    property bool cfg_showGpuTemp: true
    property bool cfg_showVram: true
    property bool cfg_showBattery: true

    // The canonical section set; `order` is the persisted (or default)
    // display order, normalized so every section is present exactly once.
    readonly property var canonical: [
        { key: "cpu", title: i18n("CPU"), prop: "cfg_showCpu" },
        { key: "memory", title: i18n("Memory"), prop: "cfg_showMemory" },
        { key: "network", title: i18n("Network"), prop: "cfg_showNetwork" },
        { key: "disk", title: i18n("Disk"), prop: "cfg_showDisk" },
        { key: "gpu", title: i18n("GPU"), prop: "cfg_showGpu" },
        { key: "battery", title: i18n("Battery"), prop: "cfg_showBattery" }
    ]
    readonly property var defaultOrder: ["cpu", "memory", "network", "disk", "gpu", "battery"]

    property var order: []

    function normalizeOrder(saved) {
        const list = defaultOrder.filter(k => saved.indexOf(k) >= 0)
        for (const k of defaultOrder)
            if (list.indexOf(k) < 0)
                list.push(k)
        return list
    }

    function persistOrder() {
        cfg_sectionOrder = page.order.slice()
    }

    function move(key, delta) {
        const from = page.order.indexOf(key)
        const to = from + delta
        if (from < 0 || to < 0 || to >= page.order.length)
            return
        page.order.splice(to, 0, page.order.splice(from, 1)[0])
        page.order = page.order.slice()
        persistOrder()
    }

    onCfg_sectionOrderChanged: {
        const saved = Array.isArray(cfg_sectionOrder) ? cfg_sectionOrder : []
        const next = normalizeOrder(saved.map(String))
        if (JSON.stringify(next) !== JSON.stringify(page.order))
            page.order = next
    }

    Component.onCompleted: {
        intervalSpin.value = Math.max(1, Math.round(cfg_updateInterval / 1000))
        durationSpin.value = cfg_graphDuration
        page.order = normalizeOrder(Array.isArray(cfg_sectionOrder) ? cfg_sectionOrder.map(String) : [])
    }

    onCfg_updateIntervalChanged: {
        if (!intervalSpin.activeFocus)
            intervalSpin.value = Math.max(1, Math.round(cfg_updateInterval / 1000))
    }
    onCfg_graphDurationChanged: {
        if (!durationSpin.activeFocus)
            durationSpin.value = cfg_graphDuration
    }

    QQC2.SpinBox {
        id: intervalSpin
        Kirigami.FormData.label: i18n("Update values every:")
        from: 1
        to: 10
        editable: false
        textFromValue: (v) => i18np("%1 second", "%1 seconds", v)
        onValueModified: page.cfg_updateInterval = value * 1000
    }

    QQC2.SpinBox {
        id: durationSpin
        Kirigami.FormData.label: i18n("Graph history:")
        from: 30
        to: 600
        stepSize: 30
        editable: false
        textFromValue: (v) => i18np("%1 second", "%1 seconds", v)
        onValueModified: page.cfg_graphDuration = value
    }

    Item { Kirigami.FormData.isSection: true }

    // ── Host card ────────────────────────────────────────────────────
    QQC2.CheckBox {
        id: hostCardCheck
        checked: page.cfg_showHostCard
        onToggled: page.cfg_showHostCard = checked
        text: i18n("Host card (machine name and clock)")
    }

    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 24
        enabled: hostCardCheck.checked
        spacing: 8

        QQC2.CheckBox {
            id: clock24Check
            checked: page.cfg_clock24
            onToggled: page.cfg_clock24 = checked
            text: i18n("24-hour clock")
        }

        QQC2.CheckBox {
            id: clockSecondsCheck
            checked: page.cfg_clockSeconds
            onToggled: page.cfg_clockSeconds = checked
            text: i18n("Seconds")
        }

        QQC2.CheckBox {
            id: showDateCheck
            checked: page.cfg_showDate
            onToggled: page.cfg_showDate = checked
            text: i18n("Date")
        }
    }

    Item { Kirigami.FormData.isSection: true }

    // ── Section order ────────────────────────────────────────────────
    GroupCaption { caption: i18n("Sections — order and visibility") }

    Repeater {
        model: page.canonical

        delegate: RowLayout {
            required property int index
            required property var modelData

            readonly property var entry: modelData
            readonly property int orderPos: page.order.indexOf(entry.key)

            Layout.fillWidth: true
            spacing: 8

            QQC2.CheckBox {
                checked: page[entry.prop]
                onToggled: page[entry.prop] = checked
                text: entry.title
                Layout.preferredWidth: 180
            }

            Item { Layout.fillWidth: true }

            QQC2.ToolButton {
                icon.name: "arrow-up"
                enabled: orderPos > 0
                onClicked: page.move(entry.key, -1)
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: i18n("Move up")
            }

            QQC2.ToolButton {
                icon.name: "arrow-down"
                enabled: orderPos >= 0 && orderPos < page.order.length - 1
                onClicked: page.move(entry.key, 1)
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: i18n("Move down")
            }
        }
    }

    QQC2.Label {
        text: i18n("Unchecked sections are hidden; the arrows set their order.")
        color: Kirigami.Theme.disabledTextColor
        font.pixelSize: 11
        Layout.fillWidth: true
    }

    Item { Kirigami.FormData.isSection: true }

    // ── Per-section details ──────────────────────────────────────────
    GroupCaption { caption: "CPU" }

    QQC2.CheckBox {
        anchors.left: parent.left
        anchors.leftMargin: 24
        enabled: page.cfg_showCpu
        checked: page.cfg_showPerCore
        onToggled: page.cfg_showPerCore = checked
        text: i18n("Per-core usage tiles")
    }
    QQC2.CheckBox {
        anchors.left: parent.left
        anchors.leftMargin: 24
        enabled: page.cfg_showCpu
        checked: page.cfg_showCpuGraph
        onToggled: page.cfg_showCpuGraph = checked
        text: i18n("Usage graph")
    }
    QQC2.CheckBox {
        anchors.left: parent.left
        anchors.leftMargin: 24
        enabled: page.cfg_showCpu
        checked: page.cfg_showTemp
        onToggled: page.cfg_showTemp = checked
        text: i18n("Temperature (when sensors are available)")
    }

    GroupCaption { caption: i18n("Network") }

    QQC2.CheckBox {
        anchors.left: parent.left
        anchors.leftMargin: 24
        enabled: page.cfg_showNetwork
        checked: page.cfg_showNetGraph
        onToggled: page.cfg_showNetGraph = checked
        text: i18n("Download history graph")
    }

    GroupCaption { caption: i18n("Disk") }

    QQC2.CheckBox {
        anchors.left: parent.left
        anchors.leftMargin: 24
        enabled: page.cfg_showDisk
        checked: page.cfg_showDiskRates
        onToggled: page.cfg_showDiskRates = checked
        text: i18n("Read / write rates")
    }

    GroupCaption { caption: i18n("GPU") }

    QQC2.CheckBox {
        anchors.left: parent.left
        anchors.leftMargin: 24
        enabled: page.cfg_showGpu
        checked: page.cfg_showGpuTemp
        onToggled: page.cfg_showGpuTemp = checked
        text: i18n("Temperatures")
    }
    QQC2.CheckBox {
        anchors.left: parent.left
        anchors.leftMargin: 24
        enabled: page.cfg_showGpu
        checked: page.cfg_showVram
        onToggled: page.cfg_showVram = checked
        text: i18n("VRAM usage")
    }

    GroupCaption { caption: i18n("Battery") }

    QQC2.CheckBox {
        anchors.left: parent.left
        anchors.leftMargin: 24
        enabled: page.cfg_showBattery
        checked: page.cfg_showBattery
        onToggled: page.cfg_showBattery = checked
        text: i18n("Battery pill and charge state (laptops)")
    }

    component GroupCaption: Text {
        property string caption: ""
        text: caption
        color: Kirigami.Theme.disabledTextColor
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.letterSpacing: 0.8
        font.capitalization: Font.AllUppercase
        Layout.fillWidth: true
        bottomPadding: 2
    }
}
