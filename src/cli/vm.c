#include <stdio.h>
#include <string.h>

#include "io.h"
#include "modules.h"
#include "path.h"
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

// TODO: This isn't currently used, but probably will be when package imports
// are supported. If not then, then delete this.
char* rootDirectory = NULL;
Path* wrenModulesDirectory = NULL;

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

static bool isDirectory(Path* path)
{
  uv_fs_t request;
  uv_fs_stat(loop, &request, path->chars, NULL);
  // TODO: Check request.result value?
  
  bool result = request.result == 0 && 
      (request.statbuf.st_mode & S_IFDIR);
  
  uv_fs_req_cleanup(&request);
  return result;
}

static Path* realPath(Path* path)
{
  uv_fs_t request;
  // fprintf("%s", path->chars);
  uv_fs_realpath(loop, &request, path->chars, NULL);
  
  // fprintf("%s", request.ptr);
  Path* result = pathNew((char*)request.ptr);
  
  uv_fs_req_cleanup(&request);
  return result;
}

// Starting at [rootDirectory], walks up containing directories looking for a
// nearby "wren_modules" directory. If found, stores it in
// [wrenModulesDirectory].
//
// If [wrenModulesDirectory] has already been found, does nothing.
static void findModulesDirectory()
{
  if (wrenModulesDirectory != NULL) {
    // fprintf(stderr,"already found\n");
    return;
  }

  // fprintf(stderr, "findModulesDirectory\n");
  
  Path* searchDirectory = pathNew(rootDirectory);
  // fprintf(stderr, "- %s\n", searchDirectory->chars);
  Path* lastPath = realPath(searchDirectory);

  // fprintf(stderr, "rootdir %s\n", rootDirectory);
  // fprintf(stderr, "search %s\n", searchDirectory->chars);

  // Keep walking up directories as long as we find them.
  for (;;)
  {
    Path* modulesDirectory = pathNew(searchDirectory->chars);
    pathJoin(modulesDirectory, "wren_modules");
    
    // fprintf(stderr, "consider %s\n", modulesDirectory->chars);
    if (isDirectory(modulesDirectory))
    {
      pathNormalize(modulesDirectory);
      wrenModulesDirectory = modulesDirectory;
      break;
    }
    
    pathFree(modulesDirectory);
    
    // Walk up directories until we hit the root. We can tell that because
    // adding ".." yields the same real path.
    pathJoin(searchDirectory, "..");
    Path* thisPath = realPath(searchDirectory);
    if (strcmp(lastPath->chars, thisPath->chars) == 0)
    {
      pathFree(thisPath);
      break;
    }
    
    pathFree(lastPath);
    lastPath = thisPath;
  }
  
  pathFree(lastPath);
  pathFree(searchDirectory);
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

  // fprintf(stderr, "loadModule: %s\n", module);

  Path* filePath;
  if (pathType(module) == PATH_TYPE_SIMPLE)
  {
    // fprintf(stderr, "simple path type\n");
    // If there is no "wren_modules" directory, then the only logical imports
    // we can handle are built-in ones. Let the VM try to handle it.
    findModulesDirectory();
    if (wrenModulesDirectory == NULL) return loadBuiltInModule(module);
    
    // TODO: Should we explicitly check for the existence of the module's base
    // directory inside "wren_modules" here?
    
    // Look up the module in "wren_modules".
    filePath = pathNew(wrenModulesDirectory->chars);
    pathJoin(filePath, module);
    
    // If the module is a single bare name, treat it as a module with the same
    // name inside the package. So "foo" means "foo/foo".
    if (strchr(module, '/') == NULL) pathJoin(filePath, module);
  }
  else
  {
    // The module path is already a file path.
    filePath = pathNew(module);
  }
  
  // Add a ".wren" file extension.
  pathAppendString(filePath, ".wren");

  result.onComplete = loadModuleComplete;
  result.source = readFile(filePath->chars);
  pathFree(filePath);
  
  // If we didn't find it, it may be a module built into the CLI or VM, so keep
  // going.
  if (result.source != NULL) return result;

  // Otherwise, see if it's a built-in module.
  return loadBuiltInModule(module);
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

static void freeVM()
{
  ioShutdown();
  schedulerShutdown();
  
  uv_loop_close(loop);
  free(loop);
  
  wrenFreeVM(vm);

  uv_tty_reset_mode();
  
  if (wrenModulesDirectory != NULL) pathFree(wrenModulesDirectory);
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
