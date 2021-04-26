#ifndef modules_h
#define modules_h

// This wires up all of the foreign classes and methods defined by the built-in
// modules bundled with the CLI.

#include "wren.h"

// Returns the source for built-in module [name].
WrenLoadModuleResult loadBuiltInModule(const char* module);
void loadModuleComplete(WrenVM* vm, const char* name, struct WrenLoadModuleResult result);

// Looks up a foreign method in a built-in module.
//
// Returns `NULL` if [moduleName] is not a built-in module.
WrenForeignMethodFn bindBuiltInForeignMethod(
    WrenVM* vm, const char* moduleName, const char* className, bool isStatic,
    const char* signature);

// Binds foreign classes declared in a built-in modules.
WrenForeignClassMethods bindBuiltInForeignClass(
    WrenVM* vm, const char* moduleName, const char* className);

#endif
