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

  static exec(cmd, args) {
    exec_(cmd, args, Fiber.current)
    return Scheduler.runNextScheduled_()
  }

  foreign static exec_(cmd, args, fiber)
  foreign static allArguments
  foreign static cwd
  foreign static pid
  foreign static ppid
  foreign static version
}
