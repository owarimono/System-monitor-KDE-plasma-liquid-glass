import QtQuick

// One thin rounded bar per logical CPU core, filled from the bottom.
// Bars read their per-core Sensor objects from SensorHub's Instantiator
// (passed in as the sensorAt accessor plus a count).

Item {
    id: root

    property int count: 0
    property var sensorAt: null          // function(index) -> Sensors.Sensor
    property color fillColor: "#0a84ff"
    property color trackColor: Qt.rgba(1, 1, 1, 0.12)

    implicitHeight: 34

    Row {
        id: row
        anchors.fill: parent
        spacing: 3

        Repeater {
            id: rep
            model: root.count

            delegate: Item {
                width: (row.width - (rep.count - 1) * row.spacing)
                       / Math.max(1, rep.count)
                height: row.height

                readonly property real usage: {
                    const s = root.sensorAt ? root.sensorAt(index) : null
                    const v = s ? Number(s.value) : 0
                    return isFinite(v) ? Math.max(0, Math.min(100, v)) / 100 : 0
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: root.trackColor
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.height * parent.usage
                    radius: width / 2
                    color: root.fillColor

                    Behavior on height {
                        NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}
