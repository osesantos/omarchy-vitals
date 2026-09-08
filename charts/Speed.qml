import QtQuick
import qs.Commons

// Up/down transfer rates, for network and disk. The widget supplies
// `upText`/`downText` already formatted (e.g. "1.2 MB/s"). Stacked vertically —
// download over upload — with breathing room above and below. Each rate sits in
// a fixed-width field so the bar entry never resizes as the numbers change.
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

  // Fixed field width so the widget never resizes as the rate text changes.
  // Sized to the widest realistic value via a hidden metric below, so there is
  // no dead space to the right when the number is short.
  readonly property int fieldWidth: metric.implicitWidth

  implicitHeight: bar ? bar.barSize : 26
  implicitWidth: stack.implicitWidth

  // Off-screen sample of the widest rate string, to lock the field width.
  Text {
    id: metric
    visible: false
    text: "999 MB/s"
    font.family: chart.ff
    font.pixelSize: Style.font.caption
  }

  Column {
    id: stack
    anchors.centerIn: parent
    spacing: 0
    topPadding: 3
    bottomPadding: 3

    component RateRow: Row {
      property string arrow: ""
      property string value: ""
      spacing: 3
      height: Style.font.caption - 1   // tighter than the natural line box
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: parent.arrow
        color: chart.fg
        font.family: chart.ff
        font.pixelSize: Style.font.caption
        opacity: 0.7
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        width: chart.fieldWidth
        horizontalAlignment: Text.AlignLeft
        text: parent.value
        elide: Text.ElideRight
        color: chart.fg
        font.family: chart.ff
        font.pixelSize: Style.font.caption
      }
    }

    RateRow { arrow: "↓"; value: chart.downText }
    RateRow { arrow: "↑"; value: chart.upText }
  }
}
