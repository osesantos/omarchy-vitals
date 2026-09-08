import QtQuick
import qs.Commons

// A compact filled-area sparkline sized for the bar: glyph + a tiny history
// graph. Reads the ring buffer off the widget.
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
  implicitWidth: row.implicitWidth

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 4

    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: chart.glyph !== ""
      text: chart.glyph
      color: chart.fg
      font.family: chart.ff
      font.pixelSize: 12
    }

    Canvas {
      id: spark
      anchors.verticalCenter: parent.verticalCenter
      width: 34
      height: (chart.bar ? chart.bar.barSize : 26) - 10
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
        ctx.moveTo(0, h)
        for (var i = 0; i < n; i++) {
          var v = Math.max(0, Math.min(100, pts[i]))
          ctx.lineTo(i * step, h - (v / 100) * h)
        }
        ctx.lineTo(w, h)
        ctx.closePath()
        ctx.fillStyle = Qt.rgba(chart.accent.r, chart.accent.g, chart.accent.b, 0.25)
        ctx.fill()
        ctx.beginPath()
        for (var j = 0; j < n; j++) {
          var vv = Math.max(0, Math.min(100, pts[j]))
          var y = h - (vv / 100) * h
          if (j === 0) ctx.moveTo(0, y); else ctx.lineTo(j * step, y)
        }
        ctx.strokeStyle = chart.accent
        ctx.lineWidth = 1.5
        ctx.stroke()
      }
    }
  }
}
