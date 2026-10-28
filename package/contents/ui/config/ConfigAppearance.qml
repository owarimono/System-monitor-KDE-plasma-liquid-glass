import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Material (glass/solid), color scheme, accent color and the performance
// knobs of the liquid glass effect.

Kirigami.FormLayout {
    id: page

    property int cfg_styleMode: 0
    property int cfg_appearance: 0
    property alias cfg_accentColor: accentButton.color
    property int cfg_blurRadius: 24
    property bool cfg_refraction: true
    property bool cfg_realtimeRefraction: false

    onCfg_blurRadiusChanged: {
        if (!blurSlider.activeFocus)
            blurSlider.value = cfg_blurRadius
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

    Kirigami.ColorButton {
        id: accentButton
        Kirigami.FormData.label: i18n("Accent color:")
        modal: true
    }

    Item { Kirigami.FormData.isSection: true }

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
