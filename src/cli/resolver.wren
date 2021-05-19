class Resolver {
  static DEBUG { false }
  static debug(s) { 
    if (this.DEBUG) System.print(s) 
  }
  // load a dynamic library
  static loadLibrary(name, file, root) {
    var moduleDirectory = findModulesDirectory(root)
    if (moduleDirectory == null) {
      Fiber.abort("dynamic libraries require a wren_modules folder")
    }
    var libPath = Path.new(moduleDirectory).join(file).toString
    if (!File.existsSync(libPath)) {
      Fiber.abort("library not found -- %(libPath)")
    }
    // System.print(libPath)
    File.loadDynamicLibrary(name, libPath)
  }
  static isLibrary(module) { module.contains(":") }
  // Applies the CLI's import resolution policy. The rules are:
  //
  // * If [module] starts with "./" or "../", it is a relative import, relative
  //   to [importer]. The resolved path is [name] concatenated onto the directory
  //   containing [importer] and then normalized.
  //
  //   For example, importing "./a/./b/../c" from "./d/e/f" gives you "./d/e/a/c".
  static resolveModule(importer, module, rootDir) {
    if (isLibrary(module)) {
      var pieces = module.split(":")
      module = pieces[1]
      var libraryName = pieces[0]
      var libraryFile = "lib%(pieces[0]).dylib"
      loadLibrary(libraryName, libraryFile, rootDir)
      return module
    }
    // System.print("importer: %(importer)  module: %(module)")
    if (PathType.resolve(module) == PathType.SIMPLE) return module

    var path = Path.new(importer).dirname.join(module)
    debug("resolved: %(path.toString)")
    return path.toString
  }

  // walks the tree starting with current root and attemps to find 
  // `wren_modules` which will be used to resolve modules in addition
  // to built-in modules
  static findModulesDirectory(root) {
    var path = Path.new(root + "/")
    while(true) {
      var modules = path.join("wren_modules/").toString 
      debug(modules)
      if (File.existsSync(modules)) return modules
      if (path.isRoot) break
      path = path.up()
    }
  }

  // searches for a module inside `wren_modules`
  //
  // If the module is a single bare name, treat it as a module with the same
  // name inside the package. So "foo" means "foo/foo".
  //
  // returns the path to the .wren file that needs to be loaded
  static findModule(root, module) {
    var segment
    if (module.contains("/")) {
      segment = "%(module).wren"
    } else {
      segment = "%(module)/%(module).wren"
    }
    var moduleDirectory = Path.new(root).join(segment).toString
    debug(moduleDirectory)
    if (File.existsSync(moduleDirectory)) return moduleDirectory
  }

  // Attempts to find the source for [module] relative to the current root
  // directory.
  //
  // Returns the filename to load if found, or `:%(module)` if not which
  // is the pattern C uses to attempt a built-in module load, ie:
  // returning `:os` will instruct C to use the internal `os` module.
  static loadModule(module, rootDir) {
    var type = PathType.resolve(module)
    if (type == PathType.ABSOLUTE || type == PathType.RELATIVE) {
      var path = "%(module).wren"
      return path
    }

    var root = File.realPathSync(rootDir)
    debug("root: %(root)")
    var wren_modules = findModulesDirectory(root)
    if (wren_modules != null) {
      var loc = findModule(wren_modules, module)
      if (loc!=null) {
        debug("found %(module) in %(wren_modules)")
        return loc
      }
    }
    // must be built-in
    return ":%(module)"
  }
}

class Path {
  construct new(path) {
    _path = path
  }
  dirname {
    var pieces = _path.split("/")
    return Path.new(pieces[0..-2].join("/"))
    // debug(_path)
    // var pos = _path.indexOf("/",-1)
    // debug(pos)
    // return Path.new(_path[0..pos])
  }
  isRoot { 
    return _path == "/"  || (_path.count == 3 && path[1..2] == ":\\") 
  }
  up() {
    // TODO: we can do this without realPathSync
    return Path.new(File.realPathSync(_path + "/.."))
  }
  stripRelative(s) {
    if (s.startsWith("./")) return s[2..-1]
    return s
  }
  join(path) {
    return Path.new((_path + "/" + stripRelative(path)).replace("//","/"))
  }
  toString { _path }
}

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

class File {
  foreign static loadDynamicLibrary(name, path)
  foreign static existsSync(s)
  foreign static realPathSync(s)
}



