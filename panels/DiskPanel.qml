import QtQuick
import qs.Ui
import qs.Commons
import ".." as Vitals
import "." as Local
import "../format.js" as Fmt

// Disk detail panel content.
Column {
  id: panel

  property QtObject bar: null
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string ff: bar ? bar.fontFamily : Style.font.family

  spacing: Style.space(14)

  PanelSectionHeader {
    text: "DISK  ·  /"
    foreground: panel.fg
    fontFamily: panel.ff
    fontSize: Style.font.title
  }

  Local.MeterRow {
    width: parent.width
    label: "CAPACITY"
    fraction: Vitals.Sampler.diskPercent / 100
    valueText: Fmt.size(Vitals.Sampler.disk.usedBytes) + " / "
      + Fmt.size(Vitals.Sampler.disk.totalBytes)
    foreground: panel.fg
    fontFamily: panel.ff
  }

  PanelSeparator { foreground: panel.fg }

  Local.MeterRow {
    width: parent.width
    label: "READ"
    fraction: Math.min(1, Vitals.Sampler.disk.readBytesPerSec / Vitals.Sampler.disk.ceilingBps)
    valueText: Fmt.rate(Vitals.Sampler.disk.readBytesPerSec)
    foreground: panel.fg
    fontFamily: panel.ff
  }

  Local.MeterRow {
    width: parent.width
    label: "WRITE"
    fraction: Math.min(1, Vitals.Sampler.disk.writeBytesPerSec / Vitals.Sampler.disk.ceilingBps)
    valueText: Fmt.rate(Vitals.Sampler.disk.writeBytesPerSec)
    foreground: panel.fg
    fontFamily: panel.ff
  }
}
