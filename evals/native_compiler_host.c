// Trusted orchestration only: runtime file IO, import resolution and the same
// LIFO continuation machine as checker_core_step_runtime.mjs. No parser,
// elaborator, checker, emitter, source literal or expected result lives here.
// Included unchanged by compile_book's ordinary foreign-effect mechanism.

#include <sys/resource.h>

typedef struct {
  char* path;
  char* scope;
  int state; // 0 unseen, 1 active, 2 complete; -1 foreign bytes
} NativeInput;

typedef struct {
  NativeInput* inputs;
  size_t count;
  Term* modules;
  size_t module_count;
  size_t module_capacity;
  Term parse;
  const char* base;
  u64 source_bytes;
  u64 foreign_bytes;
  u64 fuel_build_ns;
  u64 fuel_cells;
  u64 parsed_sources;
} NativeLoader;

static u64 native_peak_rss(void) {
  struct rusage usage;
  if (getrusage(RUSAGE_SELF, &usage) != 0)
    err_fail("native experiment: cannot sample fuel RSS");
#ifdef __APPLE__
  return (u64)usage.ru_maxrss;
#else
  return (u64)usage.ru_maxrss * 1024;
#endif
}

static void native_fields(Env e, Term value, u32 cid, u32 n, Term* fields) {
  if (term_aux(value) != cid || cid_arity(cid) != n
      || (term_tag(value) != TAG_CTR && term_tag(value) != TAG_PAK)) {
    err_fail("native experiment: unexpected typed constructor/layout");
  }
  if (term_tag(value) == TAG_PAK) {
    if (n > 1) err_fail("native experiment: packed constructor arity");
    if (n == 1) fields[0] = term_loc(value);
  } else {
    spare_free(e, cls_fit(n), ctr_take(e, value, n, fields));
  }
}

// The IO evaluator has already returned before this effect is entered.
// Each call returns before another call is made: no evaluator reentry, no
// borrowed heap pointer survives an evaluation, and no affine closure is copied.
static Term native_apply(Env e, Term function, Term argument) {
  u64 at = task_node(e, FID(Clo~apply), TERM_HOLE, 0, 0);
  e.mem[at] = function;
  e.mem[at + 1] = argument;
  return corpus_eval(e.mem, term_tsk(FID(Clo~apply), at));
}

static void native_closed(Term function) {
  if (term_tag(function) != TAG_CLO || term_loc(function) != 0) {
    err_fail("native experiment: reusable callback must be capture-free");
  }
}

static Term native_drive(Env e, Term start, Term argument, Term reflect,
    u32 finished, u32 more, const char* phase) {
  Term* stack = NULL;
  size_t depth = 0, capacity = 0;
  u64 calls = 0, resumes = 0;
  u64 started = io_tick();
  Term progress = native_apply(e, start, argument);
  for (;;) {
    // reflect is polymorphic in its erased result type. It preserves the
    // original existential request domain in each next/resume pair.
    progress = native_apply(e, reflect, progress);
    u32 tag = (u32)term_aux(progress);
    Term fs[2];
    if (tag == more) {
      native_fields(e, progress, more, 2, fs);
      if (depth == capacity) {
        capacity = capacity ? capacity * 2 : 256;
        stack = io_mem(realloc(stack, capacity * sizeof(Term)));
      }
      stack[depth++] = fs[1];
      calls += 1;
      progress = native_apply(e, fs[0], term_pak(CID(Unit), 0));
    } else if (tag == finished) {
      native_fields(e, progress, finished, 1, fs);
      if (depth == 0) {
        free(stack);
        fprintf(stderr, "NATIVE_PHASE {\"phase\":\"%s\",\"elapsedMs\":%.3f,\"calls\":%llu,\"resumes\":%llu}\n",
          phase, (double)(io_tick() - started) / 1000000.0,
          (unsigned long long)calls, (unsigned long long)resumes);
        return fs[0];
      }
      Term resume = stack[--depth];
      stack[depth] = TERM_HOLE;
      resumes += 1;
      progress = native_apply(e, resume, fs[0]);
    } else {
      err_fail("native experiment: invalid progress constructor");
    }
  }
}

