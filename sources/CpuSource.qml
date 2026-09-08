import QtQuick
import Quickshell.Io

// CPU telemetry from /proc/stat (aggregate + per-core busy %), /proc/loadavg,
// and scaling_cur_freq. Keeps the *shape* of a CPU reading separate from the
// files it comes from: everything above reads these properties and never
// learns where they came from.
//
//   percent   int    aggregate busy %
//   cores     [int]  per-core busy %
//   load1/5/15 real  load averages
//   freqMhz   int    current frequency, MHz (0 when unavailable)
//   sampled() signal emitted after every reading that parsed
Item {
  id: source

  property int percent: 0
  property var cores: []
  property real load1: 0
  property real load5: 0
  property real load15: 0
  property int freqMhz: 0

  signal sampled()

  // Previous cumulative counters, keyed by cpu line label ("cpu", "cpu0", ...).
  property var _prevTotal: ({})
  property var _prevIdle: ({})

  function poll() {
    stat.reload()
    loadavg.reload()
    freq.reload()
  }

  function _lineBusy(label, parts) {
    // parts: user nice system idle iowait irq softirq steal ...
    var idle = parseInt(parts[3]) + (parts.length > 4 ? parseInt(parts[4]) : 0)
    var total = 0
    for (var i = 0; i < parts.length; i++) {
      var n = parseInt(parts[i])
      if (isFinite(n)) total += n
    }
    var pt = source._prevTotal[label] || 0
    var pi = source._prevIdle[label] || 0
    var busy = 0
    var dTotal = total - pt
    var dIdle = idle - pi
    if (pt > 0 && dTotal > 0) busy = Math.max(0, Math.min(100, Math.round((1 - dIdle / dTotal) * 100)))
    source._prevTotal[label] = total
    source._prevIdle[label] = idle
    return busy
  }

  function _parseStat(text) {
    var lines = String(text || "").split("\n")
    var newCores = []
    var agg = 0
    for (var i = 0; i < lines.length; i++) {
      var t = lines[i].trim()
      if (t.indexOf("cpu") !== 0) continue
      var parts = t.split(/\s+/)
      var label = parts.shift()
      if (parts.length < 4) continue
      var busy = _lineBusy(label, parts)
      if (label === "cpu") agg = busy
      else newCores.push(busy)
    }
    source.percent = agg
    source.cores = newCores
    source.sampled()
  }

  FileView {
    id: stat
    path: "/proc/stat"
    printErrors: false
    onLoaded: source._parseStat(text())
  }

  FileView {
    id: loadavg
    path: "/proc/loadavg"
    printErrors: false
    onLoaded: {
      var p = String(text() || "").trim().split(/\s+/)
      source.load1 = parseFloat(p[0]) || 0
      source.load5 = parseFloat(p[1]) || 0
      source.load15 = parseFloat(p[2]) || 0
    }
  }

  FileView {
    id: freq
    path: "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"
    printErrors: false
    onLoaded: {
      var khz = parseInt(String(text() || "").trim())
      source.freqMhz = isFinite(khz) ? Math.round(khz / 1000) : 0
    }
  }
}
