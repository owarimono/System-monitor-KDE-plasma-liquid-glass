// Adapted from KStats — https://github.com/oowl/kstats
// MIT License — Copyright (c) 2026 Jun Ouyang (see LICENSES/KStats-MIT.txt)
// Modifications for System Monitor (Glass):
//   - KStats polled /proc/stat itself through its RunCommand helper; here
//     the per-core values come from the host widget's ksysguard sensor
//     layer (sensorAt accessor + count) and the chart repaints on a timer.
//   - The internal header row was removed (the host card provides section
//     chrome); average() is exposed for the host to render.
//   - Colors are exposed as properties so the glass card themes them.

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

Rectangle {
    id: root

    property int count: 0
    property var sensorAt: null                 // function(index) -> Sensors.Sensor
    property int refreshInterval: 1500
    property color barColor: Kirigami.Theme.positiveTextColor
    property color trackColor: Kirigami.Theme.textColor
    property color gridColor: Kirigami.Theme.disabledTextColor

    radius: Kirigami.Units.cornerRadius
    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
    border.width: 1
    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

    Layout.fillWidth: true
    implicitHeight: Kirigami.Units.gridUnit * 3.6

    function coreValue(i) {
        var sensor = root.sensorAt ? root.sensorAt(i) : null;
        if (!sensor) {
            return 0;
        }
        var value = Number(sensor.value);
        return isFinite(value) ? Math.max(0, Math.min(100, value)) : 0;
    }

    function average() {
        if (root.count === 0) {
            return 0;
        }
        var total = 0;
        for (var i = 0; i < root.count; i++) {
            total += root.coreValue(i);
        }
        return total / root.count;
    }

    Timer {
        interval: root.refreshInterval
        repeat: true
        running: root.visible
        onTriggered: chart.requestPaint()
    }

    Canvas {
        id: chart

        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        antialiasing: true

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            if (width <= 0 || height <= 0) {
                return;
            }

            var fontSize = Math.max(9, Kirigami.Theme.smallFont.pixelSize - 1);
            ctx.font = fontSize + "px sans-serif";

            var labelWidth = Math.ceil(ctx.measureText("100%").width + Kirigami.Units.smallSpacing);
            var labelBottom = root.count > 0 ? fontSize + 2 : 0;
            var plotLeft = labelWidth;
            var plotTop = 1;
            var plotWidth = Math.max(1, width - plotLeft);
            var plotHeight = Math.max(1, height - plotTop - labelBottom);
            var gridTicks = [100, 50, 0];

            ctx.lineWidth = 1;
            ctx.strokeStyle = root.trackColor;
            ctx.fillStyle = root.gridColor;
            ctx.textBaseline = "middle";

            for (var tickIndex = 0; tickIndex < gridTicks.length; tickIndex++) {
                var tick = gridTicks[tickIndex];
                var y = plotTop + plotHeight - (tick / 100 * plotHeight);
                var labelY = Math.max(fontSize / 2, Math.min(height - labelBottom - fontSize / 2, y));
                ctx.globalAlpha = 0.68;
                ctx.fillText(tick.toString() + "%", 0, labelY);
                ctx.globalAlpha = tick === 0 || tick === 100 ? 0.08 : 0.14;
                ctx.beginPath();
                ctx.moveTo(plotLeft, y);
                ctx.lineTo(width, y);
                ctx.stroke();
            }

            if (root.count === 0) {
                return;
            }

            var gap = Math.max(2, Math.min(5, plotWidth / Math.max(1, root.count * 10)));
            var barWidth = Math.max(2, (plotWidth - gap * Math.max(0, root.count - 1)) / root.count);
            var labelEvery = barWidth >= 14 ? 1 : barWidth >= 7 ? 2 : 4;

            for (var i = 0; i < root.count; i++) {
                var usage = root.coreValue(i);
                var x = plotLeft + i * (barWidth + gap);
                var barHeight = Math.max(1, usage / 100 * plotHeight);
                var yTop = plotTop + plotHeight - barHeight;

                ctx.fillStyle = root.barColor;
                ctx.globalAlpha = 0.88;
                ctx.fillRect(x, yTop, barWidth, barHeight);

                ctx.fillStyle = root.trackColor;
                ctx.globalAlpha = 0.08;
                ctx.fillRect(x, plotTop, barWidth, plotHeight - barHeight);

                if (i % labelEvery === 0) {
                    ctx.fillStyle = root.gridColor;
                    ctx.globalAlpha = 0.58;
                    ctx.textAlign = "center";
                    ctx.textBaseline = "alphabetic";
                    ctx.fillText(i.toString(), x + barWidth / 2, height);
                }
            }
        }
    }
}
