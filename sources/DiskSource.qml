import QtQuick
import Quickshell.Io

// Disk telemetry. Throughput comes from /proc/diskstats (sectors read/written,
// 512 bytes each) sampled on the main tick; capacity comes from `df -B1` run on
// a slow 30s cadence off the main tick, because QML has no statvfs and forking
// df every 2s would be wasteful for a number that barely moves.
//
//   readBytesPerSec / writeBytesPerSec  real
//   percent    int   used capacity % of the root filesystem
//   usedBytes / totalBytes  real  root filesystem
//   sampled()  signal (throughput)
Item {
  id: source

  property real readBytesPerSec: 0
  property real writeBytesPerSec: 0
  property int percent: 0
  property real usedBytes: 0
  property real totalBytes: 0

  readonly property real sectorSize: 512
  readonly property real ceilingBps: 200 * 1024 * 1024  // ~200 MB/s soft ceiling

  signal sampled()

  property real _prevRead: 0
  property real _prevWrite: 0
  property double _prevT: 0

  function poll() {
    diskstats.reload()
  }

  // Called by the Sampler on a slow cadence.
  function pollCapacity() {
    if (!dfProc.running) dfProc.running = true
  }

  function _parse(text) {
    // Sum whole physical disks only (nvme0n1, sda, ...), skipping partitions
    // (nvme0n1p1, sda1) and virtual devices (dm-, zram, loop) so throughput is
    // not double-counted.
    var lines = String(text || "").split("\n")
    var totalRead = 0, totalWrite = 0
    for (var i = 0; i < lines.length; i++) {
      var p = lines[i].trim().split(/\s+/)
      if (p.length < 10) continue
      var name = p[2]
      if (/^(loop|zram|dm-|ram)/.test(name)) continue
      if (/\d+p\d+$/.test(name) || /[a-z]\d+$/.test(name)) continue // partitions
      totalRead += parseFloat(p[5]) || 0   // sectors read
      totalWrite += parseFloat(p[9]) || 0  // sectors written
    }
    totalRead *= source.sectorSize
    totalWrite *= source.sectorSize

    var now = Date.now()
    if (source._prevT > 0) {
      var dt = (now - source._prevT) / 1000
      if (dt > 0) {
        source.readBytesPerSec = Math.max(0, (totalRead - source._prevRead) / dt)
        source.writeBytesPerSec = Math.max(0, (totalWrite - source._prevWrite) / dt)
      }
    }
    source._prevRead = totalRead
    source._prevWrite = totalWrite
    source._prevT = now
    source.sampled()
  }

  FileView {
    id: diskstats
    path: "/proc/diskstats"
    printErrors: false
    onLoaded: source._parse(text())
  }

  // df for the root filesystem only. -B1 = bytes, --output pins column order.
  Process {
    id: dfProc
    command: ["df", "-B1", "--output=size,used", "/"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = String(text || "").trim().split("\n")
        if (lines.length < 2) return
        var p = lines[lines.length - 1].trim().split(/\s+/)
        source.totalBytes = parseFloat(p[0]) || 0
        source.usedBytes = parseFloat(p[1]) || 0
        source.percent = source.totalBytes > 0
          ? Math.round(source.usedBytes / source.totalBytes * 100) : 0
      }
    }
  }
}
