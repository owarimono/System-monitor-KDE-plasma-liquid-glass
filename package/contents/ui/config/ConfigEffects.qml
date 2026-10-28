import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// The liquid-glass material itself: blur, tint, refraction and the
// floating drop shadow.

Kirigami.FormLayout {
    id: page

    property int cfg_blurRadius: 28
    property int cfg_tintStrength: 100
    property bool cfg_refraction: true
    property bool cfg_realtimeRefraction: false
    property bool cfg_shadowEnabled: true
    property int cfg_shadowStrength: 60

    onCfg_blurRadiusChanged: {
        if (!blurSlider.activeFocus)
            blurSlider.value = cfg_blurRadius
    }
    onCfg_tintStrengthChanged: {
        if (!tintSlider.activeFocus)
            tintSlider.value = cfg_tintStrength
    }
    onCfg_shadowStrengthChanged: {
        if (!shadowSlider.activeFocus)
            shadowSlider.value = cfg_shadowStrength
    }

    QQC2.CheckBox {
        id: shadowCheck
        checked: page.cfg_shadowEnabled
        onToggled: page.cfg_shadowEnabled = checked
        text: i18n("Floating drop shadow")
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Shadow strength:")
        enabled: shadowCheck.checked
        Kirigami.FormData.buddyFor: shadowSlider

        QQC2.Slider {
            id: shadowSlider
            Layout.preferredWidth: 180
            from: 0
            to: 100
            stepSize: 5
            snapMode: QQC2.Slider.SnapAlways
            onValueChanged: {
                if (activeFocus)
                    page.cfg_shadowStrength = value
            }
        }

        QQC2.Label {
            text: shadowSlider.value + "%"
        }
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

    RowLayout {
        Kirigami.FormData.label: i18n("Glass tint:")
        Kirigami.FormData.buddyFor: tintSlider

        QQC2.Slider {
            id: tintSlider
            Layout.preferredWidth: 180
            from: 40
            to: 160
            stepSize: 5
            snapMode: QQC2.Slider.SnapAlways
            onValueChanged: {
                if (activeFocus)
                    page.cfg_tintStrength = value
            }
        }

        QQC2.Label {
            text: tintSlider.value + "%"
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
