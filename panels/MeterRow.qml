import QtQuick
import qs.Ui
import qs.Commons

// A labelled horizontal meter: LABEL on the left, value on the right, and a
// proportional fill bar beneath. Shared by every Vitals panel so the modules
// read consistently.
Column {
  id: meterRow

  property string label: ""
  property real fraction: 0
  property string valueText: ""
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property color fillColor: Color.accent

  spacing: Style.space(6)

  Item {
    width: parent.width
    implicitHeight: Math.max(header.implicitHeight, value.implicitHeight)

    PanelSectionHeader {
      id: header
      text: meterRow.label
      foreground: meterRow.foreground
      fontFamily: meterRow.fontFamily
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      id: value
      text: meterRow.valueText
      textFormat: Text.PlainText
      color: Qt.darker(meterRow.foreground, 1.4)
      font.family: meterRow.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      anchors.right: parent.right
      anchors.rightMargin: Style.space(6)
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  CursorSurface {
    width: parent.width
    height: Style.space(18)
    bordered: true
    foreground: meterRow.foreground
    radius: Style.cornerRadius

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.margins: Style.space(4)
      width: Math.max(radius, (parent.width - Style.space(8)) * Math.max(0, Math.min(1, meterRow.fraction)))
      radius: Math.max(1, Style.cornerRadius - Style.space(2))
      color: meterRow.fillColor
      Behavior on width { NumberAnimation { duration: 250 } }
    }
  }
}
