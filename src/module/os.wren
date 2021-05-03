import "scheduler" for Scheduler

class Platform {
  foreign static homePath
  foreign static isPosix
  foreign static name

  static isWindows { name == "Windows" }
}

class Process {
  // TODO: This will need to be smarter when wren supports CLI options.
  static arguments { allArguments.count >= 2 ? allArguments[2..-1] : [] }

  static exec(cmd) {
    return exec(cmd, [], null, null)
  }

  static exec(cmd, args) {
    return exec(cmd, args, null, null)
  }

  static exec(cmd, args, cwd) { 
    return exec(cmd, args, cwd, null) 
  }
  
  static exec(cmd, args, cwd, envMap) { 
    var env = []
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

  foreign static exec_(cmd, args, cwd, env, fiber)
  foreign static allArguments
  foreign static cwd
  foreign static pid
  foreign static ppid
  foreign static version
}
