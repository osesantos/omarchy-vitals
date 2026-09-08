import QtQuick
import qs.Commons

// Plain numeric label. The default, and the only one that works for every
// module. Value is a percentage unless `unit` overrides it.
Item {
  id: chart

  property QtObject bar: null
  property string glyph: ""
  property int value: 0
  property string valueText: value + "%"
  property var history: []

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string ff: bar ? bar.fontFamily : "monospace"

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  Text {
    id: label
    anchors.centerIn: parent
    text: (chart.glyph ? chart.glyph + " " : "") + chart.valueText
    color: chart.fg
    font.family: chart.ff
    font.pixelSize: Style.bar.iconFont
  }
}
