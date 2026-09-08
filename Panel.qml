import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "panels" as Panels

// Details popup for a Vitals bar entry. Loaded by Widget.qml, which injects
// `bar`, `anchorItem`, `hostWidget`, and `module`. Picks the per-module panel
// content and hosts it in a KeyboardPanel anchored to the bar button.
Panel {
  id: root
  moduleName: "osesantos.vitals"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property string module: "cpu"

  function open() { root.controller.show() }
  function close() { root.controller.hide() }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
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
        sourceComponent: {
          switch (root.module) {
            case "memory": return memoryPanel
            case "network": return networkPanel
            case "disk": return diskPanel
            case "sensors": return sensorsPanel
            case "cpu":
            default: return cpuPanel
          }
        }
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

  Component {
    id: networkPanel
    Panels.NetworkPanel { width: content.width; bar: root.bar }
  }

  Component {
    id: diskPanel
    Panels.DiskPanel { width: content.width; bar: root.bar }
  }

  Component {
    id: sensorsPanel
    Panels.SensorsPanel { width: content.width; bar: root.bar }
  }
}
