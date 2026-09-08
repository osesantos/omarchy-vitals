import QtQuick
import qs.Ui
import qs.Commons
import "." as Vitals
import "panels" as Panels

// A single Vitals bar entry. Reads its `module` and `widget` from the inline
// shell.json settings, subscribes to the shared singleton sampler for that
// module, renders the chosen widget style in the bar, and opens a per-module
// detail panel on click.
Panel {
  id: root

  moduleName: "osesantos.vitals"
  ipcTarget: ""   // allowMultiple: sharing one IPC target across instances warns

  readonly property string module: setting("module", "cpu")
  readonly property string widget: setting("widget", "text")

  // Live value + label per module. Chart kit (P2) reads `value`/`history`.
  readonly property int value: {
    switch (module) {
      case "memory": return Vitals.Sampler.memPercent
      case "cpu":
      default: return Vitals.Sampler.cpuPercent
    }
  }
  readonly property var history: {
    switch (module) {
      case "memory": return Vitals.Sampler.memHistory
      case "cpu":
      default: return Vitals.Sampler.cpuHistory
    }
  }
  readonly property string glyph: {
    switch (module) {
      case "memory": return "󰍛"
      case "cpu":
      default: return "󰻠"
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Component.onCompleted: Vitals.Sampler.subscribe(root.module)
  Component.onDestruction: Vitals.Sampler.unsubscribe(root.module)

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.glyph + " " + root.value + "%"
    slotSize: Style.bar.iconSlot * 2
    tooltipText: root.module.toUpperCase() + " · " + root.value + "%"
    onPressed: function(b) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(720))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Loader {
        id: content
        width: parent.width
        sourceComponent: root.module === "memory" ? memoryPanel : cpuPanel
      }
    }
  }

  Component {
    id: cpuPanel
    Panels.CpuPanel { width: content.width; bar: root.bar }
  }

  Component {
    id: memoryPanel
    Panels.MemoryPanel { width: content.width; bar: root.bar }
  }
}
