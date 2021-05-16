#ifndef vm_h
#define vm_h

#include "uv.h"
#include "wren.h"
#include "path.h"

// Executes the Wren script at [path] in a new VM.
WrenInterpretResult runFile(const char* path);

// Runs the Wren interactive REPL.
WrenInterpretResult runRepl();

// run the wren CLI
WrenInterpretResult runCLI();

char* rootDirectory;
Path* wrenModulesDirectory;

// Gets the currently running VM.
WrenVM* getVM();

// Gets the event loop the VM is using.
uv_loop_t* getLoop();

// error reporting
void reportError(WrenVM* vm, WrenErrorType type,
                        const char* module, int line, const char* message);

// Get the exit code the CLI should exit with when done.
int getExitCode();

// Set the exit code the CLI should exit with when done.
void setExitCode(int exitCode);

// Adds additional callbacks to use when binding foreign members from Wren.
//
// Used by the API test executable to let it wire up its own foreign functions.
// This must be called before calling [createVM()].
void setTestCallbacks(WrenBindForeignMethodFn bindMethod,
                      WrenBindForeignClassFn bindClass,
                      void (*afterLoad)(WrenVM* vm));

#endif
