#ifndef resolver_h
#define resolver_h

#include "wren.h"

WrenVM *resolver;
void initResolverVM();
char* wrenResolveModule(const char* importer, const char* module);
char* wrenLoadModule(const char* module);

#endif