static Term native_accepted(Env e, Term result) {
  Term value;
  if (term_aux(result) == CID(NativeRejected)) {
    native_fields(e, result, CID(NativeRejected), 1, &value);
    io_errs(e, value);
    err_fail("native experiment: Bend rejected the input");
  }
  native_fields(e, result, CID(NativeAccepted), 1, &value);
  return value;
}

static char* native_read(const char* path, u64* length) {
  FILE* file = fopen(path, "rb");
  if (!file) err_fail("native experiment: cannot open input");
  if (fseek(file, 0, SEEK_END) != 0) err_fail("native experiment: input seek");
  long size = ftell(file);
  if (size < 0 || fseek(file, 0, SEEK_SET) != 0) err_fail("native experiment: input size");
  char* bytes = io_mem(malloc((size_t)size + 1));
  if (fread(bytes, 1, (size_t)size, file) != (size_t)size || fclose(file) != 0)
    err_fail("native experiment: input read");
  bytes[size] = 0;
  *length = (u64)size;
  return bytes;
}

static char* native_join(const char* parent, const char* path) {
  if (path[0] == '/') return io_mem(strdup(path));
  const char* slash = strrchr(parent, '/');
  size_t prefix = slash ? (size_t)(slash - parent + 1) : 0;
  char* joined = io_mem(malloc(prefix + strlen(path) + 1));
  memcpy(joined, parent, prefix);
  strcpy(joined + prefix, path);
  return joined;
}

// POSIX lexical normalization, matching the existing Node namespace rule.
static char* native_scope(const char* parent, const char* path) {
  if (strcmp(path, "Base") == 0) return io_mem(strdup(""));
  char* joined = native_join(parent, path);
  size_t length = strlen(joined);
  if (length >= 5 && strcmp(joined + length - 5, ".bend") == 0) joined[length - 5] = 0;
  bool absolute = joined[0] == '/';
  char** parts = io_mem(malloc((strlen(joined) + 1) * sizeof(char*)));
  size_t count = 0;
  char* save;
  for (char* part = strtok_r(joined, "/", &save); part; part = strtok_r(NULL, "/", &save)) {
    if (strcmp(part, ".") == 0) continue;
    if (strcmp(part, "..") == 0 && count && strcmp(parts[count - 1], "..") != 0) count--;
    else if (strcmp(part, "..") != 0 || !absolute) parts[count++] = part;
  }
  char* scope = io_mem(malloc(length + 2));
  size_t at = absolute ? 1 : 0;
  if (absolute) scope[0] = '/';
  for (size_t i = 0; i < count; i++) {
    if (i) scope[at++] = '/';
    size_t n = strlen(parts[i]);
    memcpy(scope + at, parts[i], n);
    at += n;
  }
  scope[at] = 0;
  free(parts);
  free(joined);
  return scope;
}

