// Adapted from KStats — https://github.com/oowl/kstats
// MIT License — Copyright (c) 2026 Jun Ouyang (see LICENSES/KStats-MIT.txt)
// Modifications for System Monitor (Glass):
//   - maxValue property: samples are normalized against maxValue instead of
//     a hard-coded 0..100 percent clamp, so byte-rate series (network)
//     plot correctly. The axis EASES toward maxValue (auto-range) and all
//     drawn points are clamped to the plot — spikes never leave the frame.
//   - the line is smoothed with a centered moving average plus quadratic
//     midpoints, and the fill fades through a vertical gradient
//   - a glowing current-value dot marks the newest sample
//   - scale text uses the bundled Inter font

import QtQuick

import org.kde.kirigami as Kirigami

Canvas {
    id: spark
    clip: true

    property real sampleValue: 0
    property int sampleLimit: 36
    property var samples: []
    property bool autoSample: true
    property int smoothing: 3                 // display MA radius (samples); 1 = off
    property real maxValue: 100
    // The scale eases toward maxValue so a traffic spike smoothly
    // rescales the whole graph instead of snapping (auto-range).
    property real effMax: maxValue
    Behavior on effMax {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    property color lineColor: "white"
    property bool showFill: false
    property bool showGrid: false
    property bool showScale: false
    property var scaleTicks: [100, 50, 0]
    property string scaleSuffix: "%"
    property color scaleColor: Kirigami.Theme.disabledTextColor

    antialiasing: true

    onSampleValueChanged: if (autoSample) addSample(sampleValue)
    onSamplesChanged: requestPaint()
    onEffMaxChanged: requestPaint()
    Component.onCompleted: if (autoSample) addSample(sampleValue)

    function addSample(value) {
        var numeric = Number(value);
        if (!isFinite(numeric)) {
            numeric = 0;
        }

        var next = samples.slice(0);
        next.push(Math.max(0, numeric));
        while (next.length > sampleLimit) {
            next.shift();
        }
        samples = next;
        requestPaint();
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function scaleLabel(value) {
        return Math.round(value).toString() + scaleSuffix;
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();

        if (samples.length < 2 || width <= 0 || height <= 0) {
            return;
        }

        var ceiling = Math.max(1, spark.effMax);
        var fontSize = Math.max(9, Kirigami.Theme.smallFont.pixelSize - 1);
        ctx.font = fontSize + "px Inter, sans-serif";

        var leftInset = 0;
        if (showScale) {
            for (var measureIndex = 0; measureIndex < scaleTicks.length; measureIndex++) {
                leftInset = Math.max(leftInset, ctx.measureText(scaleLabel(scaleTicks[measureIndex])).width);
            }
            leftInset = Math.ceil(leftInset + Kirigami.Units.smallSpacing);
        }

        var plotLeft = leftInset;
        var plotTop = showScale ? 2 : 0;
        var plotWidth = Math.max(1, width - plotLeft);
        var plotHeight = Math.max(1, height - (showScale ? 4 : 0));
        // Space samples by the ACTUAL series length — sampleLimit only
        // governs the autoSample buffer, and host-provided series (rolling
        // histories) are frequently longer, which used to push points past
        // the left edge and smear the fill outside the plot.
        var step = plotWidth / Math.max(1, samples.length - 1);

        if (showGrid || showScale) {
            ctx.lineWidth = 1;
            ctx.strokeStyle = showScale ? scaleColor : lineColor;

            if (showScale) {
                ctx.fillStyle = scaleColor;
                ctx.textBaseline = "middle";
                ctx.globalAlpha = 0.68;
                for (var tickIndex = 0; tickIndex < scaleTicks.length; tickIndex++) {
                    var tick = Math.max(0, Math.min(ceiling, Number(scaleTicks[tickIndex]) || 0));
                    var ty = plotTop + plotHeight - (tick / ceiling * plotHeight);
                    var labelY = Math.max(fontSize / 2, Math.min(height - fontSize / 2, ty));
                    ctx.fillText(scaleLabel(tick), 0, labelY);
                    ctx.globalAlpha = tick === 0 || tick === ceiling ? 0.10 : 0.16;
                    ctx.beginPath();
                    ctx.moveTo(plotLeft, ty);
                    ctx.lineTo(width, ty);
                    ctx.stroke();
                    ctx.globalAlpha = 0.68;
                }
            } else {
                ctx.globalAlpha = 0.12;
            }

            if (!showScale) {
                for (var grid = 1; grid < 4; grid++) {
                    var gy = plotTop + plotHeight * grid / 4;
                    ctx.beginPath();
                    ctx.moveTo(plotLeft, gy);
                    ctx.lineTo(width, gy);
                    ctx.stroke();
                }
            }
        }

        // Smoothed series: centered moving average tames one-sample
        // bursts into rounded hills (the stored series is untouched).
        function smoothed() {
            var r = Math.max(1, Math.min(6, spark.smoothing >> 1) | 0);
            var out = new Array(samples.length);
            for (var i = 0; i < samples.length; i++) {
                var sum = 0;
                var n = 0;
                for (var k = Math.max(0, i - r); k <= Math.min(samples.length - 1, i + r); k++) {
                    sum += samples[k];
                    n++;
                }
                out[i] = sum / n;
            }
            return out;
        }

        var series = smoothed();

        // Curve through the smoothed values with quadratic midpoints.
        // Every point is HARD-CLAMPED to the plot — a spike that lands
        // before the eased scale catches up can never escape the frame.
        function trace() {
            ctx.beginPath();
            for (var i = 0; i < series.length; i++) {
                var x = plotLeft + plotWidth - (series.length - 1 - i) * step;
                var t = Math.max(0, Math.min(ceiling, series[i])) / ceiling;
                var y = plotTop + 1 + (plotHeight - 2) * (1 - t);
                if (i === 0) {
                    ctx.moveTo(x, y);
                } else if (i < series.length - 1) {
                    var nx = plotLeft + plotWidth - (series.length - 2 - i) * step;
                    var nt = Math.max(0, Math.min(ceiling, series[i + 1])) / ceiling;
                    var ny = plotTop + 1 + (plotHeight - 2) * (1 - nt);
                    ctx.quadraticCurveTo(x, y, (x + nx) / 2, (y + ny) / 2);
                } else {
                    ctx.lineTo(x, y);
                }
            }
        }

        if (showFill) {
            trace();
            // trace() ends at the newest sample (right edge); close the
            // area polygon down the right, along the baseline, and up the
            // left — inset a pixel so nothing paints on the item edge.
            ctx.lineTo(plotLeft + plotWidth, plotTop + plotHeight - 1);
            ctx.lineTo(plotLeft, plotTop + plotHeight - 1);
            ctx.closePath();
            // Fade out by ~80% height so the fill never reads as a shadow
            // pooling at the bottom edge of the card.
            var fillGrad = ctx.createLinearGradient(0, plotTop, 0,
                                                    plotTop + plotHeight * 0.8);
            fillGrad.addColorStop(0, Qt.rgba(lineColor.r, lineColor.g,
                                             lineColor.b, 0.28).toString());
            fillGrad.addColorStop(1, Qt.rgba(lineColor.r, lineColor.g,
                                             lineColor.b, 0).toString());
            ctx.fillStyle = fillGrad;
            ctx.fill();
        }

        ctx.lineWidth = 2;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.strokeStyle = lineColor;
        ctx.globalAlpha = 0.9;
        trace();
        ctx.stroke();

        // Current-value dot at the newest sample — the macOS graph
        // signature: a glowing core over a soft halo.
        var endX = plotLeft + plotWidth - 2;
        var endT = Math.max(0, Math.min(ceiling, series[series.length - 1])) / ceiling;
        var endY = plotTop + 1 + (plotHeight - 2) * (1 - endT);
        ctx.globalAlpha = 0.30;
        ctx.fillStyle = lineColor;
        ctx.beginPath();
        ctx.arc(endX, endY, 5, 0, 2 * Math.PI);
        ctx.fill();
        ctx.globalAlpha = 1;
        ctx.beginPath();
        ctx.arc(endX, endY, 2.6, 0, 2 * Math.PI);
        ctx.fill();
    }
}
