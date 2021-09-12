#include "vm.h"
#include "cli.h"

void cliSetRootDirectory(WrenVM* vm) {
  const char* dir = wrenGetSlotString(vm,1);
  // const char* boo = malloc(20);
  // boo = "test";
  // fprintf(stderr, "setting root dir: %s %d\n", dir, strlen(dir));
  char* copydir = malloc(strlen(dir)+1);
  strcpy(copydir, dir);
  // fprintf(stderr, "setting root dir: %s %d\n", copydir, strlen(copydir));
  // memcpy(copydir, dir, strlen(dir)+20);
  rootDirectory = copydir;
}