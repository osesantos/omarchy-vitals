import QtQuick
import Quickshell.Io

// Top processes by CPU or memory, via `ps`. Run on demand only — never on the
// sampler tick — because it forks and the list is only visible while a panel is
// open. The panel calls poll("cpu") or poll("mem") on open.
//
//   list  [ {name, cpu, mem} ]  top N, sorted by the requested key
Item {
  id: source

  property int limit: 5
  property var list: []

  signal sampled()

  function poll(sortKey) {
    var key = sortKey === "mem" ? "-%mem" : "-%cpu"
    proc.command = ["ps", "-eo", "comm,%cpu,%mem", "--sort=" + key, "--no-headers"]
    proc.running = true
  }

  Process {
    id: proc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var out = []
        var lines = String(text || "").trim().split("\n")
        for (var i = 0; i < lines.length && out.length < source.limit; i++) {
          var p = lines[i].trim().split(/\s+/)
          if (p.length < 3) continue
          out.push({
            name: p[0],
            cpu: parseFloat(p[1]) || 0,
            mem: parseFloat(p[2]) || 0
          })
        }
        source.list = out
        source.sampled()
      }
    }
  }
}