static void native_visit(Env e, NativeLoader* loader, const char* path, const char* scope) {
  char* real = realpath(path, NULL);
  if (!real) err_fail("native experiment: import does not exist");
  NativeInput* input = NULL;
  for (size_t i = 0; i < loader->count; i++) {
    if (strcmp(loader->inputs[i].path, real) == 0) input = &loader->inputs[i];
  }
  free(real);
  if (!input || input->state < 0 || strcmp(input->scope, scope) != 0)
    err_fail("native experiment: source/namespace outside frozen manifest");
  if (input->state == 1) err_fail("native experiment: import cycle");
  if (input->state == 2) return;
  input->state = 1;
  u64 bytes;
  char* source = native_read(input->path, &bytes);
  loader->source_bytes += bytes;
  Term fuel = term_pak(CID(FeedbackFuelEnd), 0);
  // Same finite 8M parser control input as the current Node harness, but eager
  // native cells rather than lazy JS cells. Include this cost in parse timing
  // and report process RSS high-water before/after construction explicitly.
  u64 rss_before_fuel = native_peak_rss();
  u64 fuel_started = io_tick();
  for (u32 i = 0; i < 8000000; i++) fuel = io_box(e, CID(FeedbackFuelCell), fuel);
  u64 fuel_elapsed = io_tick() - fuel_started;
  loader->fuel_build_ns += fuel_elapsed;
  loader->fuel_cells += 8000000;
  loader->parsed_sources += 1;
  fprintf(stderr, "NATIVE_FUEL {\"sourceOrdinal\":%llu,\"cells\":8000000,\"elapsedMs\":%.3f,\"processPeakRssBeforeBytes\":%llu,\"processPeakRssAfterBytes\":%llu}\n",
    (unsigned long long)loader->parsed_sources, (double)fuel_elapsed / 1000000.0,
    (unsigned long long)rss_before_fuel, (unsigned long long)native_peak_rss());
  Term argument = io_tup(e, fuel, io_tup(e,
    io_str(e, input->path, strlen(input->path)), io_str(e, source, bytes)));
  free(source);
  Term result = native_apply(e, loader->parse, argument);
  if (term_aux(result) == CID(NativeParseFailure)) {
    Term message;
    native_fields(e, result, CID(NativeParseFailure), 1, &message);
    fprintf(stderr, "native parser file: %s\n", input->path);
    io_errs(e, message);
    err_fail("native experiment: actual Bend parser failed");
  }
  Term parsed[2];
  native_fields(e, result, CID(NativeParsed), 2, parsed);
  Term imports = parsed[0], load = parsed[1];
  while (term_aux(imports) == CID(Con)) {
    Term pair[2];
    native_fields(e, imports, CID(Con), 2, pair);
    imports = pair[1];
    u64 length;
    char* imported = io_cstr(e, pair[0], &length);
    if (io_nul(imported, length)) err_fail("native experiment: NUL in import");
    if (length >= 3 && strcmp(imported + length - 3, ".js") == 0) {
      // Foreign bytes are separately read and authenticated by the manifest.
      free(imported);
      continue;
    }
    char* child = strcmp(imported, "Base") == 0
      ? io_mem(strdup(loader->base)) : native_join(input->path, imported);
    char* child_scope = native_scope(scope, imported);
    native_visit(e, loader, child, child_scope);
    free(child_scope);
    free(child);
    free(imported);
  }
  native_fields(e, imports, CID(Nil), 0, NULL);
  Term module = native_apply(e, load, io_str(e, scope, strlen(scope)));
  if (loader->module_count == loader->module_capacity) {
    loader->module_capacity = loader->module_capacity ? loader->module_capacity * 2 : 32;
    loader->modules = io_mem(realloc(loader->modules, loader->module_capacity * sizeof(Term)));
  }
  loader->modules[loader->module_count++] = module;
  input->state = 2;
}

static NativeLoader native_manifest(const char* file, const char* base, Term parse) {
  NativeLoader loader = { .parse = parse, .base = base };
  u64 size;
  char* bytes = native_read(file, &size);
  char* line_save;
  for (char* line = strtok_r(bytes, "\n", &line_save); line; line = strtok_r(NULL, "\n", &line_save)) {
    if ((line[0] != 'B' && line[0] != 'E') || line[1] != '\t')
      err_fail("native experiment: invalid runtime manifest row");
    char* scope = line + 2;
    char* path = strchr(scope, '\t');
    if (!path) err_fail("native experiment: missing runtime manifest path");
    *path++ = 0;
    char* real = realpath(path, NULL);
    if (!real) err_fail("native experiment: missing manifest input");
    loader.inputs = io_mem(realloc(loader.inputs, (loader.count + 1) * sizeof(NativeInput)));
    loader.inputs[loader.count++] = (NativeInput){ real, io_mem(strdup(scope)), line[0] == 'E' ? -1 : 0 };
    if (line[0] == 'E') {
      u64 length;
      char* foreign = native_read(real, &length);
      loader.foreign_bytes += length;
      free(foreign);
    }
  }
  free(bytes);
  return loader;
}

