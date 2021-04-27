class Platform {
  foreign static isPosix
  foreign static name

  static isWindows { name == "Windows" }
}

class Process {
  // TODO: This will need to be smarter when wren supports CLI options.
  static arguments { allArguments.count >= 2 ? allArguments[2..-1] : [] }

  foreign static allArguments
  foreign static version
  foreign static cwd
}

class Time {
  foreign static time
}
