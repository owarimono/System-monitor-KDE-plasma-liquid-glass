import QtQuick

// Per-core usage tiles, macOS-mockup style: rounded square per core with
// the fill rising from the bottom and the core number underneath.
// Values come from the host widget's ksysguard sensor layer.
//
// Fill height uses a perceptual sqrt scale so near-idle cores (the usual
// state) still read as active; the true percentage is linear underneath.

Item {
    id: root

    property int count: 0
    property var sensorAt: null          // function(index) -> Sensors.Sensor
    property int revision: 0             // bump when sensors materialize
    property color fillColor: "#0a84ff"
    property color trackColor: Qt.rgba(1, 1, 1, 0.08)
    property color labelColor: Qt.rgba(1, 1, 1, 0.4)

    implicitHeight: tileHeight + 4 + 12

    property int tileHeight: 30

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
                id: cell
                // NOTE: with an integer Repeater model, `index` arrives as
                // a context property — declaring it `required` yields NaN.

                readonly property real usage: {
                    void root.revision // re-run once the sensors exist
                    const s = root.sensorAt ? root.sensorAt(index) : null
                    const v = s ? Number(s.value) : 0
                    return isFinite(v) ? Math.max(0, Math.min(100, v)) / 100 : 0
                }
                readonly property real fillLevel: Math.sqrt(cell.usage)

                width: (row.width - (rep.count - 1) * row.spacing)
                       / Math.max(1, rep.count)
                spacing: 4

                Rectangle {
                    width: cell.width
                    height: root.tileHeight
                    radius: 6
                    color: root.trackColor
                    clip: true

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        // Keep a visible sliver when a core is active but
                        // near-idle, so tiles never read as empty boxes.
                        height: Math.max(cell.usage > 0.001 ? 4 : 0,
                                         parent.height * cell.fillLevel)
                        radius: 3
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
