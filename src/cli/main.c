#include <stdio.h>
#include <string.h>

#include "ketopt.h"
#include "os.h"
#include "vm.h"
#include "wren.h"

int main(int argc, const char* argv[])
{
  static char opts[] = "hv";
  static ko_longopt_t longopts[] = {
    { "help", ko_no_argument, 301 },
    { "version", ko_no_argument, 302 },
    { NULL, 0, 0 }
  };
  ketopt_t opt = KETOPT_INIT;

  int c;
  while ((c = ketopt(&opt, argc, (char**) argv, 1, opts, longopts)) >= 0)
  {
    if (c == 'h' || c == 301)
    {
      printf("usage: wren [file] [arguments...]\n");
      printf("\n");
      printf("optional arguments:\n");
      printf("  -h, --help     Show command line usage\n");
      printf("  -v, --version  Show version\n");
      return 0;
    }

    if (c == 'v' || c == 302)
    {
      printf("wren %s\n", WREN_VERSION_STRING);
      return 0;
    }

    if (c == '?' && opt.opt)
    {
      fprintf(stderr, "unknown option: -%c\n", opt.opt);
      return 64; // EX_USAGE.
    }

    if (c == '?')
    {
      fprintf(stderr, "unknown option: %s\n", argv[opt.ind - 1]);
      return 64; // EX_USAGE.
    }
  }

  osSetArguments(argc, argv);

  WrenInterpretResult result;
  if (opt.ind >= argc)
  {
    result = runRepl();
  }
  else
  {
    result = runFile(argv[opt.ind]);
  }

  // Exit with an error code if the script failed.
  if (result == WREN_RESULT_COMPILE_ERROR) return 65; // EX_DATAERR.
  if (result == WREN_RESULT_RUNTIME_ERROR) return 70; // EX_SOFTWARE.

  return getExitCode();
}
