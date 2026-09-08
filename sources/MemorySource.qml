import QtQuick
import Quickshell.Io

// Memory telemetry from /proc/meminfo and /proc/pressure/memory.
//
//   percent    int   used %, matching what free(1) calls "used"
//   totalKb    real  MemTotal, KiB
//   usedKb     real  total - available, KiB
//   availKb    real  MemAvailable, KiB
//   cachedKb   real  Cached, KiB
//   swapTotalKb / swapUsedKb  real  KiB
//   pressure   real  memory some avg10 (0 when unavailable)
//   sampled()  signal
Item {
  id: source

  property int percent: 0
  property real totalKb: 0
  property real usedKb: 0
  property real availKb: 0
  property real cachedKb: 0
  property real swapTotalKb: 0
  property real swapUsedKb: 0
  property real pressure: 0

  signal sampled()

  function poll() {
    meminfo.reload()
    psi.reload()
  }

  function _parse(text) {
    var fields = {}
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^(\w+):\s+(\d+)/)
      if (m) fields[m[1]] = parseFloat(m[2])
    }
    source.totalKb = fields.MemTotal || 0
    source.availKb = fields.MemAvailable !== undefined
      ? fields.MemAvailable
      : (fields.MemFree || 0) + (fields.Cached || 0) + (fields.Buffers || 0)
    source.cachedKb = fields.Cached || 0
    source.usedKb = Math.max(0, source.totalKb - source.availKb)
    source.swapTotalKb = fields.SwapTotal || 0
    source.swapUsedKb = Math.max(0, (fields.SwapTotal || 0) - (fields.SwapFree || 0))
    source.percent = source.totalKb > 0
      ? Math.round(source.usedKb / source.totalKb * 100) : 0
    source.sampled()
  }

  FileView {
    id: meminfo
    path: "/proc/meminfo"
    printErrors: false
    onLoaded: source._parse(text())
  }

  FileView {
    id: psi
    path: "/proc/pressure/memory"
    printErrors: false
    onLoaded: {
      var m = String(text() || "").match(/some\s+avg10=([\d.]+)/)
      source.pressure = m ? parseFloat(m[1]) : 0
    }
  }
}
