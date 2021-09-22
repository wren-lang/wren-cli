class Resolver {
  // this is called at the end of this script when the CLI starts up
  // and the Resolver VM is fired up
  static boot() {
    __modules = {}
  }
  static DEBUG { false }
  static debug(s) { 
    if (this.DEBUG) System.print(s) 
  }
  // load a dynamic library
  static loadLibrary(name, file, root) {
    debug("loadLibrary(`%(name)`, `%(file)`, `%(root)`)")
    var libPath
    var moduleDirectories = findModulesDirectories(root)
    if (moduleDirectories.isEmpty) {
      Fiber.abort("dynamic libraries require a wren_modules folder")
    }
    for (moduleDirectory in moduleDirectories ) {
      debug(" - searching %(moduleDirectory)")
      libPath = Path.new(moduleDirectory).join(file).toString
      if (File.existsSync(libPath)) {
        debug(" - loading dynamic library `%(file)`")
        File.loadDynamicLibrary(name, libPath)
        return
      }
    }
    Fiber.abort(" # dynamic library `%(name)` - `%(file)` not found")
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
    debug("resolveModule(`%(importer)`, `%(module)`, `%(rootDir)`)")
    if (isLibrary(module)) {
      var pieces = module.split(":")
      module = pieces[1]
      var libraryName = pieces[0]
      // TODO: linux, windows, etc.
      var libraryFile = "lib%(pieces[0]).dylib"
      loadLibrary(libraryName, libraryFile, rootDir)
      return module
    }
    // System.print("importer: %(importer)  module: %(module)")
    if (PathType.resolve(module) == PathType.SIMPLE) return module

    debug("dirname: %(Path.new(importer).dirname)")
    var path = Path.new(importer).dirname.join(module)
    debug("resolved: %(path.toString)")
    return path.toString
  }

  // walks the tree starting with current root and attemps to find 
  // `wren_modules` which will be used to resolve modules in addition
  // to built-in modules
  static findModulesDirectories(root) {
    // switch to using absolute pathss
    root = File.realPathSync(root)
    if (__modules[root]) return __modules[root]
    var moduleCollections = []

    var path = Path.new(root + "/")
    while(true) {
      var modules = path.join("wren_modules/").toString 
      debug(" ? checking for existance: %(modules)")
      if (File.existsSync(modules)) {
        debug("- found modules in %(modules)")
        // return modules
        moduleCollections.add(modules)
      }
      if (path.isRoot) break
      path = path.up()
    }
    __modules[root] = moduleCollections
    return moduleCollections
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
    debug("trying: %(moduleDirectory)")
    if (File.existsSync(moduleDirectory)) {
      debug("found module: %(moduleDirectory)")
      return moduleDirectory
    }
  }

  // Attempts to find the source for [module] relative to the current root
  // directory.
  //
  // Returns the filename to load if found, or `:%(module)` if not which
  // is the pattern C uses to attempt a built-in module load, ie:
  // returning `:os` will instruct C to use the internal `os` module.
  static loadModule(module, rootDir) {
    debug("loadModule(%(module), %(rootDir)")
    var type = PathType.resolve(module)
    debug(type)
    if (type == PathType.ABSOLUTE || type == PathType.RELATIVE) {
      var path = "%(module).wren"
      return path
    }

    var root = File.realPathSync(rootDir)
    debug("root: %(root)")
    for (wren_modules in findModulesDirectories(root)) {
      var loc = findModule(wren_modules, module)
      if (loc!=null) {
        debug("found %(module) in %(wren_modules)")
        return loc
      }
    }
    debug("must be built-in? returning :%(module)")
    // must be built-in
    return ":%(module)"
  }
}

class File {
  foreign static loadDynamicLibrary(name, path)
  foreign static existsSync(s)
  foreign static realPathSync(s)
}

Resolver.boot()


