import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQC

// Per-metric accent colors. An empty value follows the accent theme.

Kirigami.FormLayout {
    id: page

    property string cfg_cpuColor: ""
    property string cfg_memoryColor: ""
    property string cfg_netDownColor: ""
    property string cfg_netUpColor: ""
    property string cfg_gpuColor: ""

    readonly property string fallbackAccent: "#0a84ff"

    signal syncValues()

    function colorFor(value) {
        return value === "" ? fallbackAccent : value
    }

    function resetAll() {
        cfg_cpuColor = ""
        cfg_memoryColor = ""
        cfg_netDownColor = ""
        cfg_netUpColor = ""
        cfg_gpuColor = ""
        syncValues()
    }

    Component.onCompleted: syncValues()

    component MetricColorRow: RowLayout {
        id: row

        property string title
        property string value
        signal changed(string color)

        function sync() {
            button.color = page.colorFor(row.value)
        }

        Kirigami.FormData.label: title + ":"
        Layout.fillWidth: true

        KQC.ColorButton {
            id: button
            showAlphaChannel: false
            Component.onCompleted: row.sync()
            onColorChanged: {
                const s = String(color)
                if (s !== page.colorFor(row.value))
                    row.changed(s)
            }
            Connections {
                target: row
                function onValueChanged() { row.sync() }
            }
            Connections {
                target: page
                function onSyncValues() { row.sync() }
            }
        }

        QQC2.ToolButton {
            icon.name: "edit-reset"
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.text: i18n("Follow the accent theme")
            onClicked: row.changed("")
        }
    }

    MetricColorRow {
        title: i18n("CPU")
        value: page.cfg_cpuColor
        onChanged: (color) => page.cfg_cpuColor = color
    }

    MetricColorRow {
        title: i18n("Memory")
        value: page.cfg_memoryColor
        onChanged: (color) => page.cfg_memoryColor = color
    }

    MetricColorRow {
        title: i18n("Download")
        value: page.cfg_netDownColor
        onChanged: (color) => page.cfg_netDownColor = color
    }

    MetricColorRow {
        title: i18n("Upload")
        value: page.cfg_netUpColor
        onChanged: (color) => page.cfg_netUpColor = color
    }

    MetricColorRow {
        title: i18n("GPU")
        value: page.cfg_gpuColor
        onChanged: (color) => page.cfg_gpuColor = color
    }

    QQC2.Button {
        icon.name: "edit-reset"
        text: i18n("Reset all to accent theme")
        onClicked: page.resetAll()
    }

    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: i18n("Leave a color empty to follow the accent theme selected in Appearance.")
        color: Kirigami.Theme.disabledTextColor
        font.pixelSize: 11
    }
}
