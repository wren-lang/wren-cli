#include "os.h"
#include "uv.h"
#include "wren.h"
#include "vm.h"
#include "scheduler.h"
#include "cli_common.h"

#include <stdint.h>

#if __APPLE__
  #include "TargetConditionals.h"
#endif

int numArgs;
const char** args;

void osSetArguments(int argc, const char* argv[])
{
  numArgs = argc;
  args = argv;
}

void platformHomePath(WrenVM* vm)
{
  wrenEnsureSlots(vm, 1);

  char _buffer[WREN_PATH_MAX];
  char* buffer = _buffer;
  size_t length = sizeof(_buffer);
  int result = uv_os_homedir(buffer, &length);

  if (result == UV_ENOBUFS)
  {
    buffer = (char*)malloc(length);
    result = uv_os_homedir(buffer, &length);
  }

  if (result != 0)
  {
    wrenSetSlotString(vm, 0, "Cannot get the current user's home directory.");
    wrenAbortFiber(vm, 0);
    return;
  }

  wrenSetSlotString(vm, 0, buffer);

  if (buffer != _buffer) free(buffer);
}

void platformName(WrenVM* vm)
{
  wrenEnsureSlots(vm, 1);
  
  #ifdef _WIN32
    wrenSetSlotString(vm, 0, "Windows");
  #elif __APPLE__
    #if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
      wrenSetSlotString(vm, 0, "iOS");
    #elif TARGET_OS_MAC
      wrenSetSlotString(vm, 0, "OS X");
    #else
      wrenSetSlotString(vm, 0, "Unknown");
    #endif
  #elif __linux__
    wrenSetSlotString(vm, 0, "Linux");
  #elif __unix__
    wrenSetSlotString(vm, 0, "Unix");
  #elif defined(_POSIX_VERSION)
    wrenSetSlotString(vm, 0, "POSIX");
  #else
    wrenSetSlotString(vm, 0, "Unknown");
  #endif
}

void platformIsPosix(WrenVM* vm)
{
  wrenEnsureSlots(vm, 1);
  
  #ifdef _WIN32
    wrenSetSlotBool(vm, 0, false);
  #elif __APPLE__
    wrenSetSlotBool(vm, 0, true);
  #elif __linux__
    wrenSetSlotBool(vm, 0, true);
  #elif __unix__
    wrenSetSlotBool(vm, 0, true);
  #elif defined(_POSIX_VERSION)
    wrenSetSlotBool(vm, 0, true);
  #else
    wrenSetSlotString(vm, 0, false);
  #endif
}

void processAllArguments(WrenVM* vm)
{
  wrenEnsureSlots(vm, 2);
  wrenSetSlotNewList(vm, 0);

  for (int i = 0; i < numArgs; i++)
  {
    wrenSetSlotString(vm, 1, args[i]);
    wrenInsertInList(vm, 0, -1, 1);
  }
}

void processExit(WrenVM* vm) {
  int code = (int)wrenGetSlotDouble(vm, 1);
  setExitCode(code);
  uv_stop(getLoop());
}

// chdir_(dir)
void processChdir(WrenVM* vm)
{
  wrenEnsureSlots(vm, 1);
  const char* dir = wrenGetSlotString(vm, 1);
  if (uv_chdir(dir) != 0)
  {
    wrenSetSlotString(vm, 0, "Cannot change directory.");
    wrenAbortFiber(vm, 0);
    return;
  }
}

void processCwd(WrenVM* vm)
{
  wrenEnsureSlots(vm, 1);

  char buffer[WREN_PATH_MAX * 4];
  size_t length = sizeof(buffer);
  if (uv_cwd(buffer, &length) != 0)
  {
    wrenSetSlotString(vm, 0, "Cannot get current working directory.");
    wrenAbortFiber(vm, 0);
    return;
  }

  wrenSetSlotString(vm, 0, buffer);
}

void processPid(WrenVM* vm) {
  wrenEnsureSlots(vm, 1);
  wrenSetSlotDouble(vm, 0, uv_os_getpid());
}

void processPpid(WrenVM* vm) {
  wrenEnsureSlots(vm, 1);
  wrenSetSlotDouble(vm, 0, uv_os_getppid());
}

void processVersion(WrenVM* vm) {
  wrenEnsureSlots(vm, 1);
  wrenSetSlotString(vm, 0, WREN_VERSION_STRING);
}

// Called when the UV handle for a process is done, so we can free it
static void processOnClose(uv_handle_t* req) 
{
  free((void*)req);
}

