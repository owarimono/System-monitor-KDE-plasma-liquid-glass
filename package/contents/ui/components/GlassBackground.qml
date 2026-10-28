import QtQuick
import org.kde.plasma.plasmoid

// Frosted / liquid-glass background, macOS style.
//
// Place as the bottom-most child of the widget root and anchors.fill: parent.
//
// Pipeline (glass mode):
//   wallpaper item -> ShaderEffectSource (full capture)
//     -> crop pass (widget region, optionally half-res)
//     -> separable Gaussian blur (horizontal + vertical, half-res)
//     -> glass compose (squircle mask, edge refraction, chroma, tint,
//        specular border, sheen, dither)
//
// The blur chain only renders in short bursts: anything that can change
// the sampled backdrop calls markDirty(), the chain runs live for a short
// settle window, then parks with zero GPU cost. Enable realtimeRefraction
// only for animated wallpapers.
//
// Falls back to a translucent rounded rectangle whenever the wallpaper
// cannot be sampled (panel form factor, plasmoidviewer, solid-less hosts).

Item {
    id: glass

    // ── Shape ─────────────────────────────────────────────────────────
    property real radius: 20             // corner radius in px (exact)

    // ── Material ──────────────────────────────────────────────────────
    property color tint: "#ffffff"
    property real tintAlpha: 0.10
    property real blurRadius: 24            // widget px, 0 = crisp
    property bool refraction: true
    property real edgeBand: 30              // refractive rim width, px
    property real refractionStrength: 26    // max rim displacement, px
    property real chromaStrength: 0.08      // chromatic aberration, 0..1
    property bool specular: true
    property real specStrength: 0.9
    property real edgeStroke: 1.0           // Apple-style inner outline, 0..1
    property bool realtimeRefraction: false

    // ── Solid panel mode (no wallpaper sampling) ──────────────────────
    property bool solidMode: false
    property color solidColor: "#1c1c1e"
    // Opacity of the plain fallback rectangle shown when the wallpaper
    // cannot be sampled (higher than tintAlpha to stay legible without blur).
    property real fallbackOpacity: 0.55

    readonly property bool active: wallpaperItem !== null
                                   && wallpaperItem.width > 0
                                   && wallpaperItem.height > 0
    readonly property bool glassActive: !solidMode && active
    readonly property bool blurActive: glassActive && blurRadius > 0

    // ── Wallpaper resolution ──────────────────────────────────────────
    readonly property var wallpaperItem: {
        const c = Plasmoid.containment
        if (!c) return null
        const w = c.wallpaperGraphicsObject
        if (!w) return null
        return resolveSource(w)
    }

    function resolveSource(node) {
        if (!node) return null
        // Walk through Loaders and unsized wrappers down to the first
        // renderable item (the actual wallpaper picture).
        if (node.sourceComponent !== undefined && node.item !== undefined)
            return resolveSource(node.item)
        if (node.width > 0 && node.height > 0) return node
        const kids = node.children || []
        for (let i = 0; i < kids.length; i++) {
            const found = resolveSource(kids[i])
            if (found) return found
        }
        return null
    }

    // ── Widget position within the wallpaper (for cropping) ───────────
    property real _offX: 0
    property real _offY: 0

    function updateGeometry() {
        if (!wallpaperItem) return
        const p = glass.mapToItem(wallpaperItem, 0, 0)
        if (p.x !== _offX || p.y !== _offY) {
            _offX = p.x
            _offY = p.y
            if (!realtimeRefraction && glassActive)
                wallpaperTex.scheduleUpdate()
            markDirty()
        }
    }

    // ── Redraw bursts ─────────────────────────────────────────────────
    // The blur chain is a set of ShaderEffectSources feeding one another;
    // leaving them all live would re-blur the wallpaper every frame even
    // for a static wallpaper. Instead the chain runs only while a burst is
    // active, then parks.
    property bool _dirtyBurst: false
    function markDirty() {
        _dirtyBurst = true
        settleTimer.restart()
    }

    Timer {
        id: settleTimer
        interval: 250
        onTriggered: glass._dirtyBurst = false
    }

    readonly property bool _chainLive: glass.glassActive
                                       && (glass.realtimeRefraction || glass._dirtyBurst)

    onWidthChanged: markDirty()
    onHeightChanged: markDirty()
    onVisibleChanged: if (visible) markDirty()
    onBlurRadiusChanged: markDirty()
    onRealtimeRefractionChanged: markDirty()
    onActiveChanged: {
        markDirty()
        updateGeometry()
    }

    // A widget can move without any bindable signal (containment relayout,
    // drag), so poll the offset: slow at rest, frame-rate during a move.
    Timer {
        interval: glass._dirtyBurst ? 16 : 500
        repeat: true
        running: !glass.solidMode && glass.active
                 && glass.visible && glass.width > 0 && glass.height > 0
        onTriggered: glass.updateGeometry()
    }

    Component.onCompleted: {
        updateGeometry()
        refreshCapture()
    }

    function refreshCapture() {
        if (glass.glassActive && !glass.realtimeRefraction)
            wallpaperTex.scheduleUpdate()
    }

    // ── Mouse tracking for the specular sheen ─────────────────────────
    property real _mouseU: -1
    property real _mouseV: -1
    property real _mouseFade: 0

    Behavior on _mouseFade {
        NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: glass.specular
        acceptedButtons: Qt.NoButton // never consume clicks
        onPositionChanged: (mouse) => {
            glass._mouseU = mouse.x / Math.max(1, glass.width)
            glass._mouseV = mouse.y / Math.max(1, glass.height)
            glass._mouseFade = 1
        }
        onExited: {
            glass._mouseFade = 0
            glass._mouseU = -1
        }
    }

    // ── Wallpaper capture ─────────────────────────────────────────────
    ShaderEffectSource {
        id: wallpaperTex
        anchors.fill: parent
        opacity: 0
        sourceItem: glass.glassActive ? glass.wallpaperItem : null
        live: glass.glassActive
              && (glass.realtimeRefraction || glass._dirtyBurst)
        hideSource: false
        recursive: false
        smooth: true
        // Mipmaps keep high-res wallpapers from aliasing when the widget
        // region is small relative to the full image.
        mipmap: true
        textureMirroring: ShaderEffectSource.MirrorVertically
    }

    // ── Crop pass ─────────────────────────────────────────────────────
    readonly property vector2d _uvOff: glass.active
        ? Qt.vector2d(glass._offX / glass.wallpaperItem.width,
                      glass._offY / glass.wallpaperItem.height)
        : Qt.vector2d(0, 0)
    readonly property vector2d _uvSc: glass.active
        ? Qt.vector2d(glass.width / glass.wallpaperItem.width,
                      glass.height / glass.wallpaperItem.height)
        : Qt.vector2d(1, 1)

    readonly property size _halfSize: Qt.size(
        Math.max(1, Math.round(glass.width / 2)),
        Math.max(1, Math.round(glass.height / 2)))

    ShaderEffect {
        id: cropPass
        anchors.fill: parent
        visible: false
        fragmentShader: Qt.resolvedUrl("shaders/crop.frag.qsb")
        property variant uSource: wallpaperTex
        property vector2d uUVOffset: glass._uvOff
        property vector2d uUVScale: glass._uvSc
    }

    ShaderEffectSource {
        id: cropTex
        anchors.fill: parent
        opacity: 0
        sourceItem: glass.glassActive ? cropPass : null
        live: glass._chainLive
        hideSource: true
        smooth: true
        // Blur at half resolution: doubles effective reach, halves cost.
        textureSize: glass.blurActive ? glass._halfSize
                                      : Qt.size(Math.max(1, glass.width),
                                                Math.max(1, glass.height))
    }

    // ── Gaussian blur (two passes at half resolution) ─────────────────
    ShaderEffect {
        id: blurH
        anchors.fill: parent
        visible: false
        fragmentShader: Qt.resolvedUrl("shaders/blur.frag.qsb")
        property variant uSource: cropTex
        property vector2d uDirection: Qt.vector2d(1, 0)
        property real uRadius: glass.blurRadius * 0.5
        property vector2d uTexel: Qt.vector2d(1.0 / glass._halfSize.width,
                                              1.0 / glass._halfSize.height)
    }

    ShaderEffectSource {
        id: blurHTex
        anchors.fill: parent
        opacity: 0
        sourceItem: glass.blurActive ? blurH : null
        live: glass._chainLive
        hideSource: true
        smooth: true
        textureSize: glass._halfSize
    }

    ShaderEffect {
        id: blurV
        anchors.fill: parent
        visible: false
        fragmentShader: Qt.resolvedUrl("shaders/blur.frag.qsb")
        property variant uSource: blurHTex
        property vector2d uDirection: Qt.vector2d(0, 1)
        property real uRadius: glass.blurRadius * 0.5
        property vector2d uTexel: Qt.vector2d(1.0 / glass._halfSize.width,
                                              1.0 / glass._halfSize.height)
    }

    ShaderEffectSource {
        id: blurVTex
        anchors.fill: parent
        opacity: 0
        sourceItem: glass.blurActive ? blurV : null
        live: glass._chainLive
        hideSource: true
        smooth: true
        textureSize: glass._halfSize
    }

    // Tiny opaque texture so the glass pass has something bound in solid
    // mode (where the backdrop is fully overwritten by the tint anyway).
    // Both items use opacity 0 — a visible:false item is culled from the
    // scene graph and would never produce a texture.
    Rectangle {
        id: dummyBackdrop
        width: 2; height: 2
        color: glass.solidColor
        opacity: 0
    }
    ShaderEffectSource {
        id: dummyTex
        anchors.fill: parent
        opacity: 0
        sourceItem: dummyBackdrop
        live: true
        smooth: true
    }

    // ── Glass compose ─────────────────────────────────────────────────
    ShaderEffect {
        id: glassPass
        anchors.fill: parent
        visible: glass.solidMode || glass.glassActive
        fragmentShader: Qt.resolvedUrl("shaders/glass.frag.qsb")

        property variant uBackdrop: glass.blurActive ? blurVTex
                                    : glass.glassActive ? cropTex
                                    : dummyTex
        property vector2d uSize: Qt.vector2d(Math.max(1, glass.width),
                                             Math.max(1, glass.height))
        property real uRadius: glass.radius
        property vector4d uTint: glass.solidMode
            ? Qt.vector4d(glass.solidColor.r, glass.solidColor.g,
                          glass.solidColor.b, 1.0)
            : Qt.vector4d(glass.tint.r, glass.tint.g, glass.tint.b,
                          glass.tintAlpha)
        property real uEdgeBand: (glass.solidMode || !glass.refraction)
                                 ? 0.0 : glass.edgeBand
        property real uRefract: (glass.solidMode || !glass.refraction)
                                ? 0.0 : glass.refractionStrength
        property real uChroma: glass.solidMode ? 0.0 : glass.chromaStrength
        property real uSpec: glass.specular ? glass.specStrength : 0.0
        property real uStroke: glass.specular ? glass.edgeStroke : 0.0
        property vector2d uMouse: Qt.vector2d(glass._mouseU, glass._mouseV)
        property real uMouseFade: glass._mouseFade
        property real uNoise: 0.006
    }

    // ── Fallback (panels, plasmoidviewer) ─────────────────────────────
    Rectangle {
        anchors.fill: parent
        visible: !glass.solidMode && !glass.active
        color: glass.tint
        opacity: glass.fallbackOpacity
        radius: glass.radius
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
    }
}
