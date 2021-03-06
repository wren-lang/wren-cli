class Platform {
  foreign static isPosix
  foreign static name

  static isWindows { name == "Windows" }
}

class Process {
  // TODO: This will need to be smarter when wren supports CLI options.
  static arguments { allArguments[2..-1] }

  foreign static allArguments
  foreign static version
  foreign static cwd
  static exec(command){
    if(!(command is String)) Fiber.abort("Command must be a string")
      runCommand_(command)
    }
  foreign static runCommand_(command)
}
