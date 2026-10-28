import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// Which sections appear, how fast values refresh and how much history
// the graphs keep.

Kirigami.FormLayout {
    id: page

    property int cfg_updateInterval: 2000
    property int cfg_graphDuration: 120

    property alias cfg_showCpu: cpuCheck.checked
    property alias cfg_showPerCore: perCoreCheck.checked
    property alias cfg_showCpuGraph: cpuGraphCheck.checked
    property alias cfg_showMemory: memoryCheck.checked
    property alias cfg_showNetwork: networkCheck.checked
    property alias cfg_showNetGraph: netGraphCheck.checked
    property alias cfg_showDisk: diskCheck.checked
    property alias cfg_showGpu: gpuCheck.checked
    property alias cfg_showTemp: tempCheck.checked

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

    QQC2.CheckBox {
        id: cpuCheck
        text: i18n("CPU")
    }
    QQC2.CheckBox {
        id: perCoreCheck
        anchors.left: parent.left
        anchors.leftMargin: 24
        enabled: cpuCheck.checked
        text: i18n("Per-core usage bars")
    }
    QQC2.CheckBox {
        id: cpuGraphCheck
        anchors.left: parent.left
        anchors.leftMargin: 24
        enabled: cpuCheck.checked
        text: i18n("CPU usage graph")
    }
    QQC2.CheckBox {
        id: tempCheck
        anchors.left: parent.left
        anchors.leftMargin: 24
        enabled: cpuCheck.checked
        text: i18n("CPU temperature (when sensors are available)")
    }

    QQC2.CheckBox {
        id: memoryCheck
        text: i18n("Memory")
    }

    QQC2.CheckBox {
        id: networkCheck
        text: i18n("Network")
    }
    QQC2.CheckBox {
        id: netGraphCheck
        anchors.left: parent.left
        anchors.leftMargin: 24
        enabled: networkCheck.checked
        text: i18n("Throughput graphs")
    }

    QQC2.CheckBox {
        id: diskCheck
        text: i18n("Disk")
    }

    QQC2.CheckBox {
        id: gpuCheck
        text: i18n("GPU (shown only when a GPU is detected)")
    }
}
