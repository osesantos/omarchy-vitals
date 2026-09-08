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

  // Reactive per-module subscription flags. Timer `running:` bindings depend on
  // these — a plain subscribed() function call does not establish a QML
  // dependency, so timers would never start (the disk/sensors 0-value bug).
  readonly property bool cpuOn: (_refs["cpu"] || 0) > 0
  readonly property bool memoryOn: (_refs["memory"] || 0) > 0
  readonly property bool networkOn: (_refs["network"] || 0) > 0
  readonly property bool diskOn: (_refs["disk"] || 0) > 0
  readonly property bool sensorsOn: (_refs["sensors"] || 0) > 0

  function subscribe(module) {
    var m = String(module || "")
    if (m === "") return
    var next = Object.assign({}, _refs)
    next[m] = (next[m] || 0) + 1
    _refs = next
  }

  function unsubscribe(module) {
    var m = String(module || "")
    if (m === "" || !_refs[m]) return
    var next = Object.assign({}, _refs)
    next[m] = next[m] - 1
    if (next[m] <= 0) delete next[m]
    _refs = next
  }

  function subscribed(module) {
    return (_refs[String(module || "")] || 0) > 0
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

  // ---- Network ------------------------------------------------------------
  property alias network: networkSource
  readonly property int netPercent: networkSource.percent
  property var netHistory: []

  Vitals.NetworkSource {
    id: networkSource
    onSampled: sampler.netHistory = sampler._push(sampler.netHistory, percent)
  }

  // ---- Disk ---------------------------------------------------------------
  property alias disk: diskSource
  readonly property int diskPercent: diskSource.percent
  property var diskHistory: []

  Vitals.DiskSource {
    id: diskSource
    onSampled: sampler.diskHistory = sampler._push(sampler.diskHistory,
      Math.min(100, Math.round(Math.max(readBytesPerSec, writeBytesPerSec) / ceilingBps * 100)))
  }

  // ---- Sensors ------------------------------------------------------------
  // Resolve the plugin directory so the enumeration helper ships with the
  // plugin rather than depending on PATH.
  readonly property string pluginDir: {
    var u = String(Qt.resolvedUrl("."))
    if (u.indexOf("file://") === 0) u = u.substring(7)
    return u.charAt(u.length - 1) === "/" ? u : u + "/"
  }

  property alias sensors: sensorsSource
  readonly property int maxTemp: sensorsSource.maxTemp
  property var sensorsList: []

  Vitals.SensorsSource {
    id: sensorsSource
    pluginDir: sampler.pluginDir
    onSampled: sampler.sensorsList = sensors
  }

  // ---- Top processes (on demand) ------------------------------------------
  // Polled by CPU/memory panels on open, never on the tick.
  property alias processes: processSource
  property var processList: []

  function pollProcesses(sortKey) { processSource.poll(sortKey) }

  Vitals.ProcessSource {
    id: processSource
    onSampled: sampler.processList = list
  }

  // ---- The one timer ------------------------------------------------------
  Timer {
    id: tick
    interval: 2000
    repeat: true
    running: sampler.cpuOn || sampler.memoryOn || sampler.networkOn || sampler.diskOn
    triggeredOnStart: true
    onTriggered: {
      if (sampler.cpuOn) cpuSource.poll()
      if (sampler.memoryOn) memorySource.poll()
      if (sampler.networkOn) networkSource.poll()
      if (sampler.diskOn) diskSource.poll()
    }
  }

  // Disk capacity (df) on a slow cadence, off the main tick — QML has no
  // statvfs and df barely changes.
  Timer {
    interval: 30000
    repeat: true
    running: sampler.diskOn
    triggeredOnStart: true
    onTriggered: if (sampler.diskOn) diskSource.pollCapacity()
  }

  // Sensors on a slower 5s cadence — reading many hwmon files is comparatively
  // expensive, and temperatures move slowly.
  Timer {
    interval: 5000
    repeat: true
    running: sampler.sensorsOn
    triggeredOnStart: true
    onTriggered: if (sampler.sensorsOn) sensorsSource.poll()
  }
}
