class Platform {
  foreign static homePath
  foreign static isPosix
  foreign static name

  static isWindows { name == "Windows" }
}

class Process {
  // TODO: This will need to be smarter when wren supports CLI options.
  static arguments { allArguments.count >= 2 ? allArguments[2..-1] : [] }

  static chdir(dir) {
    ensureString_(dir, "directory")
    chdir_(dir)
  }

  // TODO: Copied from `io`. Figure out good way to share this.
  static ensureString_(s, name) {
    if (!(s is String)) Fiber.abort("%(name) must be a string.")
  }

  foreign static allArguments
  foreign static cwd
  foreign static chdir_(dir)
  foreign static pid
  foreign static ppid
  foreign static version
}
