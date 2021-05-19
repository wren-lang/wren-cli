#module=resolver
class Path {
  construct new(path) { _path = path }
  sep { "/" }
  toString { _path }
  up() { join("..") }
  join(path) { Path.new(_path + "/" + path).normalize }
  isRoot { 
    return _path == "/"  || (_path.count == 3 && _path[1..2] == ":\\") 
  }
  dirname {
    if (_path=="/") return this
    if (_path.endsWith("/")) return Path.new(_path[0..-2])
    return up()
  }
  normalize {
    var paths = _path.split(sep)
    var finalPaths = []
    if (_path.startsWith("/")) finalPaths.add("/") 
    if (paths[0]==".") finalPaths.add(".") 
    for (path in paths) {
      var last = finalPaths.count>0 ? finalPaths[-1] : null
      if (path == "..") {
        if (last == "/") continue
        if (last == ".." || last == null) {
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
    var path = finalPaths.join("/")
    if (path == "") path = "."
    return Path.new(path)
  }
}