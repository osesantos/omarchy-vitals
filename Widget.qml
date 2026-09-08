import QtQuick
import Quickshell
import qs.Ui
import qs.Commons
import "." as Vitals
import "charts" as Charts
import "format.js" as Fmt
// A single Vitals bar entry — the manifest entry point. Reads its `module` and
// `widget` from the inline shell.json settings, subscribes to the shared
// singleton sampler, renders the chosen chart in the bar, and loads Panel.qml
// for the details popup.
//
// This follows the blessed BarWidget + separate Panel.qml split from
// plugins.omarchy.org/develop.html: the entry point forwards the panel
// lifecycle (opened/open/close/toggle) so the shell's summon/hide IPC routes
// correctly, not just click-to-toggle.
BarWidget {
  id: root

  moduleName: "osesantos.vitals"

  readonly property string module: setting("module", "cpu")
  readonly property string widget: setting("widget", "text")

  // ---- Panel lifecycle forwarding -----------------------------------------
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
    panelLoader.item.module = root.module
  }

  onBarChanged: injectPanel()

  // ---- Live values --------------------------------------------------------
  readonly property int value: {
    switch (module) {
      case "memory": return Vitals.Sampler.memPercent
      case "network": return Vitals.Sampler.netPercent
      case "disk": return Vitals.Sampler.diskPercent
      case "cpu":
      default: return Vitals.Sampler.cpuPercent
    }
  }
  readonly property var history: {
    switch (module) {
      case "memory": return Vitals.Sampler.memHistory
      case "network": return Vitals.Sampler.netHistory
      case "disk": return Vitals.Sampler.diskHistory
      case "cpu":
      default: return Vitals.Sampler.cpuHistory
    }
  }
  readonly property var series: module === "cpu" ? Vitals.Sampler.cpu.cores : []
  readonly property string glyph: {
    switch (module) {
      case "memory": return "󰍛"
      case "network": return "󰤨"
      case "disk": return "󰋊"
      case "cpu":
      default: return "󰻠"
    }
  }

  // Up/down rate strings for the speed chart (network + disk).
  readonly property string upText: {
    switch (module) {
      case "network": return Fmt.rate(Vitals.Sampler.network.txBytesPerSec)
      case "disk": return Fmt.rate(Vitals.Sampler.disk.writeBytesPerSec)
      default: return "—"
    }
  }
  readonly property string downText: {
    switch (module) {
      case "network": return Fmt.rate(Vitals.Sampler.network.rxBytesPerSec)
      case "disk": return Fmt.rate(Vitals.Sampler.disk.readBytesPerSec)
      default: return "—"
    }
  }

  implicitWidth: Math.max(24, chartLoader.implicitWidth + 12)
  implicitHeight: bar ? bar.barSize : 26

  Component.onCompleted: Vitals.Sampler.subscribe(root.module)
  Component.onDestruction: Vitals.Sampler.unsubscribe(root.module)

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

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
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
  Component { id: speedChart; Charts.Speed { bar: root.bar; glyph: root.glyph; value: root.value; history: root.history; upText: root.upText; downText: root.downText } }
}
