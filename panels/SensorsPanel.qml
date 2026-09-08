import QtQuick
import qs.Ui
import qs.Commons
import ".." as Vitals
import "." as Local

// Sensors detail panel: every discovered temperature and fan, as a labelled
// meter (temps 0..100°C) or a plain RPM row (fans).
Column {
  id: panel

  property QtObject bar: null
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string ff: bar ? bar.fontFamily : Style.font.family

  spacing: Style.space(14)

  PanelSectionHeader {
    text: "SENSORS"
    foreground: panel.fg
    fontFamily: panel.ff
    fontSize: Style.font.title
  }

  Repeater {
    model: Vitals.Sampler.sensorsList

    Local.MeterRow {
      required property var modelData
      width: parent.width
      label: (modelData.chip + " · " + modelData.label).toUpperCase()
      fraction: modelData.type === "temp" ? Math.min(1, modelData.value / 100) : 0
      valueText: modelData.type === "temp"
        ? (modelData.value + " °C")
        : (modelData.value + " RPM")
      foreground: panel.fg
      fontFamily: panel.ff
    }
  }

  Text {
    visible: Vitals.Sampler.sensorsList.length === 0
    width: parent.width
    text: "No sensors detected."
    color: Qt.darker(panel.fg, 1.4)
    font.family: panel.ff
    font.pixelSize: Style.font.caption
  }
}
