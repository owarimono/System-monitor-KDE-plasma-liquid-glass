// Adapted from KStats — https://github.com/oowl/kstats
// MIT License — Copyright (c) 2026 Jun Ouyang (see LICENSES/KStats-MIT.txt)
// Modifications for System Monitor (Glass): label uses the small font
// and the value is semibold with tabular figures; colors are exposed as
// properties so the glass card themes them from its palette.

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

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    Controls.Label {
        text: row.label
        color: row.labelColor
        elide: Text.ElideRight
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        Layout.fillWidth: true
    }

    Controls.Label {
        text: row.value
        color: row.valueColor
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideMiddle
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        font.weight: Font.DemiBold
        font.features: { "tnum": 1 }
        Layout.maximumWidth: Kirigami.Units.gridUnit * 12
    }
}
