#include "os.h"
#include "uv.h"
#include "wren.h"
#include "vm.h"
#include "scheduler.h"
#include <inttypes.h>

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

void proccesOnExit(uv_process_t *req, int64_t exit_status, int term_signal) {
    uv_close((uv_handle_t*) req, NULL);
    schedulerResume(((processData*)req->data)->fiber, true);
    wrenSetSlotDouble(getVM(), 2, exit_status);
    schedulerFinishResume();

    free((processData*)(req->data));
    free(req);
}

void processExec(WrenVM* vm) {
    uv_process_t *child_req = malloc(sizeof(uv_process_t));
    processData* data = malloc(sizeof(processData));
    memset(data, 0, sizeof(processData));

    // 2 extra slots in args for:
    //  - the program to execute (head)
    //  - NULL terminator (tail)
    const char* args[PROCESS_MAX_EXEC_ARGUMENTS + 2];
    uv_loop_t *loop = getLoop();

    args[0] = wrenGetSlotString(vm,1);
    int argCount = wrenGetListCount(vm,2);
    WrenHandle *fiber = wrenGetSlotHandle(vm,3);

    // TODO: allocate args dynamically to remove this limitation?
    if (argCount > PROCESS_MAX_EXEC_ARGUMENTS) {
      wrenSetSlotString(vm, 0, "Too many process arguments.");
      wrenAbortFiber(vm, 0);
    }

    wrenEnsureSlots(vm,4);
    for (int i = 0; i < argCount; i++) {
      wrenGetListElement(vm, 2, i, 4);
      args[i+1] = wrenGetSlotString(vm,4);
    }
    args[argCount+1] = NULL;

    data->options.exit_cb = proccesOnExit;
    data->options.file = args[0];
    data->options.args = args;

    data->fiber = fiber;
    child_req->data = data;

    int r;
    if ((r = uv_spawn(loop, child_req, &data->options))) {
        fprintf(stderr, "could not launch %s, %s\n", args[0], uv_strerror(r));
        wrenSetSlotString(vm, 0, "Could not spawn process.");
        wrenAbortFiber(vm, 0);
    }
}
