import QtQuick
import qs.Commons

// A row of vertical bars: per-core CPU or per-sensor readings. The `series`
// property is an array of 0..100 values; falls back to a single bar of
// `value` when no series is supplied.
Item {
  id: chart

  property QtObject bar: null
  property string glyph: ""
  property int value: 0
  property string valueText: value + "%"
  property var history: []
  property var series: []

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color accent: Color.accent

  readonly property var series2: (series && series.length > 0) ? series : [value]

  implicitHeight: bar ? bar.barSize : 26
  implicitWidth: Math.max(12, series2.length * 4)

  Row {
    anchors.centerIn: parent
    height: (chart.bar ? chart.bar.barSize : 26) - 10
    spacing: 1

    Repeater {
      model: chart.series2

      Rectangle {
        width: 3
        height: parent.height
        color: "transparent"

        Rectangle {
          anchors.bottom: parent.bottom
          width: parent.width
          height: Math.max(1, parent.height * Math.max(0, Math.min(100, modelData)) / 100)
          color: chart.accent
          Behavior on height { NumberAnimation { duration: 200 } }
        }
      }
    }
  }
}
