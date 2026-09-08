import QtQuick
import qs.Commons

// A horizontal fill bar (memory/disk capacity) with the percentage overlaid.
Item {
  id: chart

  property QtObject bar: null
  property string glyph: ""
  property int value: 0
  property string valueText: value + "%"
  property var history: []

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color accent: Color.accent
  readonly property string ff: bar ? bar.fontFamily : "monospace"

  implicitHeight: bar ? bar.barSize : 26
  implicitWidth: 46

  Rectangle {
    id: track
    anchors.centerIn: parent
    width: 40
    height: (chart.bar ? chart.bar.barSize : 26) - 10
    radius: height / 2
    color: "transparent"
    border.width: 1
    border.color: Qt.darker(chart.fg, 2.0)

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.margins: 2
      width: Math.max(radius, (parent.width - 4) * Math.max(0, Math.min(100, chart.value)) / 100)
      radius: Math.max(1, parent.radius - 2)
      color: chart.accent
      Behavior on width { NumberAnimation { duration: 250 } }
    }

    Text {
      anchors.centerIn: parent
      text: chart.value + "%"
      color: chart.fg
      font.family: chart.ff
      font.pixelSize: 9
      font.bold: true
    }
  }
}
