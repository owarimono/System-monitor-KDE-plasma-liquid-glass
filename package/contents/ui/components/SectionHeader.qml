import QtQuick
import org.kde.kirigami as Kirigami

// Section header: small monochrome icon, bold title, optional secondary
// value aligned to the trailing edge.

Item {
    id: root

    property string title: ""
    property string iconName: ""
    property string value: ""
    property color textColor: "#ffffff"
    property color secondaryColor: textColor
    property color iconColor: textColor

    implicitHeight: Math.max(20, titleLabel.implicitHeight)

    Row {
        id: leading
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Kirigami.Icon {
            anchors.verticalCenter: parent.verticalCenter
            width: 15
            height: 15
            visible: root.iconName !== ""
            source: root.iconName
            isMask: true
            color: root.iconColor
        }

        Text {
            id: titleLabel
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            color: root.textColor
            font.pixelSize: 13
            font.weight: Font.DemiBold
            font.letterSpacing: 0.2
        }
    }

    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.value !== ""
        text: root.value
        color: root.secondaryColor
        font.pixelSize: 12
        font.weight: Font.Medium
        elide: Text.ElideMiddle
    }
}
