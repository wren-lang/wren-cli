#ifndef cli_common_h
#define cli_common_h

#include <stdlib.h>
#include <string.h>

inline char* cli_strdup(const char* s) {
  size_t len = strlen(s) + 1;
  char* m = (char*)malloc(len);
  if (m == NULL) return NULL;
  return memcpy(m, s, len);
}

inline char* cli_strndup(const char* s, size_t n) {
  char* m;
  size_t len = strlen(s);
  if (n < len) len = n;
  m = (char*)malloc(len + 1);
  if (m == NULL) return NULL;
  m[len] = '\0';
  return memcpy(m, s, len);
}

#endif