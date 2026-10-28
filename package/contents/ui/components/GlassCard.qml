import QtQuick
import QtQuick.Layouts

// A second-layer glass section card, Tahoe style: a soft vertical white
// gradient over the parent's frosted backdrop, a hairline border and a
// crisp top highlight. Auto-sizes to its content so rows never overflow.

Rectangle {
    id: card

    default property alias content: cardLayout.data
    property int pad: 16

    radius: 18
    border.width: 1
    border.color: colors.cardBorder
    implicitHeight: cardLayout.implicitHeight + card.pad * 2

    gradient: Gradient {
        GradientStop { position: 0.0; color: colors.cardFillTop }
        GradientStop { position: 1.0; color: colors.cardFillBottom }
    }

    // Soft top luminance: fades out over a few pixels instead of a crisp
    // 1px line, which read as a floating stripe over the translucent fill.
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        height: 6
        gradient: Gradient {
            GradientStop { position: 0.0; color: colors.cardHighlight }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    ColumnLayout {
        id: cardLayout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: card.pad
        spacing: 10
    }
}
