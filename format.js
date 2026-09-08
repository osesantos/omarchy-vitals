.pragma library

// Human-readable byte-rate, e.g. 1536 -> "1.5 KB/s".
function rate(bytesPerSec) {
  var b = bytesPerSec || 0
  if (b < 1024) return Math.round(b) + " B/s"
  var kb = b / 1024
  if (kb < 1024) return kb.toFixed(kb < 10 ? 1 : 0) + " KB/s"
  var mb = kb / 1024
  if (mb < 1024) return mb.toFixed(mb < 10 ? 1 : 0) + " MB/s"
  return (mb / 1024).toFixed(1) + " GB/s"
}

// Human-readable byte size, e.g. 1073741824 -> "1.0 GiB".
function size(bytes) {
  var b = bytes || 0
  var units = ["B", "KiB", "MiB", "GiB", "TiB"]
  var i = 0
  while (b >= 1024 && i < units.length - 1) { b /= 1024; i++ }
  return b.toFixed(i === 0 ? 0 : 1) + " " + units[i]
}
