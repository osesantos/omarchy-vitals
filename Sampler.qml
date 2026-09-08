pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The single sampler shared by every Vitals widget in the bar.
//
// Facade-independent by design: rather than asking the host for a shared
// `service` object (whose third-party availability is uncertain — see the
// plan's facade risk), Vitals ships its own `pragma Singleton`. Quickshell
// instantiates exactly one of these per process, so N bar entries share one
// timer and one set of readings no matter how they were placed.
//
// Widgets never read /proc themselves. They subscribe to the modules they
// render; the sampler refcounts subscriptions and only reads a file when at
// least one widget wants that module. A bar with only a CPU widget never
// touches /proc/meminfo.
Singleton {
  id: sampler

  // ---- Subscription refcounting -------------------------------------------
  // moduleName -> number of live widgets subscribed. A module is sampled iff
  // its count is > 0.
  property var _refs: ({})

  function subscribe(module) {
    var m = String(module || "")
    if (m === "") return
    _refs[m] = (_refs[m] || 0) + 1
    _refs = _refs // nudge bindings
    tick.running = _anyActive()
  }

  function unsubscribe(module) {
    var m = String(module || "")
    if (m === "" || !_refs[m]) return
    _refs[m] = _refs[m] - 1
    if (_refs[m] <= 0) delete _refs[m]
    _refs = _refs
    tick.running = _anyActive()
  }

  function subscribed(module) {
    return (_refs[String(module || "")] || 0) > 0
  }

  function _anyActive() {
    for (var k in _refs) if (_refs[k] > 0) return true
    return false
  }

  // ---- CPU ----------------------------------------------------------------
  // Aggregate CPU busy percentage over the last interval, from /proc/stat.
  property int cpuPercent: 0

  property var _cpuPrevTotal: 0
  property var _cpuPrevIdle: 0

  function _sampleCpu() {
    cpuStat.reload()
  }

  function _parseCpu(text) {
    // First line: "cpu  user nice system idle iowait irq softirq steal ..."
    var line = String(text || "").split("\n")[0]
    var parts = line.trim().split(/\s+/)
    if (parts[0] !== "cpu" || parts.length < 5) return

    var idle = parseInt(parts[4]) + (parts.length > 5 ? parseInt(parts[5]) : 0) // idle + iowait
    var total = 0
    for (var i = 1; i < parts.length; i++) {
      var n = parseInt(parts[i])
      if (isFinite(n)) total += n
    }

    var dTotal = total - sampler._cpuPrevTotal
    var dIdle = idle - sampler._cpuPrevIdle
    if (sampler._cpuPrevTotal > 0 && dTotal > 0) {
      var busy = Math.round((1 - dIdle / dTotal) * 100)
      sampler.cpuPercent = Math.max(0, Math.min(100, busy))
    }
    sampler._cpuPrevTotal = total
    sampler._cpuPrevIdle = idle
  }

  FileView {
    id: cpuStat
    path: "/proc/stat"
    printErrors: false
    onLoaded: sampler._parseCpu(text())
  }

  // ---- The one timer ------------------------------------------------------
  Timer {
    id: tick
    interval: 2000
    repeat: true
    running: false
    triggeredOnStart: true
    onTriggered: {
      if (sampler.subscribed("cpu")) sampler._sampleCpu()
    }
  }
}
