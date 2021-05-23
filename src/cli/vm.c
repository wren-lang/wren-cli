#include <stdio.h>
#include <string.h>

#include "io.h"
#include "modules.h"
#include "scheduler.h"
#include "stat.h"
#include "vm.h"
#include "resolver.h"

// The single VM instance that the CLI uses.
static WrenVM* vm;

static WrenBindForeignMethodFn bindMethodFn = NULL;
static WrenBindForeignClassFn bindClassFn = NULL;
static WrenForeignMethodFn afterLoadFn = NULL;

static uv_loop_t* loop;

// the directory of the original script - used as an offset when searching
// for wren_modules, etc.
char* rootDirectory = NULL;

// The exit code to use unless some other error overrides it.
int defaultExitCode = 0;

// Reads the contents of the file at [path] and returns it as a heap allocated
// string.
//
// Returns `NULL` if the path could not be found. Exits if it was found but
// could not be read.
static char* readFile(const char* path)
{
  FILE* file = fopen(path, "rb");
  if (file == NULL) return NULL;
  
  // Find out how big the file is.
  fseek(file, 0L, SEEK_END);
  size_t fileSize = ftell(file);
  rewind(file);
  
  // Allocate a buffer for it.
  char* buffer = (char*)malloc(fileSize + 1);
  if (buffer == NULL)
  {
    fprintf(stderr, "Could not read file \"%s\".\n", path);
    exit(74);
  }
  
  // Read the entire file.
  size_t bytesRead = fread(buffer, 1, fileSize, file);
  if (bytesRead < fileSize)
  {
    fprintf(stderr, "Could not read file \"%s\".\n", path);
    exit(74);
  }
  
  // Terminate the string.
  buffer[bytesRead] = '\0';
  
  fclose(file);
  return buffer;
}

// Applies the CLI's import resolution policy. The rules are:
//
// * If [module] starts with "./" or "../", it is a relative import, relative
//   to [importer]. The resolved path is [name] concatenated onto the directory
//   containing [importer] and then normalized.
//
//   For example, importing "./a/./b/../c" from "./d/e/f" gives you "./d/e/a/c".
static const char* resolveModule(WrenVM* vm, const char* importer,
                                 const char* module)
{
  return wrenResolveModule(importer, module);
}

// Attempts to read the source for [module] relative to the current root
// directory.
//
// Returns it if found, or NULL if the module could not be found. Exits if the
// module was found but could not be read.
static WrenLoadModuleResult loadModule(WrenVM* vm, const char* module)
{
  WrenLoadModuleResult result = {0};
  char *moduleLoc = wrenLoadModule(module);

  if (moduleLoc[0] == ':') {
    // fprintf(stderr, "%s\n", moduleLoc+1);
    result = loadBuiltInModule(moduleLoc+1);
  } else {
    result.onComplete = loadModuleComplete;
    // fprintf(stderr, "found: %s\n", moduleLoc);
    result.source = readFile(moduleLoc);
    // if (result.source != NULL) return result;
  }
  free(moduleLoc);
  return result;
}

// Binds foreign methods declared in either built in modules, or the injected
// API test modules.
static WrenForeignMethodFn bindForeignMethod(WrenVM* vm, const char* module,
    const char* className, bool isStatic, const char* signature)
{
  WrenForeignMethodFn method = bindBuiltInForeignMethod(vm, module, className,
                                                        isStatic, signature);
  if (method != NULL) return method;
  
  if (bindMethodFn != NULL)
  {
    return bindMethodFn(vm, module, className, isStatic, signature);
  }

  return NULL;
}

// Binds foreign classes declared in either built in modules, or the injected
// API test modules.
static WrenForeignClassMethods bindForeignClass(
    WrenVM* vm, const char* module, const char* className)
{
  WrenForeignClassMethods methods = bindBuiltInForeignClass(vm, module,
                                                            className);
  if (methods.allocate != NULL) return methods;

  if (bindClassFn != NULL)
  {
    return bindClassFn(vm, module, className);
  }

  return methods;
}

static void write(WrenVM* vm, const char* text)
{
  printf("%s", text);
}

void reportError(WrenVM* vm, WrenErrorType type,
                        const char* module, int line, const char* message)
{
  switch (type)
  {
    case WREN_ERROR_COMPILE:
      fprintf(stderr, "[%s line %d] %s\n", module, line, message);
      break;
      
    case WREN_ERROR_RUNTIME:
      fprintf(stderr, "%s\n", message);
      break;
      
    case WREN_ERROR_STACK_TRACE:
      fprintf(stderr, "[%s line %d] in %s\n", module, line, message);
      break;
  }
}

static void initVM()
{
  WrenConfiguration config;
  wrenInitConfiguration(&config);

  config.bindForeignMethodFn = bindForeignMethod;
  config.bindForeignClassFn = bindForeignClass;
  config.resolveModuleFn = resolveModule;
  config.loadModuleFn = loadModule;
  config.writeFn = write;
  config.errorFn = reportError;

  // Since we're running in a standalone process, be generous with memory.
  config.initialHeapSize = 1024 * 1024 * 100;
  vm = wrenNewVM(&config);

  // Initialize the event loop.
  loop = (uv_loop_t*)malloc(sizeof(uv_loop_t));
  uv_loop_init(loop);
}

void on_uvClose(uv_handle_t* handle)
{
    if (handle != NULL)
    {
        free(handle);
    }
}

void on_uvWalkForShutdown(uv_handle_t* handle, void* arg)
{
   if (!uv_is_closing(handle))
    uv_close(handle, on_uvClose);
}

static void uvShutdown() {
  uv_loop_t *loop = getLoop();
  int result = uv_loop_close(loop);
  if (result != UV_EBUSY) return;

  // walk open handles and shut them down    
  uv_walk(loop, on_uvWalkForShutdown, NULL);
  uv_run(loop, UV_RUN_ONCE);
  result = uv_loop_close(loop);
  if (result != 0) {
    fprintf(stderr, "could not close UV event loop completely");
  }
}

static void freeVM()
{
  ioShutdown();
  schedulerShutdown();
  uvShutdown();
  free(loop);
  
  wrenFreeVM(vm);

  uv_tty_reset_mode();
}

WrenInterpretResult runCLI()
{
  initResolverVM();

  // This cast is safe since we don't try to free the string later.
  rootDirectory = (char*)".";
  initVM();

  WrenInterpretResult result = wrenInterpret(vm, "<cli>", "import \"cli\"\n");
  
  if (result == WREN_RESULT_SUCCESS)
  {
    uv_run(loop, UV_RUN_DEFAULT);
  }

  freeVM();
  
  return result;
}

WrenVM* getVM()
{
  return vm;
}

uv_loop_t* getLoop()
{
  return loop;
}

int getExitCode()
{
  return defaultExitCode;
}

void setExitCode(int exitCode)
{
  defaultExitCode = exitCode;
}

void setTestCallbacks(WrenBindForeignMethodFn bindMethod,
                      WrenBindForeignClassFn bindClass,
                      WrenForeignMethodFn afterLoad)
{
  bindMethodFn = bindMethod;
  bindClassFn = bindClass;
  afterLoadFn = afterLoad;
}
