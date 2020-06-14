This contains the Wren source code. It is organized like so:

*   `cli`: the source code for the command line interface. This is a custom
    executable that embeds the VM in itself. Code here handles reading
    command-line, running the REPL, loading modules from disc, etc.

*   `module`: the source code for the built-in modules that come with the CLI.
    These modules are written in a mixture of C and Wren and generally use
    [libuv](http://libuv.org/) to implement their underlying functionality.
