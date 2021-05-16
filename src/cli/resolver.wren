class Resolver {
  static resolveModule(importer, module) {
    // System.print("importer: %(importer)  module: %(module)")
    if (Pathtype.resolve(module) == Pathtype.SIMPLE) return module

    var path = Path.new(importer).dirname.join(module)
    System.print("resolved: %(path.toString)")
    return path.toString
  }
  static loadModule(name) {
    
    // System.print("load %(name)")
  }
}

class Path {
  construct new(path) {
    _path = path
  }
  dirname {
    var pieces = _path.split("/")
    return Path.new(pieces[0..-2].join("/"))
    // System.print(_path)
    // var pos = _path.indexOf("/",-1)
    // System.print(pos)
    // return Path.new(_path[0..pos])
  }
  stripRelative(s) {
    if (s.startsWith("./")) return s[2..-1]
    return s
  }
  join(path) {
    return Path.new(_path + "/" + stripRelative(path))
  }
  toString { _path }
}

class Pathtype {
  static SIMPLE { 1 }
  static ABSOLUTE { 2 }
  static RELATIVE { 3 }

  static unixAbsolute(path) { path.startsWith("/") }
  static resolve(path) {
    if (path.startsWith(".")) return Pathtype.RELATIVE
    if (unixAbsolute(path)) return Pathtype.ABSOLUTE
    // TODO: ABSOLUTE windows
    return Pathtype.SIMPLE
  }
}
