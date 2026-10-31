import QtQuick
import QtQuick.Controls
import qs.Ui
import qs.Commons
import ".." as Vitals

// Sensors detail panel: every discovered temperature and fan, grouped under its
// chip. Rows are compact (label, value, thin meter) and the list scrolls once it
// outgrows the card, since a laptop easily exposes a dozen or more sensors.
Column {
  id: panel

  property QtObject bar: null
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string ff: bar ? bar.fontFamily : Style.font.family

  // Flat list for the ListView: a header row whenever the chip changes, then one
  // row per sensor carrying its index into the sampler's live readings. Built
  // from the static layout, so it is only rebuilt when the sensor set changes —
  // not on every reading, which would reset the scroll position.
  readonly property var rows: {
    var layout = Vitals.Sampler.sensors.layout
    var out = []
    var chip = null
    for (var i = 0; i < layout.length; i++) {
      if (layout[i].chip !== chip) {
        chip = layout[i].chip
        out.push({ kind: "header", text: chip.toUpperCase() })
      }
      out.push({ kind: "sensor", index: i, label: layout[i].label, type: layout[i].type })
    }
    return out
  }

  spacing: Style.space(10)

  PanelSectionHeader {
    text: "SENSORS"
    foreground: panel.fg
    fontFamily: panel.ff
    fontSize: Style.font.title
  }

  ListView {
    id: list
    width: parent.width
    height: Math.min(contentHeight, Style.space(460))
    clip: true
    spacing: Style.space(6)
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    model: panel.rows

    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

    delegate: Item {
      id: row
      required property var modelData

      readonly property bool isHeader: modelData.kind === "header"
      readonly property var reading: isHeader ? null : Vitals.Sampler.sensorsList[modelData.index]
      readonly property real value: reading ? reading.value : 0
      readonly property bool isTemp: modelData.type === "temp"

      width: ListView.view.width
      height: isHeader ? headerText.implicitHeight + Style.space(4) : sensorRow.implicitHeight

      PanelSectionHeader {
        id: headerText
        visible: row.isHeader
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        text: row.isHeader ? row.modelData.text : ""
        foreground: panel.fg
        fontFamily: panel.ff
      }

      Column {
        id: sensorRow
        visible: !row.isHeader
        width: parent.width - Style.space(6)
        spacing: Style.space(3)

        Item {
          width: parent.width
          implicitHeight: Math.max(name.implicitHeight, valueLabel.implicitHeight)

          Text {
            id: name
            anchors.left: parent.left
            anchors.right: valueLabel.left
            anchors.rightMargin: Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
            text: row.isHeader ? "" : row.modelData.label
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: panel.fg
            font.family: panel.ff
            font.pixelSize: Style.font.caption
          }

          Text {
            id: valueLabel
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: row.isHeader ? "" : (row.isTemp ? (row.value + " °C") : (row.value + " RPM"))
            textFormat: Text.PlainText
            color: Qt.darker(panel.fg, 1.4)
            font.family: panel.ff
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }

        // Thin meter, temperatures only (0..100 °C); a fan speed has no
        // natural full-scale.
        Rectangle {
          visible: row.isTemp
          width: parent.width
          height: Style.space(5)
          radius: height / 2
          color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.15)

          Rectangle {
            width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, row.value / 100)))
            height: parent.height
            radius: parent.radius
            color: Color.accent
            Behavior on width { NumberAnimation { duration: 250 } }
          }
        }
      }
    }
  }

  Text {
    visible: panel.rows.length === 0
    width: parent.width
    text: "No sensors detected."
    color: Qt.darker(panel.fg, 1.4)
    font.family: panel.ff
    font.pixelSize: Style.font.caption
  }
}
