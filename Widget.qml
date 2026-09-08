import QtQuick
import "." as Vitals

// A single Vitals bar entry. Reads its `module` and `widget` from the inline
// shell.json settings, subscribes to the shared singleton sampler for that
// module, and renders the chosen widget style.
//
// P0: module "cpu", widget "text" only. Later phases add sources and charts
// without changing this contract — the widget always subscribes by module and
// reads live values off the singleton.
Item {
  id: root

  // Injected by the bar at load time (see bar/README.md "Bar properties").
  property var bar: null
  property string moduleName: ""
  property var settings: ({})

  // Read a single value from this entry's inline shell.json settings.
  function setting(name, fallback) {
    var v = settings ? settings[name] : undefined
    return v === undefined || v === null ? fallback : v
  }

  readonly property string module: setting("module", "cpu")
  readonly property string widget: setting("widget", "text")

  implicitWidth: label.implicitWidth + 12
  implicitHeight: bar ? bar.barSize : 26

  // Subscribe/unsubscribe over the widget's lifetime so the sampler only reads
  // files for modules that are actually on the bar.
  Component.onCompleted: Vitals.Sampler.subscribe(root.module)
  Component.onDestruction: Vitals.Sampler.unsubscribe(root.module)

  readonly property int cpuValue: Vitals.Sampler.cpuPercent

  Text {
    id: label
    anchors.centerIn: parent
    text: root.module === "cpu" ? ("󰻠 " + root.cpuValue + "%") : root.module
    color: root.bar ? root.bar.foreground : "white"
    font.family: root.bar ? root.bar.fontFamily : "monospace"
    font.pixelSize: 12
  }
}
