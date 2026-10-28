// Adapted from KStats — https://github.com/oowl/kstats
// MIT License — Copyright (c) 2026 Jun Ouyang (see LICENSES/KStats-MIT.txt)
// Modifications for System Monitor (Glass): optional colored leading dot
// (macOS memory-breakdown style), small Inter label, semibold JetBrains
// Mono value; colors are exposed as properties so the glass card themes
// them from its palette.

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

RowLayout {
    id: row

    property string label
    property string value
    property color labelColor: Kirigami.Theme.disabledTextColor
    property color valueColor: Kirigami.Theme.textColor
    property color dotColor: "transparent"

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    Rectangle {
        visible: row.dotColor.a > 0
        Layout.preferredWidth: 8
        Layout.preferredHeight: 8
        radius: 4
        color: row.dotColor
    }

    Controls.Label {
        text: row.label
        color: row.labelColor
        elide: Text.ElideRight
        font.family: "Inter"
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        Layout.fillWidth: true
    }

    Controls.Label {
        text: row.value
        color: row.valueColor
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideMiddle
        font.family: "JetBrains Mono"
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        font.weight: Font.DemiBold
        Layout.maximumWidth: Kirigami.Units.gridUnit * 12
    }
}
