import "scheduler" for Scheduler
import "ensure" for Ensure

class Platform {
  foreign static homePath
  foreign static isPosix
  foreign static name

  static isWindows { name == "Windows" }
}

class Process {
  // TODO: This will need to be smarter when wren supports CLI options.
  static arguments { allArguments.count >= 2 ? allArguments[2..-1] : [] }
  static exit() { exit(0) }
  static exit(code) {
    // sets the exit code on the C side and stops the UV loop
    exit_(code)
    // suspends our Fiber and with UV loop stopped, no futher Fibers should get
    // resumed so we should immediately stop and exit
    Fiber.suspend()
  }

  static exec(cmd) {
    return exec(cmd, null, null, null)
  }

  static exec(cmd, args) {
    return exec(cmd, args, null, null)
  }

  static exec(cmd, args, cwd) { 
    return exec(cmd, args, cwd, null) 
  }
  
  static exec(cmd, args, cwd, envMap) { 
    var env = []
    args = args || []
    if (envMap is Map) {
      for (entry in envMap) {
        env.add([entry.key, entry.value].join("="))
      }
    } else if (envMap == null) {
      env = null
    } else {
      Fiber.abort("environment vars must be passed as a Map")
    }
    return Scheduler.await_ { exec_(cmd, args, cwd, env, Fiber.current) }
  }

  static chdir(dir) {
    Ensure.string(dir, "directory")
    chdir_(dir)
  }

  foreign static exec_(cmd, args, cwd, env, fiber)
  foreign static allArguments
  foreign static cwd
  foreign static chdir_(dir)
  foreign static pid
  foreign static ppid
  foreign static version
  foreign static exit_(code)
}