// Called when a process is finished running
static void processOnExit(uv_process_t* req, int64_t exit_status, int term_signal) 
{
  ProcessData* data = (ProcessData*)req->data;
  WrenHandle* fiber = data->fiber;

  uv_close((uv_handle_t*)req, processOnClose);

  int index = 0;
  char* arg = data->options.args[index];
  while (arg != NULL)
  {
    free(arg);
    index += 1;
    arg = data->options.args[index];
  }

  index = 0;
  if (data->options.env) {
    char* env = data->options.env[index];
    while (env != NULL)
    {
      free(env);
      index += 1;
      env = data->options.env[index];
    }
  }

  free(data->options.stdio);
  free((void*)data);

  schedulerResume(fiber, true);
  wrenSetSlotDouble(getVM(), 2, (double)exit_status);
  schedulerFinishResume();
}

//        1     2    3    4     5
// exec_(cmd, args, cwd, env, fiber)
void processExec(WrenVM* vm) 
{
  ProcessData* data = (ProcessData*)malloc(sizeof(ProcessData));
  memset(data, 0, sizeof(ProcessData));

  //:todo: add env + cwd + flags args

  char* cmd = cli_strdup(wrenGetSlotString(vm, 1));

  if (wrenGetSlotType(vm, 3) != WREN_TYPE_NULL) {
    const char* cwd = wrenGetSlotString(vm, 3);
    data->options.cwd = cwd;
  }

  // input/output: for now we'll hookup STDOUT/STDERR as inherit/passthru so
  // we'll see output just like you would in a shell script, by default 
  data->options.stdio_count = 3;
  // TODO: make more flexible
  uv_stdio_container_t *child_stdio = malloc(sizeof(uv_stdio_container_t) * 3);
  memset(child_stdio, 0, sizeof(uv_stdio_container_t) * 3);
  child_stdio[0].flags = UV_IGNORE;
  child_stdio[1].flags = UV_INHERIT_FD;
  child_stdio[2].flags = UV_INHERIT_FD;
  child_stdio[1].data.fd = 1;
  child_stdio[2].data.fd = 2;
  data->options.stdio = child_stdio;

  data->options.file = cmd;
  data->options.exit_cb = processOnExit;
  data->fiber = wrenGetSlotHandle(vm, 5);

  wrenEnsureSlots(vm, 7);

  if (wrenGetSlotType(vm, 4) == WREN_TYPE_NULL) {
    // no environment specified
  } else if (wrenGetSlotType(vm, 4) == WREN_TYPE_LIST) {
    int envCount = wrenGetListCount(vm, 4);
    int envSize = sizeof(char*) * (envCount + 1);

    data->options.env = (char**)malloc(envSize);
    data->options.env[envCount] = NULL;

    for (int i = 0; i < envCount ; i++) 
    {
      wrenGetListElement(vm, 4, i, 6);
      if (wrenGetSlotType(vm, 6) != WREN_TYPE_STRING) {
        wrenSetSlotString(vm, 0, "arguments to env are supposed to be strings");
        wrenAbortFiber(vm, 0);        
      }
      char* envKeyPlusValue = cli_strdup(wrenGetSlotString(vm, 6));
      data->options.env[i] = envKeyPlusValue;
    }
  }

  int argCount = wrenGetListCount(vm, 2);
  int argsSize = sizeof(char*) * (argCount + 2);
    
  // First argument is the cmd, last+1 is NULL
  data->options.args = (char**)malloc(argsSize);
  data->options.args[0] = cmd;
  data->options.args[argCount + 1] = NULL;

  for (int i = 0; i < argCount; i++) 
  {
    wrenGetListElement(vm, 2, i, 3);
    if (wrenGetSlotType(vm, 3) != WREN_TYPE_STRING) {
      wrenSetSlotString(vm, 0, "arguments to args are supposed to be strings");
      wrenAbortFiber(vm, 0);        
    }
    char* arg = cli_strdup(wrenGetSlotString(vm, 3));
    data->options.args[i + 1] = arg;
  }

  uv_process_t* child_req = (uv_process_t*)malloc(sizeof(uv_process_t));
  memset(child_req, 0, sizeof(uv_process_t));

  child_req->data = data;

  int r;
  if ((r = uv_spawn(getLoop(), child_req, &data->options))) 
  {
    // should be stderr??? but no idea how to make tests work/pass with that
    fprintf(stdout, "Could not launch %s, reason: %s\n", cmd, uv_strerror(r));
    wrenSetSlotString(vm, 0, "Could not spawn process.");
    wrenReleaseHandle(vm, data->fiber);
    wrenAbortFiber(vm, 0);
  }
}
