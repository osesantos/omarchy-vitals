import QtQuick
import qs.Ui
import qs.Commons
import ".." as Vitals
import "." as Local

// CPU detail panel content. A Column of meters + per-core bars, reading live
// values off the shared singleton sampler.
Column {
  id: panel

  property QtObject bar: null
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string ff: bar ? bar.fontFamily : Style.font.family

  spacing: Style.space(14)

  PanelSectionHeader {
    text: "CPU"
    foreground: panel.fg
    fontFamily: panel.ff
    fontSize: Style.font.title
  }

  Local.MeterRow {
    width: parent.width
    label: "USAGE"
    fraction: Vitals.Sampler.cpuPercent / 100
    valueText: Vitals.Sampler.cpuPercent + "%"
    foreground: panel.fg
    fontFamily: panel.ff
  }

  Local.MeterRow {
    width: parent.width
    label: "FREQUENCY"
    fraction: 0
    valueText: Vitals.Sampler.cpu.freqMhz > 0
      ? (Vitals.Sampler.cpu.freqMhz + " MHz") : "—"
    foreground: panel.fg
    fontFamily: panel.ff
  }

  Local.MeterRow {
    width: parent.width
    label: "LOAD AVG"
    fraction: 0
    valueText: Vitals.Sampler.cpu.load1.toFixed(2) + "  "
      + Vitals.Sampler.cpu.load5.toFixed(2) + "  "
      + Vitals.Sampler.cpu.load15.toFixed(2)
    foreground: panel.fg
    fontFamily: panel.ff
  }

  PanelSeparator { foreground: panel.fg }

  PanelSectionHeader {
    text: "PER CORE"
    foreground: panel.fg
    fontFamily: panel.ff
  }

  // Per-core bar grid.
  Flow {
    width: parent.width
    spacing: Style.space(6)

    Repeater {
      model: Vitals.Sampler.cpu.cores

      Rectangle {
        width: (panel.width - Style.space(6) * 7) / 8
        height: Style.space(28)
        radius: Style.cornerRadius
        color: "transparent"
        border.width: 1
        border.color: Qt.darker(panel.fg, 2.2)

        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.margins: Style.space(2)
          height: Math.max(1, (parent.height - Style.space(4)) * (modelData / 100))
          radius: 1
          color: Color.accent
          Behavior on height { NumberAnimation { duration: 200 } }
        }
      }
    }
  }

  PanelSeparator { foreground: panel.fg }

  Local.ProcessList {
    width: parent.width
    bar: panel.bar
    sortKey: "cpu"
  }
}
