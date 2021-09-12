#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "modules.h"

#include "io.wren.inc"
#include "os.wren.inc"
#include "repl.wren.inc"
#include "scheduler.wren.inc"
#include "runtime.wren.inc"
#include "timer.wren.inc"
#include "_wren.inc"
#include "essentials.h"


// To locate foreign classes and modules, we build a big directory for them in
// static data. The nested collection initializer syntax gets pretty noisy, so
// define a couple of macros to make it easier.
#define SENTINEL_METHOD { false, NULL, NULL }
#define SENTINEL_CLASS { NULL, { SENTINEL_METHOD } }
#define SENTINEL_MODULE {NULL, NULL, { SENTINEL_CLASS } }

#define NAMED_MODULE(name, identifier ) { #name, &identifier##ModuleSource, {
#define MODULE(name) { #name, &name##ModuleSource, {
#define END_MODULE SENTINEL_CLASS } },

#define CLASS(name) { #name, {
#define END_CLASS SENTINEL_METHOD } },

#define METHOD(signature, fn) { false, signature, fn },
#define STATIC_METHOD(signature, fn) { true, signature, fn },
#define ALLOCATE(fn) { true, "<allocate>", (WrenForeignMethodFn)fn },
#define FINALIZE(fn) { true, "<finalize>", (WrenForeignMethodFn)fn },


// The array of built-in modules.
/* START AUTOGEN: core.cli.modules */
extern void cliSetRootDirectory(WrenVM* vm);
extern void directoryCreate(WrenVM* vm);
extern void directoryDelete(WrenVM* vm);
extern void directoryList(WrenVM* vm);
extern void fileDescriptor(WrenVM* vm);
extern void fileDelete(WrenVM* vm);
extern void fileOpen(WrenVM* vm);
extern void fileRealPath(WrenVM* vm);
extern void fileSizePath(WrenVM* vm);
extern void fileClose(WrenVM* vm);
extern void fileReadBytes(WrenVM* vm);
extern void fileSize(WrenVM* vm);
extern void fileStat(WrenVM* vm);
extern void fileWriteBytes(WrenVM* vm);
extern void fileAllocate(WrenVM* vm);
extern void fileFinalize(void* data);
extern void statPath(WrenVM* vm);
extern void statBlockCount(WrenVM* vm);
extern void statBlockSize(WrenVM* vm);
extern void statDevice(WrenVM* vm);
extern void statGroup(WrenVM* vm);
extern void statInode(WrenVM* vm);
extern void statLinkCount(WrenVM* vm);
extern void statMode(WrenVM* vm);
extern void statSize(WrenVM* vm);
extern void statSpecialDevice(WrenVM* vm);
extern void statUser(WrenVM* vm);
extern void statIsFile(WrenVM* vm);
extern void statIsDirectory(WrenVM* vm);
extern void statAllocate(WrenVM* vm);
extern void statFinalize(void* data);
extern void stdinIsRaw(WrenVM* vm);
extern void stdinIsRawSet(WrenVM* vm);
extern void stdinIsTerminal(WrenVM* vm);
extern void stdinReadStart(WrenVM* vm);
extern void stdinReadStop(WrenVM* vm);
extern void stderrWrite(WrenVM* vm);
extern void stdoutFlush(WrenVM* vm);
extern void platformHomePath(WrenVM* vm);
extern void platformIsPosix(WrenVM* vm);
extern void platformName(WrenVM* vm);
extern void processExec(WrenVM* vm);
extern void processAllArguments(WrenVM* vm);
extern void processCwd(WrenVM* vm);
extern void processChdir(WrenVM* vm);
extern void processPid(WrenVM* vm);
extern void processPpid(WrenVM* vm);
extern void processVersion(WrenVM* vm);
extern void processExit(WrenVM* vm);
extern void schedulerCaptureMethods(WrenVM* vm);
extern void timerStartTimer(WrenVM* vm);

