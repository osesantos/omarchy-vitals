import QtQuick
import qs.Commons

// A wider rolling line chart (no fill), for cpu/memory/network trends in the
// bar. Same history contract as Mini but larger and line-only.
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
  implicitWidth: 56

  Canvas {
    id: line
    anchors.fill: parent
    anchors.margins: 4
    property var pts: chart.history
    onPtsChanged: requestPaint()
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var n = pts ? pts.length : 0
      if (n < 2) return
      var w = width, h = height
      var step = w / (n - 1)
      ctx.beginPath()
      for (var i = 0; i < n; i++) {
        var v = Math.max(0, Math.min(100, pts[i]))
        var y = h - (v / 100) * h
        if (i === 0) ctx.moveTo(0, y); else ctx.lineTo(i * step, y)
      }
      ctx.strokeStyle = chart.accent
      ctx.lineWidth = 1.5
      ctx.stroke()
    }
  }
}
