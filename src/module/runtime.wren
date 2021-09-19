class Capability {
  construct new(name) {
    _name = name
    _version = 0
  }
  ==(x) { x == _name }
  toString { _name }
}

class Runtime {
  static NAME { "wren-console" }
  static WREN_VERSION { "0.4.0" }
  static VERSION { "0.2.91" }
  // allows simple numeric comparison of semantic version strings
  // by turning them into large integers
  static versionToNumber_(v) {
    var segments = v.split(".").map { |x| Num.fromString(x) }.toList
    return segments[0] * 1000000 + segments[1] * 10000 + segments[2] * 100
  }
  // takes a semantic version string, ex "3.0.0" and aborts if the currently running
  // version of wren-console is less than the version specified
  //
  // If we running Wren Console 0.3:
  //
  //   Runtime.assertVersion("1.0") // aborts with error about version mismatch
  //   Runtime.assertVersion("0.1") // ok
  //   Runtime.assertVersion("0.3") // ok
  static assertVersion(desiredMinimalVersion) {
    if (versionToNumber_(Runtime.VERSION) < versionToNumber_(desiredMinimalVersion)) {
      Fiber.abort("wren-console version %(desiredMinimalVersion) or higher required.")
    }
  }
  static details {
    return {
      "name": Runtime.NAME,
      "wrenVersion": Runtime.WREN_VERSION,
      "version": Runtime.VERSION,
      "capabilities": [
        Capability.new("essentials"),
        Capability.new("json"),
        Capability.new("mirror")
      ]
    }
  }
}

