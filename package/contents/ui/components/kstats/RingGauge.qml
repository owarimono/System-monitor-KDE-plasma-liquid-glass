// Adapted from KStats — https://github.com/oowl/kstats
// MIT License — Copyright (c) 2026 Jun Ouyang (see LICENSES/KStats-MIT.txt)
// Modifications for System Monitor (Glass):
//   - the center percent label is built without i18nc so the component
//     also loads outside the plasmoid QML context (percent figures need
//     no translation)
//   - center text scales with the ring size — KStats used fixed theme
//     font sizes that overflowed smaller rings
//   - the drawn value eases toward the target (600ms, OutCubic) so the
//     gauge motion feels like Apple's rings
//   - the value arc strokes through a linear gradient (accent -> lighter)
//     with a soft glow, Apple activity-ring style; colors are overridden
//     through the existing properties; text uses the bundled Inter font.

import QtQuick
import QtQuick.Controls as Controls

import org.kde.kirigami as Kirigami

Item {
    id: root

    property real value: 0
    property string label: ""
    property color accentColor: Kirigami.Theme.focusColor
    property color accentColor2: Qt.lighter(accentColor, 1.3)
    property color trackColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.14)
    property color labelColor: Kirigami.Theme.textColor
    property color subLabelColor: Kirigami.Theme.disabledTextColor
    property real lineWidth: Math.max(5, Math.min(width, height) * 0.11)

    property real shown: 0
    Behavior on shown {
        NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
    }
    onValueChanged: root.shown = root.clamped()
    Component.onCompleted: root.shown = root.clamped()

    function clamped() {
        return Math.max(0, Math.min(100, root.value))
    }

    implicitWidth: Kirigami.Units.gridUnit * 5
    implicitHeight: implicitWidth

    onShownChanged: canvas.requestPaint()
    onAccentColorChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas

        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            var size = Math.min(width, height);
            if (size <= 0) {
                return;
            }

            var centerX = width / 2;
            var centerY = height / 2;
            var radius = Math.max(1, (size - root.lineWidth) / 2 - 1);
            var startAngle = -Math.PI / 2;
            var endAngle = startAngle + Math.PI * 2 * Math.max(0, Math.min(100, root.shown)) / 100;

            ctx.lineWidth = root.lineWidth;
            ctx.lineCap = "round";

            ctx.strokeStyle = root.trackColor;
            ctx.globalAlpha = 1;
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, 0, Math.PI * 2, false);
            ctx.stroke();

            var grad = ctx.createLinearGradient(centerX - radius, centerY - radius,
                                                centerX + radius, centerY + radius);
            grad.addColorStop(0, String(root.accentColor));
            grad.addColorStop(1, String(root.accentColor2));
            ctx.strokeStyle = grad;
            ctx.shadowColor = String(Qt.rgba(root.accentColor.r, root.accentColor.g,
                                             root.accentColor.b, 0.45));
            ctx.shadowBlur = 6;
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, startAngle, endAngle, false);
            ctx.stroke();
            ctx.shadowBlur = 0;
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 0

        Controls.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(root.shown) + "%"
            color: root.labelColor
            font.family: "Inter"
            font.pixelSize: Math.max(11, root.width * 0.21)
            font.weight: Font.DemiBold
        }

        Controls.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.label.length > 0
            text: root.label
            color: root.subLabelColor
            font.family: "Inter"
            font.pixelSize: Math.max(8, root.width * 0.13)
            font.weight: Font.Medium
        }
    }
}
