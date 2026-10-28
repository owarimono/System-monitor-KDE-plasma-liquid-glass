// Adapted from KStats — https://github.com/oowl/kstats
// MIT License — Copyright (c) 2026 Jun Ouyang (see LICENSES/KStats-MIT.txt)
// Modifications for System Monitor (Glass):
//   - maxValue property: samples are normalized against maxValue instead of
//     a hard-coded 0..100 percent clamp, so byte-rate series (network)
//     plot correctly. Scale ticks and labels follow maxValue.
//   - the line is smoothed with quadratic midpoints and the fill fades
//     through a vertical gradient (straight segments + flat fill in
//     upstream); scale text uses the bundled Inter font.

import QtQuick

import org.kde.kirigami as Kirigami

Canvas {
    id: spark
    clip: true

    property real sampleValue: 0
    property int sampleLimit: 36
    property var samples: []
    property bool autoSample: true
    property real maxValue: 100
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
    Component.onCompleted: if (autoSample) addSample(sampleValue)

    function addSample(value) {
        var numeric = Number(value);
        if (!isFinite(numeric)) {
            numeric = 0;
        }

        var ceiling = Math.max(1, spark.maxValue);
        var next = samples.slice(0);
        next.push(Math.max(0, Math.min(ceiling, numeric)));
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

        var ceiling = Math.max(1, spark.maxValue);
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
        var step = plotWidth / Math.max(1, sampleLimit - 1);

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

        // Smooth the series with quadratic midpoints, then fade the fill
        // through a vertical gradient.
        function trace() {
            ctx.beginPath();
            var lastX = plotLeft + plotWidth - (samples.length - 1) * step;
            var lastY = plotTop + plotHeight - (samples[0] / ceiling * plotHeight);
            ctx.moveTo(lastX, lastY);
            for (var i = 0; i < samples.length; i++) {
                var x = plotLeft + plotWidth - (samples.length - 1 - i) * step;
                var y = plotTop + plotHeight - (samples[i] / ceiling * plotHeight);
                if (i === 0) {
                    ctx.moveTo(x, y);
                } else if (i < samples.length - 1) {
                    var nx = plotLeft + plotWidth - (samples.length - 2 - i) * step;
                    var ny = plotTop + plotHeight - (samples[i + 1] / ceiling * plotHeight);
                    ctx.quadraticCurveTo(x, y, (x + nx) / 2, (y + ny) / 2);
                } else {
                    ctx.lineTo(x, y);
                }
            }
        }

        if (showFill) {
            trace();
            // trace() ends at the leftmost sample; walk the baseline back
            // to the right edge, then close up to the path start — inset a
            // pixel so nothing paints on the very edge of the item.
            ctx.lineTo(plotLeft, plotTop + plotHeight - 1);
            ctx.lineTo(plotLeft + plotWidth, plotTop + plotHeight - 1);
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
    }
}
