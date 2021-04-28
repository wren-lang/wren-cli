#include <stdlib.h>
#include <string.h>

#include "modules.h"

#include "io.wren.inc"
#include "os.wren.inc"
#include "repl.wren.inc"
#include "scheduler.wren.inc"
#include "timer.wren.inc"


// The maximum number of foreign methods a single class defines. Ideally, we
// would use variable-length arrays for each class in the table below, but
// C++98 doesn't have any easy syntax for nested global static data, so we
// just use worst-case fixed-size arrays instead.
//
// If you add a new method to the longest class below, make sure to bump this.
// Note that it also includes an extra slot for the sentinel value indicating
// the end of the list.
#define MAX_METHODS_PER_CLASS 14

// The maximum number of foreign classes a single built-in module defines.
//
// If you add a new class to the largest module below, make sure to bump this.
// Note that it also includes an extra slot for the sentinel value indicating
// the end of the list.
#define MAX_CLASSES_PER_MODULE 6

// Describes one foreign method in a class.
typedef struct
{
  bool isStatic;
  const char* signature;
  WrenForeignMethodFn method;
} MethodRegistry;

// Describes one class in a built-in module.
typedef struct
{
  const char* name;

  MethodRegistry methods[MAX_METHODS_PER_CLASS];
} ClassRegistry;

// Describes one built-in module.
typedef struct
{
  // The name of the module.
  const char* name;

  // Pointer to the string containing the source code of the module. We use a
  // pointer here because the string variable itself is not a constant
  // expression so can't be used in the initializer below.
  const char **source;

  ClassRegistry classes[MAX_CLASSES_PER_MODULE];
} ModuleRegistry;

#define METHOD(signature, fn)        extern void fn (WrenVM* vm);;
#define STATIC_METHOD(signature, fn) extern void fn (WrenVM* vm);;
#define FINALIZER(fn)                extern void fn (WrenVM* vm);;
#define SENTINEL_METHOD 
#define SENTINEL_CLASS 
#define MODULE(name) 
#define END_MODULE 
#define CLASS(name) 
#define END_CLASS 

// MODULES, CLASSES, METHODS
//
// all modules as well as any foreign classes or methods must be included in
// this list to connect them to their counterpart C functions
//
// This macro is used to construct both the `ModuleRegistry` as well as the full
// list of externs so that they do not need to be maintained by hand.
#define REGISTRY MODULE(io) \
    CLASS(Directory) \
      STATIC_METHOD("list_(_,_)", directoryList) \
    END_CLASS \
    CLASS(File) \
      STATIC_METHOD("<allocate>", fileAllocate) \
      FINALIZER(fileFinalize) \
      STATIC_METHOD("delete_(_,_)", fileDelete) \
      STATIC_METHOD("open_(_,_,_)", fileOpen) \
      STATIC_METHOD("realPath_(_,_)", fileRealPath) \
      STATIC_METHOD("sizePath_(_,_)", fileSizePath) \
      METHOD("close_(_)", fileClose) \
      METHOD("descriptor", fileDescriptor) \
      METHOD("readBytes_(_,_,_)", fileReadBytes) \
      METHOD("size_(_)", fileSize) \
      METHOD("stat_(_)", fileStat) \
      METHOD("writeBytes_(_,_,_)", fileWriteBytes) \
    END_CLASS \
    CLASS(Stat) \
      STATIC_METHOD("path_(_,_)", statPath) \
      METHOD("blockCount", statBlockCount) \
      METHOD("blockSize", statBlockSize) \
      METHOD("device", statDevice) \
      METHOD("group", statGroup) \
      METHOD("inode", statInode) \
      METHOD("linkCount", statLinkCount) \
      METHOD("mode", statMode) \
      METHOD("size", statSize) \
      METHOD("specialDevice", statSpecialDevice) \
      METHOD("user", statUser) \
      METHOD("isDirectory", statIsDirectory) \
      METHOD("isFile", statIsFile) \
    END_CLASS \
    CLASS(Stdin) \
      STATIC_METHOD("isRaw", stdinIsRaw) \
      STATIC_METHOD("isRaw=(_)", stdinIsRawSet) \
      STATIC_METHOD("isTerminal", stdinIsTerminal) \
      STATIC_METHOD("readStart_()", stdinReadStart) \
      STATIC_METHOD("readStop_()", stdinReadStop) \
    END_CLASS \
    CLASS(Stdout) \
      STATIC_METHOD("flush()", stdoutFlush) \
    END_CLASS \
  END_MODULE \
  MODULE(os) \
    CLASS(Platform) \
      STATIC_METHOD("isPosix", platformIsPosix) \
      STATIC_METHOD("name", platformName) \
    END_CLASS \
    CLASS(Process) \
      STATIC_METHOD("allArguments", processAllArguments) \
      STATIC_METHOD("version", processVersion) \
      STATIC_METHOD("cwd", processCwd) \
    END_CLASS \
  END_MODULE \
  MODULE(repl) \
  END_MODULE \
  MODULE(scheduler) \
    CLASS(Scheduler) \
      STATIC_METHOD("captureMethods_()", schedulerCaptureMethods) \
    END_CLASS \
  END_MODULE \
  MODULE(timer) \
    CLASS(Timer) \
      STATIC_METHOD("startTimer_(_,_)", timerStartTimer) \
    END_CLASS \
  END_MODULE

