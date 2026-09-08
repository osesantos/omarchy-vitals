import QtQuick
import qs.Commons

// Up/down transfer rates, for network and disk. The widget supplies
// `upText`/`downText` already formatted (e.g. "1.2 MB/s"); this chart only
// lays them out with arrows.
Item {
  id: chart

  property QtObject bar: null
  property string glyph: ""
  property int value: 0
  property string valueText: value + "%"
  property var history: []
  property string upText: "—"
  property string downText: "—"

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string ff: bar ? bar.fontFamily : "monospace"

  implicitHeight: bar ? bar.barSize : 26
  implicitWidth: col.implicitWidth

  Column {
    id: col
    anchors.centerIn: parent
    spacing: 0

    Text {
      text: "↑ " + chart.upText
      color: chart.fg
      font.family: chart.ff
      font.pixelSize: 9
    }
    Text {
      text: "↓ " + chart.downText
      color: chart.fg
      font.family: chart.ff
      font.pixelSize: 9
    }
  }
}
