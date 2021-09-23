# Wren Console - `wrenc`

[![latest release](https://badgen.net/github/release/joshgoebel/wren-console/stable)](https://github.com/joshgoebel/wren-console/releases)
[![MIT license](https://badgen.net/badge/license/MIT/cyan)](https://github.com/joshgoebel/wren-console/blob/main/LICENSE)
[![wren version 0.4](https://badgen.net/badge/wren/0.4.0/?color=purple)](https://github.com/wren-lang/wren)
![build status](https://badgen.net/github/checks/joshgoebel/wren-console?label=build)
[![join discord](https://badgen.net/badge/icon/discord?icon=discord&label&color=pink)][discord]


The Wren Console project is a small and simple REPL and CLI tool for running Wren scripts. It is backed by [libuv](http://libuv.org/) to implement IO functionality. It is  based on the official [Wren CLI](https://github.com/wren-lang/wren-cli) project and very much a work in progress. 

The goals and priorities are slightly different than the Wren CLI project.

- To be written as much as possible in pure Wren, not C.  This greatly simplifies much, expands the list of potential contributors, as makes developing new features faster (for everyone who knows Wren).
- Provide the best learning environment for the forthcoming [Exercism](https://exercism.io) Wren track.  For starters this means providing full introspection of stack traces when a Fiber aborts - allowing test suites to show helpful debugging information, including source code snippets. (thanks to [@mhermier](https://github.com/mhermier))
- Serve as a development playground for good ideas that may or may not ever make it into Wren CLI proper. If much of what we do makes it into Wren CLI, great.  If we end up going different directions, that's ok too.

For now the idea is to try to maintain compatibility with whe Wren CLI modules themselves, so that [reference documentation](https://wren.io/cli/modules) may prove useful.

For more information about Wren, the language that Wren Console is embedding, see http://wren.io.

We welcome contributions.  Feel free to [open an issue][issues] to start a discussion or [join our Discord][discord]. You can also find me on the main Wren Discord as well.

[issues]: https://github.com/joshgoebel/wren-console
[discord]: https://discord.gg/6YjUdym5Ap


---

## FAQ

### Pure Wren? Why?

- It's higher level and therefore easier to read, write, and iterate than C.
- [It's more than fast enough.](https://wren.io/performance.html)
- **I've fallen a bit in love with Wren.** 
- *It's fun.* Is there any better reason?
- Many (including myself) don't know C nearly well enough to be proficient with major CLI contributions.

### Exercism?

Thousands of helpful mentors, hundreds of thousands of fellow students to learn alongside.  If you're wanting to learn a new language, improve your Wren, or just sharpen your skills on an entirely different language, [Exercism is the place to be](https://exercism.io/about).



---

## Usage Examples

Start up an interactive REPL session:

```sh
$ wrenc
```

Run a script from the console:

```sh
$ wrenc ./path_to_script.wren
```

Evaluate code directly:

```sh
$ wrenc -e 'System.print("Hello World!")'
```

Executable Wren scripts:

Use the typical "shebang" for executable wren scripts:
```sh
#!/usr/bin/env wrenc
import "io" for Stdin
System.print("Enter your name:")
var name = Stdin.readLine().trim()
System.print("Hello %(name.isEmpty ? "World" : name)!")
```
(Note: for Linux folk, this is documented in the
[`execve(2)` man page](https://manpage.me/index.cgi?apropos=0&q=execve&sektion=2&manpath=Debian+8.1.0&arch=default&format=html).)

Embed Wren code in a shell script:

This makes smart use of file descriptors and the Linux /dev file system to
read the code from a here-document while also keeping standard input
available for wren:

```sh
#!/bin/sh
wrenc /dev/fd/5 < input.txt 5<< 'EOF'
import "io" for Stdin
System.print(Stdin.readLine())
EOF
```

---

## Extended Library Support

Our hope is to extend the libraries available without breaking forwards compatibility - meaning that a script running successfully on Wren CLI should run as-is on Wren Console - but once you start using the newer library features your script may no longer run be backwards compatible with Wren CLI.

### `wren-package` module

Dirt simple package management/dependencies for Wren Console projects.

- `WrenPackage` class
- `Dependency` class  
- See [wren-package][wren-package] for usage details

### `io` module

- `Stderr.write(s)` - Write a string to srderr
- `Stderr.print(s)` - Write a string to stderr followed by a newline
- `File.dirname(path)` - Strip last component from file name
- `File.basename(path)` - Strip directory from filenames
- `File.basename(path, suffixes)` - Strip directory and suffix from filenames

### `os` module

- `Process.exec(command, [arguments, [workingDirectory, [environment]]])` - Run an external command and display it's output
- `Process.exit()` - Exit immediately with 0 status code
- `Process.exit(code)` - Exit immediately with the specified exit status code. (https://github.com/wren-lang/wren-cli/pull/74)
- `Process.chdir(dir)` - Change the working directory of the process

### `ensure` module

Argument validation...

- `Ensure.map(v,name)` - value must be `Map`, or abort with `ArgumentError`
- `Ensure.list(v,name)` - value must be `List`, or abort with `ArgumentError`
- `Ensure.num(v,name)` - value must be `Num`, or abort with `ArgumentError`
- `Ensure.string(v,name)` - value must be `String`, or abort with `ArgumentError`
- `Ensure.bool(v,name)` - value must be `bool`, or abort with `ArgumentError`
- `Ensure.int(v,name)` - value must be integer, or abort with `ArgumentError`
- `Ensure.positiveNum(v,name)` - value must be positive number, or abort with `ArgumentError`
- `Ensure.positiveInt(v,name)` - value must be positive integer, or abort with `ArgumentError`
- `Ensure.fn(v, arity, name)` - value must be function with arity, or abort with `ArgumentError`
- `Ensure.type(v, type, name)` - value must be of given type, or abort with `ArgumentError`

Example:

```js
static sleep(milliseconds) {
  Ensure.positiveNum(milliseconds, "milliseconds")
  // ...
}  
```

### `runtime` module

Retrieve details about the runtime environment.

- `Runtime.NAME` - The runtime name
- `Runtime.VERSION` - The runtime version number
- `Runtime.WREN_VERSION` - The Wren version the runtime is built against
- `Runtime.details` - retrieve additional details about the runtime environment
- `Runtime.capabilities` - list of supported capabilities
- `Runtime.hasCapability(name)` - query if specific capability is supported by runtime

### `mirror` module

Experimental. See https://github.com/wren-lang/wren/pull/1006.

- `Mirror.reflect(object)` - Reflect on an object
- `Mirror.reflect(class)` - Reflect on a class
- `Mirror.reflect(fiber)` - Reflect on a fiber, it's stacktrace, etc.

### `essentials` module

Wren Console includes the [Wren Essentials](https://github.com/joshgoebel/wren-essentials) library built right into the binary.

- `Time.now()` - number of milliseconds since Epoch
- `Time.highResolution()` - high resolution time counter (for benchmarking, etc.)
- `Strings.upcase(s)` - convert an ASCII string to uppercase
- `Strings.downcase(s)` - convert an ASCII string to lowercase
- `Strings.titlecase(s)` - convert an ASCII string to "Title Case"
- `Strings.capitalize(s)` - capitalize first letter of an ASCII string
- `Strings.globMatch(s, pattern)` - glob match capabilities ported from TCL

#### `json` module

- `JSON.encode(data, [options])` - encode data into JSON string
- `JSON.decode(json, [options])` - decode JSON string into data
- `JSON.stringify(data)` - alias of `encode`
- `JSON.parse(json)` - alias of `decode`

---

## Installing

If you're using [Homebrew](https://brew.sh) we have a tap for you. Otherwise you can check out our [binary releases](https://github.com/joshgoebel/wren-console/releases) or simply build from source.

**With Homebrew:**

```sh
brew tap exercism/wren
brew install wren-console
```

### Building from source

**Pre-requisites**

- Git clone the `wren-essentials` project ([link](https://github.com/joshgoebel/wren-essentials)) into `deps` (TODO: vendor?)

### Windows

The `projects/vs20xx` folders contain Visual Studio projects. 

### macOS

The `projects/xcode` folder contains an Xcode project. 

The `projects/make.mac` folder also contains a `make` project.   
From that folder, run `make`.

`cd projects/make.mac`   
`make`

### Linux

The `projects/make` folder contains a `make` project.   
From that folder, run `make`.

`cd projects/make`   
`make`

### FreeBSD

The `projects/make.bsd` folder contains a `make` project.   
From that folder, run `make`.

`cd projects/make.bsd`   
`gmake`

## Alternative build options

The projects are generated by premake, found inside `projects/premake`.   
You can use premake5 (alpha 14 was used) to generate other projects.   
Generate other system's projects via the premake `--os` flag,    
i.e if on linux, `premake vs2019 --os=windows` is valid.

---


[wren-package]: https://github.com/joshgoebel/wren-package
