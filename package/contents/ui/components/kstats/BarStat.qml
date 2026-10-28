// Adapted from KStats — https://github.com/oowl/kstats
// MIT License — Copyright (c) 2026 Jun Ouyang (see LICENSES/KStats-MIT.txt)
// Modifications for System Monitor (Glass):
//   - KStats read the label/value font sizes from its own plasmoid
//     configuration; here they are plain component properties
//     (0 = follow Kirigami small font).
//   - valueSlot reserves width for a representative value string (KStats'
//     fixed-slot trick) so longer formatted rates do not elide, and
//     meterWidth (0 = automatic) lets host cards widen the meter.
//   - stretch mode: the row fills the host width and the meter flexes —
//     KStats pinned every width for its compact dropdown columns, which
//     misaligned rows in a full-width card.
//   - fixedLabelWidth aligns the label column across sibling rows.
//   - Meter colors (track fill, border) are exposed as properties so the
//     glass card can theme them from its own palette; meter corners are
//     slightly rounder and text uses the bundled Inter font.

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import "." as Local

RowLayout {
    id: stat

    property string label
    property string value
    property real percent: 0
    property color accentColor: Kirigami.Theme.highlightColor
    property color valueColor: Kirigami.Theme.textColor
    property color meterColor: Qt.rgba(0, 0, 0, 0.86)
    property color meterBorderColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.32)
    property bool showMeter: true
    property string previewMode: "sparkline"
    property string valueSlot: showMeter ? "100.0%" : value
    property real meterWidth: 0
    property bool stretch: false
    property real fixedLabelWidth: 0
    property int labelPixelSize: 0
    property int valuePixelSize: 0
    readonly property real labelWidth: fixedLabelWidth > 0
        ? fixedLabelWidth
        : Math.max(labelText.implicitWidth, stat.label.length <= 1 ? Kirigami.Units.gridUnit * 0.7 : Kirigami.Units.gridUnit * 1.25)
    readonly property real valueWidth: showMeter ? valueMetrics.width + 1 : Kirigami.Units.gridUnit * 3
    readonly property real autoMeterWidth: previewMode === "bar" ? Kirigami.Units.gridUnit * 0.85 : Kirigami.Units.gridUnit * 2.2
    readonly property real previewWidth: showMeter
        ? (stat.meterWidth > 0 ? stat.meterWidth : autoMeterWidth)
        : 0
    readonly property real fixedWidth: labelWidth + valueWidth + (showMeter ? previewWidth + spacing * 2 : spacing)

    spacing: Math.max(1, Kirigami.Units.smallSpacing / 4)
    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: stat.stretch
    Layout.minimumWidth: stat.stretch ? 0 : fixedWidth
    Layout.preferredWidth: stat.stretch ? -1 : fixedWidth
    Layout.maximumWidth: stat.stretch ? Infinity : fixedWidth
    implicitWidth: fixedWidth

    TextMetrics {
        id: valueMetrics

        font: valueText.font
        text: stat.valueSlot
    }

    Controls.Label {
        id: labelText

        text: stat.label
        color: stat.accentColor
        elide: Text.ElideRight
        font.pixelSize: stat.labelPixelSize > 0 ? stat.labelPixelSize : Kirigami.Theme.smallFont.pixelSize
        font.family: "Inter"
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignRight
        Layout.minimumWidth: stat.labelWidth
        Layout.preferredWidth: stat.labelWidth
        Layout.maximumWidth: stat.labelWidth
    }

    Rectangle {
        visible: stat.showMeter
        clip: true
        Layout.fillWidth: stat.stretch
        Layout.minimumWidth: stat.stretch ? 0 : stat.previewWidth
        Layout.preferredWidth: stat.stretch ? -1 : stat.previewWidth
        Layout.maximumWidth: stat.stretch ? Infinity : stat.previewWidth
        Layout.preferredHeight: Math.max(Kirigami.Units.gridUnit * 0.9, stat.height - Kirigami.Units.smallSpacing)
        radius: 3
        color: stat.meterColor
        border.width: 1
        border.color: stat.meterBorderColor

        Rectangle {
            visible: stat.previewMode === "sparkline"
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * Math.max(0, Math.min(100, stat.percent)) / 100
            color: Qt.rgba(stat.accentColor.r, stat.accentColor.g, stat.accentColor.b, 0.28)

            Behavior on height {
                NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
            }
        }

                    Rectangle {
                        visible: stat.previewMode === "bar"
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 2
                        anchors.rightMargin: 2
                        anchors.bottomMargin: 2
                        height: Math.max(0, parent.height - 4) * Math.max(0, Math.min(100, stat.percent)) / 100
                        color: Qt.rgba(stat.accentColor.r, stat.accentColor.g, stat.accentColor.b, 0.72)

                        Behavior on height {
                            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                        }
                    }

        Local.Sparkline {
            visible: stat.previewMode === "sparkline"
            anchors.fill: parent
            anchors.margins: 2
            sampleValue: stat.percent
            sampleLimit: 24
            lineColor: stat.accentColor
            showFill: true
        }
    }

    Controls.Label {
        id: valueText

        text: stat.value
        color: stat.valueColor
        elide: Text.ElideRight
        font.pixelSize: stat.valuePixelSize > 0 ? stat.valuePixelSize : Kirigami.Theme.smallFont.pixelSize
        font.family: "JetBrains Mono"
        font.weight: Font.Medium
        font.features: { "tnum": 1 }
        horizontalAlignment: Text.AlignRight
        Layout.minimumWidth: stat.valueWidth
        Layout.preferredWidth: stat.valueWidth
        Layout.maximumWidth: stat.valueWidth
    }
}
