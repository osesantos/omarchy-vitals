import QtQuick
import qs.Ui
import qs.Commons
import "." as Vitals
import "panels" as Panels
import "charts" as Charts

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

  // Per-core series for the `bars` chart (cpu only).
  readonly property var series: module === "cpu" ? Vitals.Sampler.cpu.cores : []

  implicitWidth: Math.max(24, chartLoader.implicitWidth + 12)
  implicitHeight: bar ? bar.barSize : 26

  Component.onCompleted: Vitals.Sampler.subscribe(root.module)
  Component.onDestruction: Vitals.Sampler.unsubscribe(root.module)

  // Map the `widget` setting to a chart type. Unknown values fall back to text.
  function chartComponent(w) {
    switch (w) {
      case "mini":  return miniChart
      case "line":  return lineChart
      case "bars":  return barsChart
      case "pie":   return pieChart
      case "fill":  return fillChart
      case "speed": return speedChart
      case "text":
      default:      return textChart
    }
  }

  Rectangle {
    id: button
    anchors.fill: parent
    color: mouse.containsMouse
      ? Qt.rgba((root.bar ? root.bar.foreground.r : 1), (root.bar ? root.bar.foreground.g : 1), (root.bar ? root.bar.foreground.b : 1), 0.08)
      : "transparent"
    radius: Style.cornerRadius

    Loader {
      id: chartLoader
      anchors.centerIn: parent
      sourceComponent: root.chartComponent(root.widget)
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      onClicked: root.toggle()
      onEntered: if (root.bar) root.bar.showTooltip(button, root.module.toUpperCase() + " · " + root.value + "%")
      onExited: if (root.bar) root.bar.hideTooltip(button)
    }
  }

  Component { id: textChart;  Charts.Text  { bar: root.bar; glyph: root.glyph; value: root.value; history: root.history } }
  Component { id: miniChart;  Charts.Mini  { bar: root.bar; glyph: root.glyph; value: root.value; history: root.history } }
  Component { id: lineChart;  Charts.Line  { bar: root.bar; glyph: root.glyph; value: root.value; history: root.history } }
  Component { id: barsChart;  Charts.Bars  { bar: root.bar; glyph: root.glyph; value: root.value; history: root.history; series: root.series } }
  Component { id: pieChart;   Charts.Pie   { bar: root.bar; glyph: root.glyph; value: root.value; history: root.history } }
  Component { id: fillChart;  Charts.Fill  { bar: root.bar; glyph: root.glyph; value: root.value; history: root.history } }
  Component { id: speedChart; Charts.Speed { bar: root.bar; glyph: root.glyph; value: root.value; history: root.history } }


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
