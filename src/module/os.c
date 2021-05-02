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

  free((void*)data);

  schedulerResume(fiber, true);
  wrenSetSlotDouble(getVM(), 2, (double)exit_status);
  schedulerFinishResume();
}

void processExec(WrenVM* vm) 
{
  ProcessData* data = (ProcessData*)malloc(sizeof(ProcessData));
  memset(data, 0, sizeof(ProcessData));

  //:todo: add env + cwd + flags args

  char* cmd = cli_strdup(wrenGetSlotString(vm, 1));

  data->options.file = cmd;
  data->options.exit_cb = processOnExit;
  data->fiber = wrenGetSlotHandle(vm, 3);

  int argCount = wrenGetListCount(vm, 2);
  int argsSize = sizeof(char*) * (argCount + 2);
    
  // First argument is the cmd, last+1 is NULL
  data->options.args = (char**)malloc(argsSize);
  data->options.args[0] = cmd;
  data->options.args[argCount + 1] = NULL;

  wrenEnsureSlots(vm, 3);
  for (int i = 0; i < argCount; i++) 
  {
    wrenGetListElement(vm, 2, i, 3);
    //:todo: ensure this is a string, and report an error if not
    char* arg = cli_strdup(wrenGetSlotString(vm, 3));
    data->options.args[i + 1] = arg;
  }

  uv_process_t* child_req = (uv_process_t*)malloc(sizeof(uv_process_t));
  memset(child_req, 0, sizeof(uv_process_t));

  child_req->data = data;

  int r;
  if ((r = uv_spawn(getLoop(), child_req, &data->options))) 
  {
    fprintf(stderr, "Could not launch %s, reason: %s\n", cmd, uv_strerror(r));
    wrenSetSlotString(vm, 0, "Could not spawn process.");
    wrenAbortFiber(vm, 0);
  }
}
