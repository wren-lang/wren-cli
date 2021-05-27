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

  foreign static allArguments
  foreign static cwd
  foreign static pid
  foreign static ppid
  foreign static version
  foreign static exit_(code)
}
