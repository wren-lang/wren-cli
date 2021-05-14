#include <stdio.h>
#include <string.h>

#include "os.h"
#include "vm.h"
#include "wren.h"

int main(int argc, const char* argv[])
{
  osSetArguments(argc, argv);

  WrenInterpretResult result;
  result = runCLI();

  // Exit with an error code if the script failed. 
  if (result == WREN_RESULT_RUNTIME_ERROR) return 70; // EX_SOFTWARE.
  // TODO: 65 is impossible now and will need to be handled inside `cli.wren`
  if (result == WREN_RESULT_COMPILE_ERROR) return 65; // EX_DATAERR.

  return getExitCode();
}
