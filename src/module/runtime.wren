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
  static VERSION { "0.2.90" }
  static details {
    return {
      "name": Runtime.NAME,
      "wrenVersion": Runtime.WREN_VERSION,
      "version": Runtime.VERSION,
      "capabilities": [
        Capability.new("essentials"),
        Capability.new("mirror")
      ]
    }
  }
}

