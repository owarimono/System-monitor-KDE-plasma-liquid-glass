import QtQuick

// macOS activity-style ring gauge with rounded caps and a gradient arc.
// The drawn value eases toward the target so gauge motion feels like
// Apple's rings instead of snapping between samples.

Item {
    id: root

    property real value: 0                 // target, 0..1
    property color ringColor: "#0a84ff"
    property color ringColor2: ringColor   // second gradient stop
    property color trackColor: Qt.rgba(1, 1, 1, 0.14)
    property real lineWidth: 8
    property real startAngle: -90          // degrees, 0 = 3 o'clock

    property real shown: 0
    Behavior on shown {
        NumberAnimation { duration: 700; easing.type: Easing.OutCubic }
    }
    onValueChanged: root.shown = root.clamped()
    Component.onCompleted: root.shown = root.clamped()

    function clamped() {
        return Math.max(0, Math.min(1, root.value))
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        Connections {
            target: root
            function onShownChanged() { canvas.requestPaint() }
            function onRingColorChanged() { canvas.requestPaint() }
            function onRingColor2Changed() { canvas.requestPaint() }
            function onTrackColorChanged() { canvas.requestPaint() }
            function onLineWidthChanged() { canvas.requestPaint() }
            function onStartAngleChanged() { canvas.requestPaint() }
        }

        onPaint: {
            const ctx = canvas.getContext("2d")
            ctx.reset()
            ctx.lineWidth = root.lineWidth
            ctx.lineCap = "round"

            const cx = width / 2
            const cy = height / 2
            const r = Math.min(width, height) / 2 - root.lineWidth / 2
            if (r <= 0) return

            // Track
            ctx.beginPath()
            ctx.strokeStyle = String(root.trackColor)
            ctx.arc(cx, cy, r, 0, 2 * Math.PI)
            ctx.stroke()

            // Value arc
            const frac = Math.max(0, Math.min(1, root.shown))
            if (frac <= 0.002) return
            const a0 = root.startAngle * Math.PI / 180
            const a1 = a0 + frac * 2 * Math.PI

            const grad = ctx.createLinearGradient(cx - r, cy - r, cx + r, cy + r)
            grad.addColorStop(0, String(root.ringColor))
            grad.addColorStop(1, String(root.ringColor2))
            ctx.strokeStyle = grad
            ctx.beginPath()
            ctx.arc(cx, cy, r, a0, a1)
            ctx.stroke()
        }
    }
}
