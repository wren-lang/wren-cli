### Additional Modules

The modules added here must be pure-Wren, with a single file per module.  They
will be compiled into the resulting binary and accessible along with all other
system modules.

After added a module here you'll need to:

- Run `util/cli_to_c_string.py` to compile the Wren code into C strings
- Update the `additionalRegistry` in `modules.c` (line ~176) to list your module
- Compile

Only the module itself need to be named (not any methods, etc), for example to
add a `booger` module your registry would look something like:

```cpp
static ModuleRegistry additionalRegistry[] =
{
  MODULE(booger)
  END_MODULE
};
```

Then in your Wren projects:

```js
import "booger" for Booger
```