import QtQuick
import qs.Ui
import qs.Commons
import ".." as Vitals
import "." as Local
import "../format.js" as Fmt

// Network detail panel content.
Column {
  id: panel

  property QtObject bar: null
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string ff: bar ? bar.fontFamily : Style.font.family

  spacing: Style.space(14)

  PanelSectionHeader {
    text: "NETWORK" + (Vitals.Sampler.network.iface !== "" ? "  ·  " + Vitals.Sampler.network.iface : "")
    foreground: panel.fg
    fontFamily: panel.ff
    fontSize: Style.font.title
  }

  Local.MeterRow {
    width: parent.width
    label: "DOWNLOAD"
    fraction: Math.min(1, Vitals.Sampler.network.rxBytesPerSec / Vitals.Sampler.network.ceilingBps)
    valueText: Fmt.rate(Vitals.Sampler.network.rxBytesPerSec)
    foreground: panel.fg
    fontFamily: panel.ff
  }

  Local.MeterRow {
    width: parent.width
    label: "UPLOAD"
    fraction: Math.min(1, Vitals.Sampler.network.txBytesPerSec / Vitals.Sampler.network.ceilingBps)
    valueText: Fmt.rate(Vitals.Sampler.network.txBytesPerSec)
    foreground: panel.fg
    fontFamily: panel.ff
  }

  PanelSeparator { foreground: panel.fg }

  PanelSectionHeader {
    text: Vitals.Sampler.network.up ? "LINK UP" : "LINK DOWN"
    foreground: panel.fg
    fontFamily: panel.ff
  }
}
