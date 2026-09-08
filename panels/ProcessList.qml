import QtQuick
import qs.Ui
import qs.Commons
import ".." as Vitals

// Top-processes table, shared by the CPU and memory panels. `sortKey` is "cpu"
// or "mem"; the component polls `ps` on load (panels are recreated on each
// open) and shows the busiest processes for that resource.
Column {
  id: procList

  property QtObject bar: null
  property string sortKey: "cpu"
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string ff: bar ? bar.fontFamily : Style.font.family

  spacing: Style.space(8)

  Component.onCompleted: Vitals.Sampler.pollProcesses(procList.sortKey)

  PanelSectionHeader {
    text: procList.sortKey === "mem" ? "TOP BY MEMORY" : "TOP BY CPU"
    foreground: procList.fg
    fontFamily: procList.ff
  }

  Repeater {
    model: Vitals.Sampler.processList

    Item {
      required property var modelData
      width: parent.width
      implicitHeight: nameText.implicitHeight

      Text {
        id: nameText
        anchors.left: parent.left
        anchors.right: valueText.left
        anchors.rightMargin: Style.space(8)
        text: modelData.name
        textFormat: Text.PlainText
        elide: Text.ElideRight
        color: procList.fg
        font.family: procList.ff
        font.pixelSize: Style.font.caption
      }

      Text {
        id: valueText
        anchors.right: parent.right
        text: procList.sortKey === "mem"
          ? (modelData.mem.toFixed(1) + "%")
          : (modelData.cpu.toFixed(1) + "%")
        color: Qt.darker(procList.fg, 1.3)
        font.family: procList.ff
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }
  }
}
