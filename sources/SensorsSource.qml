import QtQuick
import Quickshell.Io

// Sensor telemetry from /sys/class/hwmon. Because QML has no glob, the plugin's
// enumerate-sensors script walks hwmon once at startup and emits JSONL; this
// source caches the resolved *_input paths and reads them via FileView on the
// (slower, 5s) sensor cadence — Mac Stats attributes up to 50% of its CPU to
// Sensors, hence the separate interval.
//
//   sensors  [ {key,chip,label,type,path,value} ]  value in °C (temp) or RPM (fan)
//   maxTemp  int    hottest temperature, for the bar glyph default
//   sampled() signal
Item {
  id: source

  // The plugin directory, resolved so the helper ships with the plugin.
  property string pluginDir: ""

  property var sensors: []
  property int maxTemp: 0
  property bool ready: false

  signal sampled()

  function enumerate() {
    if (pluginDir === "") return
    enumProc.command = [pluginDir + "scripts/enumerate-sensors"]
    enumProc.running = true
  }

  function poll() {
    if (!ready) { enumerate(); return }
    reader.reloadAll()
  }

  function _rescale(type, raw) {
    return type === "temp" ? Math.round(raw / 1000) : Math.round(raw)
  }

  Process {
    id: enumProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var out = []
        var lines = String(text || "").trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
          var l = lines[i].trim()
          if (l === "") continue
          try {
            var o = JSON.parse(l)
            o.value = 0
            out.push(o)
          } catch (e) { /* skip malformed line */ }
        }
        source.sensors = out
        source.ready = out.length > 0
        if (source.ready) reader.reloadAll()
      }
    }
  }

  // One FileView per resolved path, rebuilt when the sensor list changes.
  Repeater {
    id: reader
    model: source.sensors

    function reloadAll() {
      for (var i = 0; i < count; i++) {
        var it = itemAt(i)
        if (it) it.reload()
      }
    }

    Item {
      required property var modelData
      required property int index

      function reload() { fv.reload() }

      FileView {
        id: fv
        path: modelData.path
        printErrors: false
        onLoaded: {
          var raw = parseFloat(String(text() || "").trim())
          if (!isFinite(raw)) return
          var v = source._rescale(modelData.type, raw)
          // Mutate a copy of the array so bindings on `sensors` re-evaluate.
          var next = source.sensors.slice()
          if (next[index]) {
            next[index] = Object.assign({}, next[index], { value: v })
            source.sensors = next
          }
          // Recompute hottest temperature.
          var hot = 0
          for (var i = 0; i < next.length; i++)
            if (next[i].type === "temp" && next[i].value > hot) hot = next[i].value
          source.maxTemp = hot
          source.sampled()
        }
      }
    }
  }
}
