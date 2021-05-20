#include "resolver.h"
#include "uv.h"
#include "wren.h"
#include "vm.h"
#include "_wren.inc"
#include "modules.h"
#include <string.h>

WrenVM *resolver;

void fileLoadDynamicLibrary(WrenVM* vm) {
  const char* name = wrenGetSlotString(vm,1);
  const char* path = wrenGetSlotString(vm,2);
  // fprintf(stderr,"loading dylib %s at %s\n",name,path);

  uv_lib_t *lib = (uv_lib_t*) malloc(sizeof(uv_lib_t));
  // fprintf(stderr, "importing TIME OH BOY");
  int r = uv_dlopen(path, lib);
  if (r !=0) {
    fprintf(stderr, "error with lib %s dlopen of %s", name, path);
  }
  registryGiverFunc registryGiver;
  if (uv_dlsym(lib, "returnRegistry", (void **) &registryGiver)) {
      fprintf(stderr, "dlsym error: %s\n", uv_dlerror(lib));
  }
  ModuleRegistry* m = registryGiver();
  registerLibrary(name, m);
}

void fileExistsSync(WrenVM* vm) {
  uv_fs_t req;
  int r = uv_fs_stat(NULL,&req,wrenGetSlotString(vm,1),NULL);
  // fprintf(stderr,"fileExists, %s  %d\n", wrenGetSlotString(vm,1), r);
  wrenEnsureSlots(vm, 1);
  // non zero is error and means we don't have a file
  wrenSetSlotBool(vm, 0, r == 0);
}

void fileRealPathSync(WrenVM* vm)
{
  const char* path = wrenGetSlotString(vm, 1);

  uv_fs_t request;
  uv_fs_realpath(getLoop(), &request, path, NULL);
  
  // fprintf("%s", request.ptr);
  // Path* result = pathNew((char*)request.ptr);
  wrenSetSlotString(vm, 0, (const char*)request.ptr);
  
  uv_fs_req_cleanup(&request);
  // return result;
}

WrenHandle* resolveModuleFn;
WrenHandle* loadModuleFn;
WrenHandle* resolverClass;

void saveResolverHandles(WrenVM* vm) {
  wrenEnsureSlots(vm,1);
  wrenGetVariable(resolver, "<resolver>", "Resolver", 0);
  resolverClass = wrenGetSlotHandle(vm, 0);
  resolveModuleFn = wrenMakeCallHandle(resolver,"resolveModule(_,_,_)");
  loadModuleFn = wrenMakeCallHandle(resolver,"loadModule(_,_)");
}

static WrenForeignMethodFn bindResolverForeignMethod(WrenVM* vm, const char* module,
    const char* className, bool isStatic, const char* signature)
{
  if (strcmp(signature,"existsSync(_)")==0) {
    return fileExistsSync;
  }
  if (strcmp(signature,"realPathSync(_)")==0) {
    return fileRealPathSync;
  }
  if (strcmp(signature,"loadDynamicLibrary(_,_)")==0) {
    return fileLoadDynamicLibrary;
  }
  return NULL;
}

static void write(WrenVM* vm, const char* text)
{
  printf("%s", text);
}

char* wrenLoadModule(const char* module) {
  WrenVM *vm = resolver;
  wrenEnsureSlots(vm,2);
  wrenSetSlotHandle(vm,0, resolverClass);
  wrenSetSlotString(vm,1, module);
  wrenSetSlotString(vm,2, rootDirectory);
  wrenCall(resolver,loadModuleFn);
  const char *tmp = wrenGetSlotString(vm,0);
  char *result = malloc(strlen(tmp)+1);
  strcpy(result,tmp);
  return result;
}

char* wrenResolveModule(const char* importer, const char* module) {
  WrenVM *vm = resolver;
  wrenEnsureSlots(vm,4);
  wrenSetSlotHandle(vm,0, resolverClass);
  wrenSetSlotString(vm,1, importer);
  wrenSetSlotString(vm,2, module);
  wrenSetSlotString(vm,3, rootDirectory);
  wrenCall(resolver,resolveModuleFn);
  const char *tmp = wrenGetSlotString(vm,0);
  char *result = malloc(strlen(tmp)+1);
  strcpy(result,tmp);
  return result;
}

void initResolverVM()
{
  WrenConfiguration config;
  wrenInitConfiguration(&config);

  config.bindForeignMethodFn = bindResolverForeignMethod;
  // config.bindForeignClassFn = bindForeignClass;
  // config.resolveModuleFn = resolveModule;
  // config.loadModuleFn = readModule;
  config.writeFn = write;
  config.errorFn = reportError;

  // Since we're running in a standalone process, be generous with memory.
  config.initialHeapSize = 1024 * 1024 * 100;
  resolver = wrenNewVM(&config);

  // Initialize the event loop.
  WrenInterpretResult result = wrenInterpret(resolver, "<resolver>", resolverModuleSource);
  saveResolverHandles(resolver);
}
