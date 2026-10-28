/* Single-export C library caller for the typed C step seam. The emitted
   library must publish exactly the named export and return its observable
   result through the same runtime entry the six-symbol fixture uses. */
#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef uint64_t Term;

extern void bend_library_init(void);
extern uint32_t bend_export_count(void);
extern const char *bend_export_name(uint32_t);
extern Term bend_export_call(uint32_t, const Term *, uint32_t);

int main(void) {
  bend_library_init();
  if (bend_export_count() != 1 || strcmp(bend_export_name(0), "U32.mul")) return 2;
  Term args[2] = {2, 3};
  printf("%llu\n", (unsigned long long)bend_export_call(0, args, 2));
  return 0;
}
