#ifndef process_h
#define process_h

#include "limits.h"
#include "wren.h"

#ifdef PATH_MAX
# define WREN_PATH_MAX PATH_MAX
#else
# define WREN_PATH_MAX 4096
#endif

// Stores the command line arguments passed to the CLI.
void osSetArguments(int argc, const char* argv[]);

#endif
