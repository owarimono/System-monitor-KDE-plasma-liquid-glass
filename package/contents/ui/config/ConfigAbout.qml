import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: page

    readonly property var metadata: {
        // metadata.json is not exposed to QML; keep the essential facts in
        // sync with it here.
        return {
            name: "System Monitor (Glass)",
            version: "0.5.0",
            website: "https://github.com/owarimono/system-monitor-kde",
            license: "GPL-3.0"
        }
    }

    spacing: 12

    Kirigami.Icon {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 64
        Layout.preferredHeight: 64
        source: Qt.resolvedUrl("../icons/appicon.svg")
    }

    QQC2.Label {
        Layout.alignment: Qt.AlignHCenter
        text: page.metadata.name
        font.weight: Font.DemiBold
        font.pixelSize: 15
    }

    QQC2.Label {
        Layout.alignment: Qt.AlignHCenter
        text: i18n("Version %1", page.metadata.version)
        opacity: 0.7
    }

    QQC2.Label {
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: 380
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: i18n("A macOS-style system monitor widget with a liquid glass background. "
                   + "Data comes from the KDE system statistics daemon (ksystemstats).")
    }

    QQC2.Button {
        Layout.alignment: Qt.AlignHCenter
        icon.name: "internet-services"
        text: i18n("Project website")
        onClicked: Qt.openUrlExternally(page.metadata.website)
    }

    QQC2.Label {
        Layout.alignment: Qt.AlignHCenter
        text: i18n("Licensed under %1", page.metadata.license)
        opacity: 0.7
        font.pixelSize: 11
    }
}
