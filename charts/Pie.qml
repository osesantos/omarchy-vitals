import QtQuick
import qs.Commons

// A small donut showing `value`% filled. Canvas-drawn.
Item {
  id: chart

  property QtObject bar: null
  property string glyph: ""
  property int value: 0
  property string valueText: value + "%"
  property var history: []

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color accent: Color.accent

  implicitHeight: bar ? bar.barSize : 26
  implicitWidth: implicitHeight

  Canvas {
    id: pie
    anchors.fill: parent
    anchors.margins: 5
    property int v: chart.value
    onVChanged: requestPaint()
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var cx = width / 2, cy = height / 2
      var r = Math.min(cx, cy)
      var lw = Math.max(2, r * 0.35)
      var start = -Math.PI / 2
      var frac = Math.max(0, Math.min(1, v / 100))

      ctx.beginPath()
      ctx.arc(cx, cy, r - lw / 2, 0, 2 * Math.PI)
      ctx.strokeStyle = Qt.rgba(chart.fg.r, chart.fg.g, chart.fg.b, 0.25)
      ctx.lineWidth = lw
      ctx.stroke()

      ctx.beginPath()
      ctx.arc(cx, cy, r - lw / 2, start, start + frac * 2 * Math.PI)
      ctx.strokeStyle = chart.accent
      ctx.lineWidth = lw
      ctx.lineCap = "round"
      ctx.stroke()
    }
  }
}
