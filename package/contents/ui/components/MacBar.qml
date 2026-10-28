import QtQuick

// macOS-style progress bar: inset rounded track, a gradient fill with a
// glossy leading cap, and an eased width animation.

Rectangle {
    id: bar

    property real level: 0                  // 0..1
    property color fillColor: "#0a84ff"
    property color trackColor: Qt.rgba(1, 1, 1, 0.10)
    property color trackBorderColor: Qt.rgba(1, 1, 1, 0.06)
    property color capColor: Qt.rgba(1, 1, 1, 0.45)

    radius: height / 2
    color: trackColor
    border.width: 1
    border.color: trackBorderColor
    clip: true

    Rectangle {
        id: fill

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 1
        width: Math.max(height,
                        (parent.width - 2) * Math.max(0, Math.min(1, bar.level)))
        radius: height / 2 - 1

        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(bar.fillColor, 1.3) }
            GradientStop { position: 1.0; color: bar.fillColor }
        }

        Behavior on width {
            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
        }

        // Glossy cap on the leading edge.
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 1.5
            width: 3
            radius: 1.5
            color: bar.capColor
            visible: parent.width > 10
        }
    }
}
