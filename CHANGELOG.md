## 0.2.90 

- (enh) `wren_modules` are searched until a matching library is found
  - this means you can now use both `$HOME/wren_modules` (global modules) 
  - as well a local `./wren_modules` for individual projects
  - the "closest" match wins, allowing local to win out over global
  - this is technically a breaking change from `wren-cli` which stops at the first `wren_modules` it finds
- (fix) absolute script paths work on Windows now
- (fix) mode test
- (fix) cwd test on windows
- (fix) pid test on Windows
- (fix) memory allocation/slot allocation issues
- (fix) freeing stdinStream memory too early
- (enh) Add CI and build artifacts with Linux, Windows, and Mac

## 0.2.0

- (chore) Auto-build and test binary releases for Windows, Mac, Linux platforms on tagged versions
- (enh) Integrate `Mirror` functionality for stack trace introspection (via wren-essentials)
- (fix) Stdin.readByte now propery removes single bytes from buffer
- (enh) support scripts at absolute paths
- (enh) controlled crashes should not include CLI script in stack trace
- (enh) Add `Runtime` API for getting information about the runtime
- (enh) Add `Process.exit()` and `Process.exit(code)`
- (enh) Add `Stderr.write(_)` and `Stderr.print(_)`
- (fix) `Process.exit()` should actually work properly now
- (enh) Add `Process.exec(command, [arguments, [workingDirectory, [environment]]])`

## 0.1.0 

- includes Wren Core 0.4
- rewrite a good portion of CLI codebase in pure Wren code (as much as possible)
- module resolution and loading is now brokered by Wren code
- flush stdout before quitting https://github.com/wren-lang/wren-cli/pull/77
- add `-e` flag for code evaluation https://github.com/wren-lang/wren-cli/issues/11
- add `-h` and `-v` flags https://github.com/wren-lang/wren-cli/pull/88
- add `-` flag for read script from stdin https://github.com/wren-lang/wren-cli/issues/55#issuecomment-844474733
- add experimental native binary module/library loading support https://github.com/wren-lang/wren-cli/issues/52
  - see https://github.com/joshgoebel/wren-essentials for how to build a sample binary library 
  - `import "wren_essentials:essentials"` loads the library from `wren_modules/libwren_essentials.dylib` and then imports the `essentials` module from that library
- based on wren-cli codebase (9c6b6933722)