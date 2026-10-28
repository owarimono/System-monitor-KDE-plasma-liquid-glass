import QtQuick

// Rounded horizontal meter with an eased fill, macOS toggle-track style.

Item {
    id: root

    property real level: 0               // 0..1
    property color fillColor: "#0a84ff"
    property color trackColor: Qt.rgba(1, 1, 1, 0.12)
    property real barHeight: 8

    implicitHeight: barHeight

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.barHeight
        radius: height / 2
        color: root.trackColor
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * Math.max(0, Math.min(1, root.level))
        height: root.barHeight
        radius: height / 2
        color: root.fillColor

        Behavior on width {
            NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
        }
    }
}
