class Error {
  toString { message }
  raise() { Fiber.abort(this) }
}

class ArgumentError is Error {
  construct new(message) {
    _message = message
  }
  message { _message }
}

class Ensure {
  static argumentError(msg) { ArgumentError.new(msg).raise() }

  // simple type assertions
  static map(v, name) { type(v, Map, name ) }
  static list(v, name) { type(v, List, name ) }
  static num(v, name) { type(v, Num, name) }
  static string(v, name) { type(v, String, name) }
  static bool(v, name) { type(v, bool, name) }

  static int(v, name) {
    if (!(v is Num) || !v.isInteger) argumentError("Expected integer (Num) argument for '%(name)'")
  }

  static positiveNum(v, name) {
    if (!(v is Num) || v < 0) argumentError("Expected positive 'Num' argument for '%(name)'")
  }

  static positiveInt(v, name) {
    if (!(v is Num) || !v.isInteger || v < 0) argumentError("Expected positive integer (Num) argument for '%(name)'")
  }

  static fn(v, arity, name) {
    if (!(v is Fn) || v.arity != arity) argumentError("Expected 'Fn' with %(arity) parameters argument for '%(name)'")
  }

  static type(v, type, name) {
    if (!(v is type)) argumentError("Expected '%(type)' argument for '%(name)'")
  }

}
