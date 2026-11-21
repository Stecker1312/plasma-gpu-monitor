import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root

    readonly property int warnTemperature: Plasmoid.configuration.warnTemperature
    readonly property int criticalTemperature: Plasmoid.configuration.criticalTemperature

    readonly property bool showCpuTemperature: Plasmoid.configuration.showCpuTemperature
    readonly property int cpuWarnTemperature: Plasmoid.configuration.cpuWarnTemperature
    readonly property int cpuCriticalTemperature: Plasmoid.configuration.cpuCriticalTemperature

    // Sensor values are QVariant and start out undefined – normalise to 0.
    function valueOf(sensor) {
        var v = sensor.value;
        return (typeof v === "number" && isFinite(v)) ? v : 0;
    }

    readonly property real usageValue: valueOf(usageSensor)
    readonly property real junctionValue: valueOf(junctionSensor)
    readonly property real edgeValue: valueOf(edgeSensor)
    readonly property real memoryValue: valueOf(memorySensor)
    readonly property real powerValue: valueOf(powerSensor)
    readonly property real clockValue: valueOf(clockSensor)
    readonly property real fanValue: valueOf(fanSensor)
    readonly property real vramUsedValue: valueOf(vramUsedSensor)
    readonly property real vramTotalValue: valueOf(vramTotalSensor)
    readonly property real cpuTemperatureValue: valueOf(cpuTemperatureSensor)
    readonly property real cpuUsageValue: valueOf(cpuUsageSensor)

    readonly property real vramUnit: 1024 * 1024 * 1024

    readonly property bool hasData: junctionValue > 0
    readonly property bool cpuHasData: showCpuTemperature && cpuTemperatureValue > 0

    readonly property color temperatureColor: {
        if (!hasData)
            return Kirigami.Theme.disabledTextColor;
        if (junctionValue >= criticalTemperature)
            return Kirigami.Theme.negativeTextColor;
        if (junctionValue >= warnTemperature)
            return Kirigami.Theme.neutralTextColor;
        return Kirigami.Theme.textColor;
    }

    readonly property color cpuTemperatureColor: {
        if (!cpuHasData)
            return Kirigami.Theme.disabledTextColor;
        if (cpuTemperatureValue >= cpuCriticalTemperature)
            return Kirigami.Theme.negativeTextColor;
        if (cpuTemperatureValue >= cpuWarnTemperature)
            return Kirigami.Theme.neutralTextColor;
        return Kirigami.Theme.textColor;
    }

    readonly property bool gpuWarning: hasData && junctionValue >= warnTemperature
    readonly property bool gpuCritical: hasData && junctionValue >= criticalTemperature
    readonly property bool cpuWarning: cpuHasData && cpuTemperatureValue >= cpuWarnTemperature
    readonly property bool cpuCritical: cpuHasData && cpuTemperatureValue >= cpuCriticalTemperature

    // Non-colour cue, so the warning does not rely on colour perception alone.
    readonly property string gpuStateCue: gpuCritical ? "!!" : (gpuWarning ? "!" : "")
    readonly property string cpuStateCue: cpuCritical ? "!!" : (cpuWarning ? "!" : "")

    readonly property string usageText: Math.round(usageValue) + " %"
    readonly property string cpuUsageText: Math.round(cpuUsageValue) + " %"
    readonly property string temperatureText: hasData ? Math.round(junctionValue) + " °C" + gpuStateCue : "-- °C"
    readonly property string cpuTemperatureText: cpuHasData ? Math.round(cpuTemperatureValue) + " °C" + cpuStateCue : "-- °C"

    // Text for screen readers: values plus the warning state, since colour and
    // the "!" cue are visual only.
    readonly property string gpuStateText: gpuCritical ? i18n("Critical") : (gpuWarning ? i18n("Warning") : "")
    readonly property string cpuStateText: cpuCritical ? i18n("Critical") : (cpuWarning ? i18n("Warning") : "")

    readonly property string cpuAccessibleValue: cpuHasData ? Math.round(cpuTemperatureValue) + " °C" : "--"

    readonly property string accessibleText: {
        var text = "";
        if (hasData) {
            text = i18n("Utilisation") + ": " + Math.round(usageValue) + " %, "
                 + i18n("Junction (Hotspot)") + ": " + Math.round(junctionValue) + " °C"
                 + (gpuStateText ? ", " + gpuStateText : "");
        } else {
            text = i18n("No GPU sensors found.");
        }
        if (showCpuTemperature) {
            text += ", " + i18n("CPU") + ": " + cpuUsageText + ", " + cpuAccessibleValue
                  + (cpuStateText ? ", " + cpuStateText : "");
        }
        return text;
    }

    Sensors.Sensor { id: usageSensor; sensorId: "gpu/gpu0/usage"; updateRateLimit: 2000 }
    Sensors.Sensor { id: junctionSensor; sensorId: "gpu/gpu0/temp2"; updateRateLimit: 2000 }
    Sensors.Sensor { id: edgeSensor; sensorId: "gpu/gpu0/temperature"; updateRateLimit: 5000 }
    Sensors.Sensor { id: memorySensor; sensorId: "gpu/gpu0/temp3"; updateRateLimit: 5000 }
    Sensors.Sensor { id: powerSensor; sensorId: "gpu/gpu0/power"; updateRateLimit: 5000 }
    Sensors.Sensor { id: clockSensor; sensorId: "gpu/gpu0/coreFrequency"; updateRateLimit: 5000 }
    Sensors.Sensor { id: fanSensor; sensorId: "gpu/gpu0/fan1"; updateRateLimit: 5000 }
    Sensors.Sensor { id: vramUsedSensor; sensorId: "gpu/gpu0/usedVram"; updateRateLimit: 5000 }
    Sensors.Sensor { id: vramTotalSensor; sensorId: "gpu/gpu0/totalVram"; updateRateLimit: 5000 }
    Sensors.Sensor { id: cpuTemperatureSensor; sensorId: "cpu/all/maximumTemperature"; updateRateLimit: 2000 }
    Sensors.Sensor { id: cpuUsageSensor; sensorId: "cpu/all/usage"; updateRateLimit: 2000 }

    toolTipMainText: root.showCpuTemperature ? i18n("GPU") + " / " + i18n("CPU") : i18n("GPU")
    toolTipSubText: hasData
        ? i18n("Utilisation: %1\nJunction: %2\nEdge: %3\nMemory: %4\nPower: %5",
               usageText,
               Math.round(junctionValue) + " °C",
               Math.round(edgeValue) + " °C",
               Math.round(memoryValue) + " °C",
               Math.round(powerValue) + " W")
          + (root.showCpuTemperature
             ? "\n" + i18n("CPU") + ": " + root.cpuUsageText + ", " + root.cpuAccessibleValue
               + (root.cpuStateText ? " (" + root.cpuStateText + ")" : "")
             : "")
        : i18n("No GPU sensors found.")

    compactRepresentation: Item {
        id: compact

        readonly property int horizontalPadding: Kirigami.Units.smallSpacing

        // Width follows the content. Tabular figures keep every digit the same
        // width, so only a change in the number of digits (or the appearance of
        // the warning cue or the CPU label) makes the item grow.
        Layout.minimumWidth: content.implicitWidth + horizontalPadding * 2
        Layout.preferredWidth: content.implicitWidth + horizontalPadding * 2
        Layout.minimumHeight: content.implicitHeight
        Layout.preferredHeight: content.implicitHeight

        // Keyboard reachable, so the details are available without a mouse.
        activeFocusOnTab: true

        Accessible.role: Accessible.Button
        Accessible.name: root.showCpuTemperature ? i18n("GPU") + " / " + i18n("CPU") : i18n("GPU")
        Accessible.description: root.accessibleText
        Accessible.onPressAction: root.expanded = !root.expanded

        Keys.onReturnPressed: root.expanded = !root.expanded
        Keys.onSpacePressed: root.expanded = !root.expanded

        // Visible focus ring; the panel has no other indication of focus.
        Rectangle {
            anchors.fill: parent
            visible: compact.activeFocus
            color: "transparent"
            border.width: 1
            border.color: Kirigami.Theme.focusColor
            radius: Kirigami.Units.smallSpacing
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                compact.forceActiveFocus();
                root.expanded = !root.expanded;
            }
        }

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            // A label is only needed while both temperatures are shown; on its
            // own the GPU item stays as compact as before.
            Text {
                visible: root.showCpuTemperature
                text: i18n("GPU")
                color: Kirigami.Theme.textColor
                opacity: 0.7
                font.family: Kirigami.Theme.defaultFont.family
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
            }

            Text {
                visible: Plasmoid.configuration.showUsage
                text: root.usageText
                color: Kirigami.Theme.textColor
                font.family: Kirigami.Theme.defaultFont.family
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                font.features: ({ "tnum": 1 })
            }

            Text {
                text: root.temperatureText
                color: root.temperatureColor
                font.family: Kirigami.Theme.defaultFont.family
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                font.features: ({ "tnum": 1 })
            }

            RowLayout {
                visible: root.showCpuTemperature
                spacing: Kirigami.Units.smallSpacing
                Layout.leftMargin: Kirigami.Units.smallSpacing * 2

                Text {
                    text: i18n("CPU")
                    color: Kirigami.Theme.textColor
                    opacity: 0.7
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                }

                Text {
                    text: root.cpuUsageText
                    color: Kirigami.Theme.textColor
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                    font.features: ({ "tnum": 1 })
                }

                Text {
                    text: root.cpuTemperatureText
                    color: root.cpuTemperatureColor
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                    font.features: ({ "tnum": 1 })
                }
            }
        }
    }

    fullRepresentation: ColumnLayout {
        // Width only. A preferredHeight bound to implicitHeight creates a
        // dependency cycle and makes Plasma fall back to its default popup size
        // (560 x 400), which leaves a huge empty area around short content.
        Layout.preferredWidth: Kirigami.Units.gridUnit * 13
        Layout.maximumWidth: Kirigami.Units.gridUnit * 13
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            level: 3
            text: i18n("GPU")
            Layout.bottomMargin: Kirigami.Units.smallSpacing
        }

        GridLayout {
            columns: 2
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.smallSpacing
            Layout.fillWidth: true

            QQC.Label { text: i18n("Utilisation") }
            QQC.Label { text: root.usageText; Layout.alignment: Qt.AlignRight }

            QQC.Label { text: i18n("Junction (Hotspot)") }
            QQC.Label { text: root.temperatureText; color: root.temperatureColor; Layout.alignment: Qt.AlignRight }

            QQC.Label { text: i18n("Edge") }
            QQC.Label { text: Math.round(root.edgeValue) + " °C"; Layout.alignment: Qt.AlignRight }

            QQC.Label { text: i18n("Memory") }
            QQC.Label { text: Math.round(root.memoryValue) + " °C"; Layout.alignment: Qt.AlignRight }

            QQC.Label { text: i18n("Power") }
            QQC.Label { text: Math.round(root.powerValue) + " W"; Layout.alignment: Qt.AlignRight }

            QQC.Label { text: i18n("Clock") }
            QQC.Label {
                text: root.clockValue > 0 ? Math.round(root.clockValue) + " MHz" : "--"
                Layout.alignment: Qt.AlignRight
            }

            QQC.Label { text: i18n("Fan") }
            QQC.Label {
                text: root.fanValue > 0 ? Math.round(root.fanValue) + " RPM" : "--"
                Layout.alignment: Qt.AlignRight
            }

            QQC.Label { text: i18n("VRAM") }
            QQC.Label {
                text: root.vramTotalValue > 0
                    ? (root.vramUsedValue / root.vramUnit).toFixed(1) + " / " + Math.round(root.vramTotalValue / root.vramUnit) + " GiB"
                    : "--"
                Layout.alignment: Qt.AlignRight
            }
        }

        Kirigami.Heading {
            visible: root.showCpuTemperature
            level: 3
            text: i18n("CPU")
            Layout.topMargin: Kirigami.Units.smallSpacing
            Layout.bottomMargin: Kirigami.Units.smallSpacing
        }

        GridLayout {
            visible: root.showCpuTemperature
            columns: 2
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.smallSpacing
            Layout.fillWidth: true

            QQC.Label { text: i18n("Utilisation") }
            QQC.Label { text: root.cpuUsageText; Layout.alignment: Qt.AlignRight }

            QQC.Label { text: i18n("Temperature") }
            QQC.Label { text: root.cpuTemperatureText; color: root.cpuTemperatureColor; Layout.alignment: Qt.AlignRight }
        }

        QQC.Label {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            text: i18n("Warning from %1 °C, critical from %2 °C (junction).",
                       root.warnTemperature, root.criticalTemperature)
                  + (root.showCpuTemperature
                     ? "\n" + i18n("CPU: warning from %1 °C, critical from %2 °C.",
                                   root.cpuWarnTemperature, root.cpuCriticalTemperature)
                     : "")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            wrapMode: Text.WordWrap
        }
    }
}
