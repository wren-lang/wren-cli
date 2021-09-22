//module=resolver,cli
class Path {
  construct new(path) { 
    _path = path 
    _sep = appearsWindows() ? "\\" : "/"
  }
  appearsWindows() {
    if (_path.contains("\\")) return true
    if (_path.count>=2 && _path[1] == ":") return true
  }
  sep { _sep || "/" }
  toString { _path }
  up() { join("..") }
  join(path) { Path.new(_path + sep + path).normalize }
  isRoot { 
    return _path == "/"  || 
      // C:
      (_path.count == 2 && _path[1] == ":") ||
      // F:\
      (_path.count == 3 && _path[1..2] == ":\\") 
  }
  dirname {
    if (_path=="/") return this
    if (_path.endsWith(sep)) return Path.new(_path[0..-2])
    return up()
  }
  static split(path) {
    var segments = []
    var last = 0
    var i = 0
    while (i < path.count) {
      var char = path[i]
      if (char == "/" || char == "\\") {
        if (last==i) {
          segments.add("")
        } else {
          segments.add(path[last...i])
        }
        last = i + 1
      }
      i = i + 1
    }
    if (last<path.count) {
      segments.add(path[last..-1])
    } else if (last==i) {
      segments.add("")
    }
    return segments
  }
  normalize {
    // var paths = _path.split(sep)
    var paths = Path.split(_path)
    var finalPaths = []
    if (_path.startsWith("/")) finalPaths.add("/") 
    if (paths[0]==".") finalPaths.add(".") 
    for (path in paths) {
      var last = finalPaths.count>0 ? finalPaths[-1] : null
      if (path == "..") {
        if (last == "/") continue

        if (last == ".")  {
          finalPaths[-1] = ".."
        } else if (last == ".." || last == null) {
          finalPaths.add("%(path)")  
        } else {
          if (finalPaths.count > 0) finalPaths.removeAt(finalPaths.count - 1)
        }
      } else if (path == "" || path == ".") {
        continue
      } else {
        finalPaths.add(path)
      }
    }
    if (finalPaths.count>1 && finalPaths[0] == "/") finalPaths[0] = ""
    var path = finalPaths.join(sep)
    if (path == "") path = "."
    return Path.new(path)
  }
}