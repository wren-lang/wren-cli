#include <stdio.h>
#include <string.h>

#include "os.h"
#include "vm.h"
#include "path.h"
#include "wren.h"

int main(int argc, const char* argv[]) {
  Path* p = pathNew(argv[0]);
  pathBaseName(p);
  char* cli  = p->chars;

  if (argc == 2 && (strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0))
  {
    printf("Usage: %s [options] [ file.wren ] [arguments...] \n", cli);
    printf("\n");
    printf("Options:\n");
    printf("  -h, --help          Show command line usage\n");
    printf("  -v, --version       Show version\n");
    return 0;
  }

  if (argc == 2 && (strcmp(argv[1], "--version") == 0 || strcmp(argv[1], "-v") == 0))
  {
    printf("%s %s\n", cli, WREN_VERSION_STRING);
    return 0;
  }

  osSetArguments(argc, argv);

  WrenInterpretResult result;
  if (argc == 1)
  {
    result = runRepl();
  }
  else
  {
    result = runFile(argv[1]);
  }

  // Exit with an error code if the script failed.
  if (result == WREN_RESULT_COMPILE_ERROR) return 65; // EX_DATAERR.
  if (result == WREN_RESULT_RUNTIME_ERROR) return 70; // EX_SOFTWARE.

  return getExitCode();
}
