import QtQuick

// Per-core usage tiles, macOS-mockup style: rounded square per core with
// the fill rising from the bottom and the core number underneath.
// Values come from the host widget's ksysguard sensor layer.

Item {
    id: root

    property int count: 0
    property var sensorAt: null          // function(index) -> Sensors.Sensor
    property color fillColor: "#0a84ff"
    property color trackColor: Qt.rgba(1, 1, 1, 0.08)
    property color labelColor: Qt.rgba(1, 1, 1, 0.4)
    property int updateRateLimit: 1500

    implicitHeight: tileHeight + 4 + 12

    readonly property int tileHeight: 34

    Row {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 4

        Repeater {
            id: rep
            model: root.count

            delegate: Column {
                width: (row.width - (rep.count - 1) * row.spacing)
                       / Math.max(1, rep.count)
                spacing: 4

                readonly property real usage: {
                    const s = root.sensorAt ? root.sensorAt(index) : null
                    const v = s ? Number(s.value) : 0
                    return isFinite(v) ? Math.max(0, Math.min(100, v)) / 100 : 0
                }

                Rectangle {
                    id: tile
                    width: parent.width
                    height: root.tileHeight
                    radius: 6
                    color: root.trackColor
                    clip: true

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: parent.height * parent.usage
                        radius: 5
                        color: root.fillColor

                        Behavior on height {
                            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: index + 1
                    color: root.labelColor
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                }
            }
        }
    }
}