static ModuleRegistry coreCLImodules[] = {
MODULE(cli)
  CLASS(CLI)
    STATIC_METHOD("setRootDirectory_(_)", cliSetRootDirectory)
  END_CLASS
END_MODULE

MODULE(io)
  CLASS(Directory)
    STATIC_METHOD("create_(_,_)", directoryCreate)
    STATIC_METHOD("delete_(_,_)", directoryDelete)
    STATIC_METHOD("list_(_,_)", directoryList)
  END_CLASS
  CLASS(File)
    ALLOCATE(fileAllocate)
    FINALIZE(fileFinalize)
    METHOD("descriptor", fileDescriptor)
    STATIC_METHOD("delete_(_,_)", fileDelete)
    STATIC_METHOD("open_(_,_,_)", fileOpen)
    STATIC_METHOD("realPath_(_,_)", fileRealPath)
    STATIC_METHOD("sizePath_(_,_)", fileSizePath)
    METHOD("close_(_)", fileClose)
    METHOD("readBytes_(_,_,_)", fileReadBytes)
    METHOD("size_(_)", fileSize)
    METHOD("stat_(_)", fileStat)
    METHOD("writeBytes_(_,_,_)", fileWriteBytes)
  END_CLASS
  CLASS(Stat)
    ALLOCATE(statAllocate)
    FINALIZE(statFinalize)
    STATIC_METHOD("path_(_,_)", statPath)
    METHOD("blockCount", statBlockCount)
    METHOD("blockSize", statBlockSize)
    METHOD("device", statDevice)
    METHOD("group", statGroup)
    METHOD("inode", statInode)
    METHOD("linkCount", statLinkCount)
    METHOD("mode", statMode)
    METHOD("size", statSize)
    METHOD("specialDevice", statSpecialDevice)
    METHOD("user", statUser)
    METHOD("isFile", statIsFile)
    METHOD("isDirectory", statIsDirectory)
  END_CLASS
  CLASS(Stdin)
    STATIC_METHOD("isRaw", stdinIsRaw)
    STATIC_METHOD("isRaw=(_)", stdinIsRawSet)
    STATIC_METHOD("isTerminal", stdinIsTerminal)
    STATIC_METHOD("readStart_()", stdinReadStart)
    STATIC_METHOD("readStop_()", stdinReadStop)
  END_CLASS
  CLASS(Stderr)
    STATIC_METHOD("write(_)", stderrWrite)
  END_CLASS
  CLASS(Stdout)
    STATIC_METHOD("flush()", stdoutFlush)
  END_CLASS
END_MODULE

MODULE(os)
  CLASS(Platform)
    STATIC_METHOD("homePath", platformHomePath)
    STATIC_METHOD("isPosix", platformIsPosix)
    STATIC_METHOD("name", platformName)
  END_CLASS
  CLASS(Process)
    STATIC_METHOD("exec_(_,_,_,_,_)", processExec)
    STATIC_METHOD("allArguments", processAllArguments)
    STATIC_METHOD("cwd", processCwd)
    STATIC_METHOD("chdir_(_)", processChdir)
    STATIC_METHOD("pid", processPid)
    STATIC_METHOD("ppid", processPpid)
    STATIC_METHOD("version", processVersion)
    STATIC_METHOD("exit_(_)", processExit)
  END_CLASS
END_MODULE

MODULE(repl)
END_MODULE

MODULE(runtime)
END_MODULE

MODULE(scheduler)
  CLASS(Scheduler)
    STATIC_METHOD("captureMethods_()", schedulerCaptureMethods)
  END_CLASS
END_MODULE

MODULE(timer)
  CLASS(Timer)
    STATIC_METHOD("startTimer_(_,_)", timerStartTimer)
  END_CLASS
END_MODULE
SENTINEL_MODULE
};
/* END AUTOGEN: core.cli.modules */

static ModuleRegistry additionalRegistry[] =
{
  MODULE(booger)
  END_MODULE
  NAMED_MODULE(wren-package, wren_package)
  END_MODULE

  SENTINEL_MODULE
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

static LibraryRegistry libraries[MAX_LIBRARIES] = {
  { "core", (ModuleRegistry (*)[MAX_MODULES_PER_LIBRARY])&coreCLImodules},
  { "addl_modules", (ModuleRegistry (*)[MAX_MODULES_PER_LIBRARY])&additionalRegistry},
  { "essential", (ModuleRegistry (*)[MAX_MODULES_PER_LIBRARY])&essentialRegistry},
  { NULL, NULL }
};

void registerLibrary(const char* name, ModuleRegistry* registry) {
  int j = 0;
  while(libraries[j].name != NULL) {
    j += 1;
  }
  if (j>MAX_LIBRARIES) {
    fprintf(stderr, "Too many libraries, sorry.");
    return;
  }
  libraries[j].name = name;
  libraries[j].modules = (ModuleRegistry (*)[MAX_MODULES_PER_LIBRARY])registry;
}

// Looks for a built-in module with [name].
//
// Returns the BuildInModule for it or NULL if not found.
static ModuleRegistry* findModule(const char* name)
{
  for (int j = 0; libraries[j].name != NULL; j++) {
    ModuleRegistry *modules = &(*libraries[j].modules)[0];
    for (int i = 0; modules[i].name != NULL; i++) {
      if (strcmp(name, modules[i].name) == 0) return &modules[i];
    }
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
