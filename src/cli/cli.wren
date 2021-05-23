import "repl" for Repl, AnsiRepl, SimpleRepl
import "os" for Platform, Process
import "io" for Stdin, File, Stdout, Stat
import "meta" for Meta

// TODO: Wren needs to expose System.version
// https://github.com/wren-lang/wren/issues/1016
class Wren {
  static CLI_VERSION { "0.1" }
  static VERSION { "0.4" }
}

// TODO: how to avoid duplication?
// we only use this for absolute path
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

class CLI {
  static start() {
    // TODO: pull out argument processing into it's own class
    if (Process.allArguments.count >=2) {
      var flag = Process.allArguments[1]
      if (flag == "--version" || flag == "-v") {
        showVersion()
        return
      }
      if (flag == "--help" || flag == "-h") {
        showHelp()
        return
      }
      if (flag == "-e" && Process.allArguments.count >= 3) {
        var code = Process.allArguments[2]
        runCode(code,"<eval>")
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
  static versionInfo { "wrenc v%(Wren.CLI_VERSION) (wren v%(Wren.VERSION))" }
  static showVersion() {
    System.print(versionInfo) 
  }
  static showHelp() {
    System.print("Usage: wrenc [file] [arguments...]")
    System.print("")
    System.print("Optional arguments:")
    System.print("  -                read script from stdin")
    System.print("  -h, --help       print wrenc command line options")
    System.print("  -v, --version    print wrenc and Wren version")
    System.print("  -e '[code]'      evaluate code")
    System.print()
    System.print("Documentation can be found at https://github.com/joshgoebel/wren-console")
    
  }
  static dirForModule(file) {
    return file.split("/")[0..-2].join("/")
  }
  static missingScript(file) {
    System.print("wrenc: No such file -- %(file)")
  }
  static runCode(code,moduleName) {
    var fn = Meta.compile(code,moduleName)
    if (fn != null) {
      fn.call()
    } else {
      // TODO: Process.exit() 
      // https://github.com/wren-lang/wren-cli/pull/74
      Fiber.abort("COMPILE ERROR, should exit 65")
    }
  }
  static runInput() {
    var code = ""
    while(!Stdin.isClosed) code = code + Stdin.read()
    runCode(code,"(script)")
    return
  }
  static runFile(file) {
    var moduleName

    if (file == "-") return runInput()
    if (!File.exists(file)) return missingScript(file)
    
    if (PathType.resolve(file) == PathType.ABSOLUTE) {
      moduleName = file
    } else {
      moduleName = "./" + file
    }
    
    var code = File.read(file)
    setRootDirectory_(dirForModule(moduleName))
    // System.print(moduleName)
    runCode(code,moduleName)
  }
  static repl() {
    System.print(""" -"\//""")
    System.print("  \\_/    \n%(versionInfo) (based on wren-cli@9c6b6933722)") 
    // " fix broken VS Code highlighting (not understaning escapes)

    Repl.start()
  }
  foreign static setRootDirectory_(dir) 
}
CLI.start()

