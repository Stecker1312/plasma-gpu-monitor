import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_warnTemperature: warnSpin.value
    property alias cfg_criticalTemperature: criticalSpin.value
    property alias cfg_showUsage: showUsageCheck.checked

    QQC.SpinBox {
        id: warnSpin
        Kirigami.FormData.label: i18n("Warnung ab:")
        from: 40
        to: 110
        stepSize: 1
        textFromValue: function (value) { return value + " °C" }
        valueFromText: function (text) { return parseInt(text) }
    }

    QQC.SpinBox {
        id: criticalSpin
        Kirigami.FormData.label: i18n("Kritisch ab:")
        from: 50
        to: 115
        stepSize: 1
        textFromValue: function (value) { return value + " °C" }
        valueFromText: function (text) { return parseInt(text) }
    }

    QQC.CheckBox {
        id: showUsageCheck
        Kirigami.FormData.label: i18n("Anzeige:")
        text: i18n("Auslastung in der Leiste mit anzeigen")
    }

    QQC.Label {
        Kirigami.FormData.isSection: false
        text: i18n("Gemessen wird die Junction-Temperatur (Hotspot), nicht die Edge-Temperatur.")
        font: Kirigami.Theme.smallFont
        opacity: 0.7
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 18
    }
}
