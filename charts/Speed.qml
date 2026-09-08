import QtQuick
import qs.Commons

// Up/down transfer rates, for network and disk. The widget supplies
// `upText`/`downText` already formatted (e.g. "1.2 MB/s"). Stacked vertically
// like exelban/stats — download over upload — with breathing room above and
// below. Each rate sits in a fixed-width right-aligned field so the bar entry
// never resizes as the numbers change.
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

  // Fixed field width so "0 B/s" and "1.2 MB/s" occupy the same space.
  readonly property int fieldWidth: 58

  implicitHeight: bar ? bar.barSize : 26
  implicitWidth: fieldWidth + 12

  Column {
    anchors.centerIn: parent
    spacing: 0
    topPadding: 3
    bottomPadding: 3

    component RateRow: Row {
      property string arrow: ""
      property string value: ""
      spacing: 3
      height: Style.font.caption - 1.5   // tighter than the natural line box
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
        horizontalAlignment: Text.AlignRight
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
