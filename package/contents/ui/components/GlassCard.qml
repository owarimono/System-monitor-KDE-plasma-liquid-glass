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

    // Crisp highlight along the top edge.
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: radius
        anchors.rightMargin: radius
        height: 1
        color: colors.cardHighlight
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
