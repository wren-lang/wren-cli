//module=resolver,cli
class PathType {
  static SIMPLE { 1 }
  static ABSOLUTE { 2 }
  static RELATIVE { 3 }

  static unixAbsolute(path) { path.startsWith("/") }
  static windowsAbsolute(path) {
    // TODO: is this not escaped properly by the stock Python code generator
    return path.count >= 3 && path[1..2] == ":\\"
  }
  static resolve(path) {
    if (path.startsWith(".")) return PathType.RELATIVE
    if (unixAbsolute(path)) return PathType.ABSOLUTE
    if (windowsAbsolute(path)) return PathType.ABSOLUTE

    return PathType.SIMPLE
  }
}
