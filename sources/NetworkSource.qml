import QtQuick
import Quickshell.Io

// Network telemetry from /proc/net/dev (rx/tx byte deltas) and operstate.
// Local IP is resolved once via a subprocess (see Widget/Sampler wiring; not
// on the sample tick).
//
//   rxBytesPerSec / txBytesPerSec  real
//   percent   int    a coarse 0..100 for chart fills, scaled to a soft ceiling
//   iface     string primary non-loopback interface with traffic
//   up        bool   operstate up
//   sampled() signal
Item {
  id: source

  property real rxBytesPerSec: 0
  property real txBytesPerSec: 0
  property int percent: 0
  property string iface: ""
  property bool up: false

  // Soft ceiling for the fill/percent charts: 12.5 MB/s ~= 100 Mbit link busy.
  readonly property real ceilingBps: 12.5 * 1024 * 1024

  signal sampled()

  property real _prevRx: 0
  property real _prevTx: 0
  property double _prevT: 0

  function poll() {
    netdev.reload()
    if (source.iface !== "") operstate.reload()
  }

  function _parse(text) {
    var lines = String(text || "").split("\n")
    var totalRx = 0, totalTx = 0
    var best = "", bestBytes = -1
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^\s*([^:]+):\s*(.*)$/)
      if (!m) continue
      var name = m[1].trim()
      if (name === "lo") continue
      var cols = m[2].trim().split(/\s+/)
      var rx = parseFloat(cols[0]) || 0
      var tx = parseFloat(cols[8]) || 0
      totalRx += rx
      totalTx += tx
      if (rx + tx > bestBytes) { bestBytes = rx + tx; best = name }
    }
    if (source.iface === "") source.iface = best

    var now = Date.now()
    if (source._prevT > 0) {
      var dt = (now - source._prevT) / 1000
      if (dt > 0) {
        source.rxBytesPerSec = Math.max(0, (totalRx - source._prevRx) / dt)
        source.txBytesPerSec = Math.max(0, (totalTx - source._prevTx) / dt)
        var busy = Math.max(source.rxBytesPerSec, source.txBytesPerSec) / source.ceilingBps
        source.percent = Math.max(0, Math.min(100, Math.round(busy * 100)))
      }
    }
    source._prevRx = totalRx
    source._prevTx = totalTx
    source._prevT = now
    source.sampled()
  }

  FileView {
    id: netdev
    path: "/proc/net/dev"
    printErrors: false
    onLoaded: source._parse(text())
  }

  FileView {
    id: operstate
    path: source.iface !== "" ? ("/sys/class/net/" + source.iface + "/operstate") : ""
    printErrors: false
    onLoaded: source.up = String(text() || "").trim() === "up"
  }
}
