import QtQuick
import qs.Ui
import qs.Commons
import ".." as Vitals

// Memory detail panel content.
Column {
  id: panel

  property QtObject bar: null
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string ff: bar ? bar.fontFamily : Style.font.family

  function gib(kb) { return (kb / 1024 / 1024).toFixed(1) }

  spacing: Style.space(14)

  PanelSectionHeader {
    text: "MEMORY"
    foreground: panel.fg
    fontFamily: panel.ff
    fontSize: Style.font.title
  }

  Vitals.MeterRow {
    width: parent.width
    label: "USED"
    fraction: Vitals.Sampler.memPercent / 100
    valueText: panel.gib(Vitals.Sampler.memory.usedKb) + " / "
      + panel.gib(Vitals.Sampler.memory.totalKb) + " GiB"
    foreground: panel.fg
    fontFamily: panel.ff
  }

  Vitals.MeterRow {
    width: parent.width
    label: "CACHED"
    fraction: Vitals.Sampler.memory.totalKb > 0
      ? Vitals.Sampler.memory.cachedKb / Vitals.Sampler.memory.totalKb : 0
    valueText: panel.gib(Vitals.Sampler.memory.cachedKb) + " GiB"
    foreground: panel.fg
    fontFamily: panel.ff
  }

  Vitals.MeterRow {
    width: parent.width
    visible: Vitals.Sampler.memory.swapTotalKb > 0
    label: "SWAP"
    fraction: Vitals.Sampler.memory.swapTotalKb > 0
      ? Vitals.Sampler.memory.swapUsedKb / Vitals.Sampler.memory.swapTotalKb : 0
    valueText: panel.gib(Vitals.Sampler.memory.swapUsedKb) + " / "
      + panel.gib(Vitals.Sampler.memory.swapTotalKb) + " GiB"
    foreground: panel.fg
    fontFamily: panel.ff
  }

  PanelSeparator { foreground: panel.fg }

  Vitals.MeterRow {
    width: parent.width
    label: "PRESSURE (avg10)"
    fraction: Math.min(1, Vitals.Sampler.memory.pressure / 100)
    valueText: Vitals.Sampler.memory.pressure.toFixed(1) + "%"
    foreground: panel.fg
    fontFamily: panel.ff
  }
}