static Term native_exports(Env e, const char* path) {
  u64 size;
  char* bytes = native_read(path, &size);
  Term reverse = term_pak(CID(Nil), 0);
  char* save;
  for (char* name = strtok_r(bytes, "\n", &save); name; name = strtok_r(NULL, "\n", &save)) {
    reverse = io_node(e, CID(Con), io_str(e, name, strlen(name)), reverse);
  }
  free(bytes);
  Term exports = term_pak(CID(Nil), 0);
  while (term_aux(reverse) == CID(Con)) {
    Term pair[2];
    native_fields(e, reverse, CID(Con), 2, pair);
    exports = io_node(e, CID(Con), pair[0], exports);
    reverse = pair[1];
  }
  native_fields(e, reverse, CID(Nil), 0, NULL);
  return exports;
}

static Term native_experiment_run(Env e, Term* f, IoWork* work) {
  (void)work;
  if (io_argc != 7) err_fail("native experiment: expected root base manifest exports check|compile output");
  for (u32 i = 0; i < 10; i++) native_closed(f[i]);
  bool compile = strcmp(io_argv[5], "compile") == 0;
  if (!compile && strcmp(io_argv[5], "check") != 0) err_fail("native experiment: invalid phase");
  fprintf(stderr, "NATIVE_BEGIN {\"computeThreads\":%u,\"parserFuel\":8000000,\"phase\":\"%s\"}\n", pool_size, io_argv[5]);
  u64 started = io_tick();
  NativeLoader loader = native_manifest(io_argv[3], io_argv[2], f[0]);
  native_visit(e, &loader, io_argv[1], "");
  for (size_t i = 0; i < loader.count; i++) {
    if (loader.inputs[i].state == 0) err_fail("native experiment: workload source was omitted");
  }
  Term modules = term_pak(CID(Nil), 0);
  for (size_t i = loader.module_count; i > 0; i--)
    modules = io_node(e, CID(Con), loader.modules[i - 1], modules);
  free(loader.modules);
  for (size_t i = 0; i < loader.count; i++) { free(loader.inputs[i].path); free(loader.inputs[i].scope); }
  free(loader.inputs);
  fprintf(stderr, "NATIVE_PHASE {\"phase\":\"parse\",\"elapsedMs\":%.3f,\"modules\":%zu,\"sourceBytes\":%llu,\"foreignBytes\":%llu,\"eagerFuelCells\":%llu,\"fuelBuildMs\":%.3f}\n",
    (double)(io_tick() - started) / 1000000.0, loader.module_count,
    (unsigned long long)loader.source_bytes, (unsigned long long)loader.foreign_bytes,
    (unsigned long long)loader.fuel_cells, (double)loader.fuel_build_ns / 1000000.0);
  Term expanded = native_drive(e, f[1], modules, f[2],
    CID(NativeTemplateFinished), CID(NativeTemplateMore), "expand");
  modules = native_accepted(e, native_apply(e, f[3], expanded));
  Term checked = native_drive(e, f[4], modules, f[5],
    CID(NativeCheckerFinished), CID(NativeCheckerMore), "check");
  modules = native_accepted(e, native_apply(e, f[6], checked));
  if (compile) {
    Term emission = native_drive(e, f[7], io_tup(e, modules, native_exports(e, io_argv[4])), f[8],
      CID(NativeEmitterFinished), CID(NativeEmitterMore), "emit");
    Term source = native_accepted(e, native_apply(e, f[9], emission));
    u64 length;
    char* bytes = io_cstr(e, source, &length);
    FILE* output = fopen(io_argv[6], "wx");
    if (!output) err_fail("native experiment: output must be a fresh writable path");
    io_out(output, bytes, length);
    if (fclose(output) != 0) err_fail("native experiment: output close failed");
    free(bytes);
    printf("NATIVE_RESULT {\"result\":\"EmitSuccess\",\"bytes\":%llu,\"modules\":%zu}\n", (unsigned long long)length, loader.module_count);
  } else {
    term_drop(e, modules);
    printf("NATIVE_RESULT {\"result\":\"CheckSuccess\",\"modules\":%zu}\n", loader.module_count);
  }
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) native_experiment_use(void) {
  io_eff(CID(native_experiment), native_experiment_run);
}
