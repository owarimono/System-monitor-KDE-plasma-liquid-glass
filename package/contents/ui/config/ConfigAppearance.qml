import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Material (glass/solid), color scheme, accent theme and the performance
// knobs of the liquid glass effect.

Kirigami.FormLayout {
    id: page

    property int cfg_styleMode: 0
    property int cfg_appearance: 0
    property string cfg_accentColor: "#0a84ff"
    property int cfg_cornerRadius: 20
    property int cfg_blurRadius: 24
    property bool cfg_refraction: true
    property bool cfg_realtimeRefraction: false

    // The macOS system accent colors (System Settings → Appearance).
    readonly property var accentPresets: [
        ["Blue", "#0a84ff"],
        ["Purple", "#bf5af2"],
        ["Pink", "#ff375f"],
        ["Red", "#ff453a"],
        ["Orange", "#ff9f0a"],
        ["Yellow", "#ffd60a"],
        ["Green", "#32d74b"],
        ["Graphite", "#8e8e93"]
    ]
    readonly property int customAccentIndex: accentPresets.length

    onCfg_blurRadiusChanged: {
        if (!blurSlider.activeFocus)
            blurSlider.value = cfg_blurRadius
    }
    onCfg_cornerRadiusChanged: {
        if (!cornerSlider.activeFocus)
            cornerSlider.value = cfg_cornerRadius
    }
    onCfg_accentColorChanged: syncAccent()
    Component.onCompleted: syncAccent()

    function syncAccent() {
        const idx = accentPresets.findIndex(
            p => p[1].toLowerCase() === cfg_accentColor.toLowerCase())
        accentCombo.currentIndex = idx >= 0 ? idx : customAccentIndex
        if (idx < 0)
            accentButton.color = cfg_accentColor
    }

    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Material:")
        currentIndex: page.cfg_styleMode
        textRole: "text"
        model: [
            { text: i18n("Liquid glass"), value: 0 },
            { text: i18n("Solid"), value: 1 }
        ]
        onActivated: (index) => page.cfg_styleMode = model[index].value
    }

    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Color scheme:")
        currentIndex: page.cfg_appearance
        textRole: "text"
        model: [
            { text: i18n("Dark"), value: 0 },
            { text: i18n("Light"), value: 1 },
            { text: i18n("Follow system"), value: 2 }
        ]
        onActivated: (index) => page.cfg_appearance = model[index].value
    }

    QQC2.ComboBox {
        id: accentCombo
        Kirigami.FormData.label: i18n("Accent theme:")
        editable: false
        model: accentPresets.map(p => p[0]).concat([i18n("Custom")])
        onActivated: (index) => {
            if (index < page.customAccentIndex)
                page.cfg_accentColor = page.accentPresets[index][1]
        }
    }

    Kirigami.ColorButton {
        id: accentButton
        Kirigami.FormData.label: i18n("Custom accent:")
        enabled: accentCombo.currentIndex === page.customAccentIndex
        modal: true
        showAlphaChannel: false
        onColorChanged: {
            if (enabled)
                page.cfg_accentColor = String(color)
        }
    }

    Item { Kirigami.FormData.isSection: true }

    RowLayout {
        Kirigami.FormData.label: i18n("Corner radius:")
        Kirigami.FormData.buddyFor: cornerSlider

        QQC2.Slider {
            id: cornerSlider
            Layout.preferredWidth: 180
            from: 8
            to: 40
            stepSize: 1
            snapMode: QQC2.Slider.SnapAlways
            onValueChanged: {
                if (activeFocus)
                    page.cfg_cornerRadius = value
            }
        }

        QQC2.Label {
            text: i18n("%1 px", cornerSlider.value)
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Blur strength:")
        Kirigami.FormData.buddyFor: blurSlider

        QQC2.Slider {
            id: blurSlider
            Layout.preferredWidth: 180
            from: 0
            to: 48
            stepSize: 1
            snapMode: QQC2.Slider.SnapAlways
            onValueChanged: {
                if (activeFocus)
                    page.cfg_blurRadius = value
            }
        }

        QQC2.Label {
            text: blurSlider.value === 0 ? i18n("Off") : i18n("%1 px", blurSlider.value)
        }
    }

    QQC2.CheckBox {
        id: refractionCheck
        checked: page.cfg_refraction
        onToggled: page.cfg_refraction = checked
        text: i18n("Refractive edge")
    }

    QQC2.CheckBox {
        checked: page.cfg_realtimeRefraction
        onToggled: page.cfg_realtimeRefraction = checked
        text: i18n("Continuously sample the background")
        QQC2.ToolTip.visible: hovered
        QQC2.ToolTip.text: i18n("Only needed for animated or video wallpapers. Costs battery on laptops.")
    }
}
