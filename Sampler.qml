pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "sources" as Vitals

// The single sampler shared by every Vitals widget in the bar.
//
// Facade-independent by design: rather than asking the host for a shared
// `service` object (whose third-party availability is uncertain), Vitals ships
// its own `pragma Singleton`. Quickshell instantiates exactly one per process,
// so N bar entries share one timer and one set of readings.
//
// Widgets never read /proc themselves. They subscribe to the modules they
// render; the sampler refcounts subscriptions and only reads a file when at
// least one widget wants that module.
Singleton {
  id: sampler

  readonly property int historyLength: 60

  // ---- Subscription refcounting -------------------------------------------
  property var _refs: ({})

  function subscribe(module) {
    var m = String(module || "")
    if (m === "") return
    _refs[m] = (_refs[m] || 0) + 1
    _refs = _refs
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

  // Push a value onto a bounded ring buffer, returning a new array (assigning
  // a fresh array is what makes QML bindings on `*History` re-evaluate).
  function _push(arr, value) {
    var next = arr.slice()
    next.push(value)
    if (next.length > historyLength) next.shift()
    return next
  }

  // ---- CPU ----------------------------------------------------------------
  property alias cpu: cpuSource
  readonly property int cpuPercent: cpuSource.percent
  property var cpuHistory: []

  Vitals.CpuSource {
    id: cpuSource
    onSampled: sampler.cpuHistory = sampler._push(sampler.cpuHistory, percent)
  }

  // ---- Memory -------------------------------------------------------------
  property alias memory: memorySource
  readonly property int memPercent: memorySource.percent
  property var memHistory: []

  Vitals.MemorySource {
    id: memorySource
    onSampled: sampler.memHistory = sampler._push(sampler.memHistory, percent)
  }

  // ---- The one timer ------------------------------------------------------
  Timer {
    id: tick
    interval: 2000
    repeat: true
    running: false
    triggeredOnStart: true
    onTriggered: {
      if (sampler.subscribed("cpu")) cpuSource.poll()
      if (sampler.subscribed("memory")) memorySource.poll()
    }
  }
}