// this first use of REGISTRY builds out the list of externs
// extern void directoryList(WrenVM* vm);
// extern void fileAllocate(WrenVM* vm);
// ...
REGISTRY

#undef SENTINEL_METHOD
#undef SENTINEL_CLASS
#undef MODULE
#undef END_MODULE
#undef CLASS
#undef END_CLASS
#undef METHOD
#undef STATIC_METHOD
#undef FINALIZER

// To locate foreign classes and modules, we build a big directory for them in
// static data. The nested collection initializer syntax gets pretty noisy, so
// define a couple of macros to make it easier.
#define SENTINEL_METHOD { false, NULL, NULL }
#define SENTINEL_CLASS { NULL, { SENTINEL_METHOD } }
#define END_REGISTRY 

#define MODULE(name) { #name, &name##ModuleSource, {
#define END_MODULE SENTINEL_CLASS } },

#define CLASS(name) { #name, {
#define END_CLASS SENTINEL_METHOD } },

#define METHOD(signature, fn) { false, signature, fn },
#define STATIC_METHOD(signature, fn) { true, signature, fn },
#define FINALIZER(fn) { true, "<finalize>", (WrenForeignMethodFn)fn },

// The array of built-in modules.
static ModuleRegistry modules[] =
{
  REGISTRY
  END_REGISTRY
};

#undef SENTINEL_METHOD
#undef SENTINEL_CLASS
#undef SENTINEL_MODULE
#undef MODULE
#undef END_MODULE
#undef CLASS
#undef END_CLASS
#undef METHOD
#undef STATIC_METHOD
#undef FINALIZER

// Looks for a built-in module with [name].
//
// Returns the BuildInModule for it or NULL if not found.
static ModuleRegistry* findModule(const char* name)
{
  for (int i = 0; modules[i].name != NULL; i++)
  {
    if (strcmp(name, modules[i].name) == 0) return &modules[i];
  }

  return NULL;
}

// Looks for a class with [name] in [module].
static ClassRegistry* findClass(ModuleRegistry* module, const char* name)
{
  for (int i = 0; module->classes[i].name != NULL; i++)
  {
    if (strcmp(name, module->classes[i].name) == 0) return &module->classes[i];
  }

  return NULL;
}

// Looks for a method with [signature] in [clas].
static WrenForeignMethodFn findMethod(ClassRegistry* clas,
                                      bool isStatic, const char* signature)
{
  for (int i = 0; clas->methods[i].signature != NULL; i++)
  {
    MethodRegistry* method = &clas->methods[i];
    if (isStatic == method->isStatic &&
        strcmp(signature, method->signature) == 0)
    {
      return method->method;
    }
  }

  return NULL;
}

void loadModuleComplete(WrenVM* vm, const char* name, struct WrenLoadModuleResult result)
{
  if (result.source == NULL) return;

  free((void*)result.source);
}

WrenLoadModuleResult loadBuiltInModule(const char* name)
{
  WrenLoadModuleResult result = {0};
  ModuleRegistry* module = findModule(name);
  if (module == NULL) return result;

  size_t length = strlen(*module->source);
  char* copy = (char*)malloc(length + 1);
  memcpy(copy, *module->source, length + 1);
   
  result.onComplete = loadModuleComplete;
  result.source = copy;
  return result;
}

WrenForeignMethodFn bindBuiltInForeignMethod(
    WrenVM* vm, const char* moduleName, const char* className, bool isStatic,
    const char* signature)
{
  // TODO: Assert instead of return NULL?
  ModuleRegistry* module = findModule(moduleName);
  if (module == NULL) return NULL;

  ClassRegistry* clas = findClass(module, className);
  if (clas == NULL) return NULL;

  return findMethod(clas, isStatic, signature);
}

WrenForeignClassMethods bindBuiltInForeignClass(
    WrenVM* vm, const char* moduleName, const char* className)
{
  WrenForeignClassMethods methods = { NULL, NULL };

  ModuleRegistry* module = findModule(moduleName);
  if (module == NULL) return methods;

  ClassRegistry* clas = findClass(module, className);
  if (clas == NULL) return methods;

  methods.allocate = findMethod(clas, true, "<allocate>");
  methods.finalize = (WrenFinalizerFn)findMethod(clas, true, "<finalize>");

  return methods;
}
