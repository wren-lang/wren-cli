import "io" for Directory
import "os" for Process

class Color {
  static GREEN { "\u001b[32m" }
  static RED { "\u001b[31m" }
  static BOLD { "\u001b[1m" }
  static RESET { "\u001b[0m" }
}

class Dependency {
  construct new(name, version, source) {
    _name = name
    _version = version
    _source = source
  }
  name { _name }
  version { _version }
  source { _source }
}

class Runner {
  construct new() {
    _jobs = []
  }
  add(cmd, args) { add(cmd,args,null) }
  add(cmd, args, path) {
    _jobs.add([cmd,args,path])
  }
  run(cmd, args) { run(cmd,args,null) }
  run(cmd, args, cwd) {
    var result
    System.print(" - [R] %(cmd) " + args.join(" "))
    return Process.exec(cmd, args, cwd)
  }
  go() {
    _jobs.each { |job|
      var r = run(job[0], job[1], job[2])
      if (r!=0) {
        Fiber.abort(" - FAILED (got error code %(r))")
      }
    }
  }
}

var ShowVersion = Fn.new() {
  System.print("wren-package v0.2.0 (embedded)")
}

class WrenPackage {
  construct new() {}
  dependencies() {}
  name { "package" }
  list() {
    System.print("%(name) dependencies:")
    dependencies.each { |dep|
      System.print("- %(dep.name) %(dep.version)")
    }
  }
  default() {
    if (["[-v]","[--version]"].contains(Process.arguments.toString)) {
      ShowVersion.call()
    } else if (Process.arguments.toString == "[install]") {
      install()
    } else {
      System.print("Usage:\n./package.wren install\n")
      list()
    }
  }
  install() {
    if (!Directory.exists("wren_modules")) Directory.create("wren_modules")
    dependencies.each { |dep|
        System.print(" - installing %(dep.name) %(dep.version)")
      if (Directory.exists("wren_modules/%(dep.name)")) {
        System.print(" - %(dep.name) already installed. To reinstall, remove first.")
        // Process.exec("git", ["fetch","--all"], "wren_modules/%(dep.name)")
        // Process.exec("git", ["checkout", dep.version], "wren_modules/%(dep.name)")
      } else {
        // var args = ["clone","-q","-b", dep.version,dep.source, "wren_modules/%(dep.name)"]
        var run=Runner.new()
        run.add("git", ["clone","-q",dep.source,"wren_modules/%(dep.name)"])
        run.add("git",["checkout", "--detach", dep.version], "wren_modules/%(dep.name)")
        var f = Fiber.new { run.go() }
        f.try()
        if (f.error != null) {
          System.print(" - Could not install dependency %(dep.name) %(dep.version)")
          System.print(" * %(dependencies.count) dependency(s). %(Color.RED)Failed to install.%(Color.RESET)")
          Process.exit(1)
        }
      }
    }
    System.print(" * %(dependencies.count) dependency(s). %(Color.GREEN)All good.%(Color.RESET)")
  }
}