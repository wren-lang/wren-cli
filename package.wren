import "wren-package/package" for WrenPackage, Dependency
import "os" for Process

class Package is WrenPackage {
  construct new() {}
  name { "wren-console" }
  dependencies {
    return [
      Dependency.new("wren-testie", "0.1.1", "https://github.com/joshgoebel/wren-testie.git"),
      Dependency.new("wren-assert", "HEAD", "https://github.com/RobLoach/wren-assert.git")
    ]
  }
}

Package.new().default()
