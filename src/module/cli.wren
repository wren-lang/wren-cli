import "repl" for Repl, AnsiRepl, SimpleRepl
import "os" for Platform, Process
import "io" for Stdin, File, Stdout
import "meta" for Meta

// TODO: Wren needs to expose System.version
// https://github.com/wren-lang/wren/issues/1016
class Wren {
  static VERSION { "0.4" }
}

class CLI {
  static start() {
    // TODO: pull out argument processing into it's own class
    if (Process.allArguments.count == 2) {
      if (Process.allArguments[1] == "--version") {
        showVersion()
        return
      }
      if (Process.allArguments[1] == "--help") {
        showHelp()
        return
      }
    }

    if (Process.allArguments.count == 1) {
      repl()
    } else {
      runFile(Process.allArguments[1])
    }
    Stdout.flush()
  }
  static showVersion() {
    System.print("wren v%(Wren.VERSION)") 
  }
  static showHelp() {
    System.print("Usage: wren [file] [arguments...]")
    System.print("")
    System.print("Optional arguments:")
    System.print("  --help     Show command line usage")
    System.print("  --version  Show version")
  }
  static dirForModule(file) {
    return file.split("/")[0..-2].join("/")
  }
  static missingScript(file) {
    System.print("wren_cli: No such file -- %(file)")
  }
  static runFile(file) {
    if (!File.exists(file)) return missingScript(file)

    // TODO: absolute paths, need Path class likely
    var moduleName = "./" + file
    var code = File.read(file)
    setRootDirectory_(dirForModule(moduleName))
    var fn = Meta.compile(code,moduleName)
    if (fn != null) {
      fn.call()
    } else {
      // TODO: Process.exit() 
      // https://github.com/wren-lang/wren-cli/pull/74
      Fiber.abort("COMPILE ERROR, should exit 65")
    }
  }
  static repl() {
    System.print("""\\\\/\\"-""")
    System.print(" \\\\_/    wren v%(Wren.VERSION)") 
    // " fix broken VS Code highlighting (not understaning escapes)

    Repl.start()
  }
  foreign static setRootDirectory_(dir) 
}
CLI.start()
