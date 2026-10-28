import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Sections")
        icon: "view-list-details"
        source: "config/ConfigSections.qml"
    }
    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-theme"
        source: "config/ConfigAppearance.qml"
    }
    ConfigCategory {
        name: i18n("About")
        icon: "help-about"
        source: "config/ConfigAbout.qml"
    }
}
