import "repl" for Repl, AnsiRepl, SimpleRepl
import "os" for Platform, Process
import "io" for Stdin, Stderr, File, Stdout, Stat
import "mirror" for Mirror
import "meta" for Meta
import "runtime" for Runtime

class StackTrace {
  construct new(fiber) {
    _fiber = fiber
    _trace = Mirror.reflect(fiber).stackTrace
  }
  print() {
    Stderr.print(_fiber.error)
    var out = _trace.frames.map { |f|
        return "at %( f.methodMirror.signature ) (%( f.methodMirror.moduleMirror.name ) line %( f.line ))"
    }.join("\n")
    Stderr.print(out)
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
  static versionInfo { "wrenc v%(Runtime.VERSION) (wren v%(Runtime.WREN_VERSION))" }
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
    return Path.new(file).dirname.toString
  }
  static missingScript(file) {
    Stderr.print("wrenc: No such file -- %(file)")
  }
  static runCode(code,moduleName) {
    var fn = Meta.compile(code,moduleName)
    if (fn != null) {
      var fb = Fiber.new (fn)
      fb.try()
      if (fb.error) {
        StackTrace.new(fb).print()
        Process.exit(70)
      }
    } else {
      Process.exit(65)
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
// CLI.start()

