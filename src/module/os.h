#ifndef process_h
#define process_h

#include "uv.h"
#include "wren.h"

#define WREN_PATH_MAX 4096
#define PROCESS_MAX_EXEC_ARGUMENTS 20

typedef struct {
  WrenHandle* fiber;
  uv_process_options_t options;
} processData;

// Stores the command line arguments passed to the CLI.
void osSetArguments(int argc, const char* argv[]);

#endif
