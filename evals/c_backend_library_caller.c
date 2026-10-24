#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef uint64_t Term;
typedef uint32_t u32;

extern u32 bend_export_count(void);
extern const char* bend_export_name(u32 i);
extern u32 bend_export_arity(u32 i);
extern void bend_library_init(void);
extern Term bend_export_call(u32 i, const Term* args, u32 n);
extern Term bend_export_apply(Term fun, const Term* args, u32 n);

static u32 index_of(const char* name) {
  for (u32 i = 0; i < bend_export_count(); i += 1) {
    const char* have = bend_export_name(i);
    if (have && strcmp(have, name) == 0) { return i; }
  }
  assert(0 && "export name missing");
  return 0;
}

int main(void) {
  bend_library_init();
  assert(bend_export_count() == 6);
  assert(bend_export_name(0) != 0);

  /* direct, exact arity: add(2, 3) == 5 */
  Term ab[2] = {2, 3};
  assert(bend_export_call(index_of("add"), ab, 2) == 5);
  /* a function declaration exported as a symbol desugars to its code entry */
  assert(bend_export_call(index_of("symbol_add"), ab, 2) == 5);

  /* direct with extra host arguments: partial(5, 7) == 12 */
  Term pb[2] = {5, 7};
  assert(bend_export_call(index_of("partial"), pb, 2) == 12);

  /* zero-arity direct, and the lazy zero-arity symbol */
  assert(bend_export_call(index_of("mk"), 0, 0) == 9);
  assert(bend_export_call(index_of("zero"), 0, 0) == 9);

  /* a lazy factory re-evaluates: two calls are distinct closure terms */
  Term f = bend_export_call(index_of("factory"), 0, 0);
  Term g = bend_export_call(index_of("factory"), 0, 0);
  assert(f != g);

  /* the returned closure applies through the runtime: (5 + 7) == 12 */
  Term c[1] = {7};
  assert(bend_export_apply(f, c, 1) == 12);

  puts("export ok");
  return 0;
}
