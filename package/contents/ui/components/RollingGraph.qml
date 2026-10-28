import QtQuick

// Rolling line graph with a soft gradient fill (macOS chart style).
// Feed it a plain JS array of samples plus a revision bump; it repaints
// lazily. Max can be fixed (usage graphs) or derived from the data
// (throughput graphs).

Canvas {
    id: root

    property var values: []
    property real maxValue: 100           // <= 0 = auto-scale from data
    property real autoMaxFloor: 1         // keeps tiny traffic readable
    property real revision: 0             // bump after mutating `values`
    property color lineColor: "#0a84ff"
    property color fillColor: lineColor
    property real fillTopAlpha: 0.30
    property real lineWidth: 2

    onRevisionChanged: requestPaint()
    onValuesChanged: requestPaint()
    onMaxValueChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onFillColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const w = width
        const h = height
        const data = root.values
        // `values` can transiently be undefined while the owning component
        // is still initializing; skip the frame.
        if (!data || data.length < 2 || w <= 1 || h <= 1) return

        let max = root.maxValue
        if (max <= 0) {
            let peak = root.autoMaxFloor
            for (let i = 0; i < data.length; i++)
                peak = Math.max(peak, data[i])
            max = peak * 1.15
        }

        const n = data.length
        const stepX = w / (n - 1)
        const y = (v) => h - Math.max(0, Math.min(1, v / max)) * (h - root.lineWidth) - 1

        // Smooth path through sample midpoints.
        ctx.beginPath()
        ctx.moveTo(0, y(data[0]))
        for (let i = 1; i < n - 1; i++) {
            const mx = i * stepX + stepX / 2
            const my = (y(data[i]) + y(data[i + 1])) / 2
            ctx.quadraticCurveTo(i * stepX, y(data[i]), mx, my)
        }
        ctx.lineTo(w, y(data[n - 1]))

        // Fill: extend the path down to the baseline and close it.
        ctx.lineTo(w, h)
        ctx.lineTo(0, h)
        ctx.closePath()
        const grad = ctx.createLinearGradient(0, 0, 0, h)
        grad.addColorStop(0, Qt.rgba(root.fillColor.r, root.fillColor.g,
                                     root.fillColor.b, root.fillTopAlpha)
                             .toString())
        grad.addColorStop(1, Qt.rgba(root.fillColor.r, root.fillColor.g,
                                     root.fillColor.b, 0).toString())
        ctx.fillStyle = grad
        ctx.fill()

        // Stroke the line itself.
        ctx.beginPath()
        ctx.moveTo(0, y(data[0]))
        for (let j = 1; j < n - 1; j++) {
            const mx2 = j * stepX + stepX / 2
            const my2 = (y(data[j]) + y(data[j + 1])) / 2
            ctx.quadraticCurveTo(j * stepX, y(data[j]), mx2, my2)
        }
        ctx.lineTo(w, y(data[n - 1]))
        ctx.lineWidth = root.lineWidth
        ctx.lineJoin = "round"
        ctx.lineCap = "round"
        ctx.strokeStyle = String(root.lineColor)
        ctx.stroke()
    }
}
