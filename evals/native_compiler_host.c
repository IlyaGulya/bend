// Trusted orchestration only: runtime file IO, import resolution and the same
// opaque chunk machine as checker_core_step_runtime.mjs. No parser,
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
  Term files;
  const char* base;
  u64 source_bytes;
  u64 foreign_bytes;
  u64 fuel_build_ns;
  u64 fuel_cells;
  u64 parsed_sources;
} NativeLoader;

static void native_cpu_sample(struct rusage* usage) {
  if (getrusage(RUSAGE_SELF, usage) != 0)
    err_fail("native experiment: cannot sample process CPU");
}

static double native_cpu_ms(const struct timeval* before, const struct timeval* after) {
  return (double)(after->tv_sec - before->tv_sec) * 1000.0
    + (double)(after->tv_usec - before->tv_usec) / 1000.0;
}

static void native_phase_start(const char* phase, struct rusage* cpu) {
  native_cpu_sample(cpu);
  fprintf(stderr, "NATIVE_PHASE_START {\"phase\":\"%s\"}\n", phase);
}

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
  u64 chunk_advances = 0;
  u64 started = io_tick();
  struct rusage cpu_started;
  native_phase_start(phase, &cpu_started);
  Term run = native_apply(e, start, argument);
  for (;;) {
    // The polymorphic native view preserves the original result type, executes
    // chunk64, and hides the existential RunState behind one owning thunk.
    Term input = run;
    run = TERM_HOLE;
    Term view = native_apply(e, reflect, input);
    chunk_advances += 1;
    u32 tag = (u32)term_aux(view);
    Term thunk;
    if (tag == more) {
      native_fields(e, view, more, 1, &thunk);
      view = TERM_HOLE;
      run = native_apply(e, thunk, term_pak(CID(Unit), 0));
    } else if (tag == finished) {
      native_fields(e, view, finished, 1, &thunk);
      view = TERM_HOLE;
      // No flattened Value<A> layout is assumed at the C boundary.
      Term boxed = native_apply(e, thunk, term_pak(CID(Unit), 0));
      struct rusage cpu_finished;
      native_cpu_sample(&cpu_finished);
      fprintf(stderr, "NATIVE_PHASE {\"phase\":\"%s\",\"elapsedMs\":%.3f,\"userCpuMs\":%.3f,\"systemCpuMs\":%.3f,\"chunkAdvances\":%llu,\"chunkQuantum\":64}\n",
        phase, (double)(io_tick() - started) / 1000000.0,
        native_cpu_ms(&cpu_started.ru_utime, &cpu_finished.ru_utime),
        native_cpu_ms(&cpu_started.ru_stime, &cpu_finished.ru_stime),
        (unsigned long long)chunk_advances);
      return boxed;
    } else {
      err_fail("native experiment: invalid run view constructor");
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

// POSIX lexical normalization, matching the existing Node namespace rule. It
// is also the exact rule BIR uses for a declared foreign path, so the host bag
// is keyed by the same string the renderer derives.
static char* native_normalized(const char* joined, bool strip_bend) {
  size_t length = strlen(joined);
  char* text = io_mem(strdup(joined));
  if (strip_bend && length >= 5 && strcmp(text + length - 5, ".bend") == 0) {
    text[length - 5] = 0;
    length -= 5;
  }
  bool absolute = text[0] == '/';
  char** parts = io_mem(malloc((length + 1) * sizeof(char*)));
  size_t count = 0;
  char* save;
  for (char* part = strtok_r(text, "/", &save); part; part = strtok_r(NULL, "/", &save)) {
    if (strcmp(part, ".") == 0) continue;
    if (strcmp(part, "..") == 0 && count && strcmp(parts[count - 1], "..") != 0) count--;
    else if (strcmp(part, "..") != 0 || !absolute) parts[count++] = part;
  }
  char* result = io_mem(malloc(length + 2));
  size_t at = absolute ? 1 : 0;
  if (absolute) result[0] = '/';
  for (size_t i = 0; i < count; i++) {
    if (i) result[at++] = '/';
    size_t n = strlen(parts[i]);
    memcpy(result + at, parts[i], n);
    at += n;
  }
  result[at] = 0;
  free(parts);
  free(text);
  return result;
}

static char* native_scope(const char* parent, const char* path) {
  if (strcmp(path, "Base") == 0) return io_mem(strdup(""));
  char* joined = native_join(parent, path);
  char* scope = native_normalized(joined, true);
  free(joined);
  return scope;
}

static bool native_manifest_external(const NativeLoader* loader, const char* real) {
  for (size_t i = 0; i < loader->count; i++)
    if (loader->inputs[i].state == -1 && strcmp(loader->inputs[i].path, real) == 0) return true;
  return false;
}

// The declared `.js` alternative is BIR metadata: the renderer resolves it and
// joins by that exact resolved path. The host only reads the bytes of the path
// BIR derives and hands them over as a passive BIR.SourceFile.
static void native_foreign(Env e, NativeLoader* loader, const char* module, const char* declared) {
  // DefImports may list the native `.c` implementation too. Only the declared
  // `.js` alternative is a BIR link source; the JS host applies the same rule.
  size_t declared_length = strlen(declared);
  if (declared_length < 3 || strcmp(declared + declared_length - 3, ".js") != 0) return;
  char* joined = native_join(module, declared);
  char* key = native_normalized(joined, false);
  free(joined);
  char* real = realpath(key, NULL);
  if (!real) {
    fprintf(stderr, "native foreign path: %s\n", key);
    err_fail("native experiment: missing declared JavaScript foreign source");
  }
  if (!native_manifest_external(loader, real)) {
    fprintf(stderr, "native foreign path: %s\n", real);
    err_fail("native experiment: foreign source outside the authenticated manifest");
  }
  u64 length;
  char* bytes = native_read(key, &length);
  loader->foreign_bytes += length;
  // The canonical C id block names the authoritative BIR.SourceFile constructor
  // from the book key `../bend2/selfhost/backend_ir:SourceFile` (name_clean ->
  // upper). This is the existing generated macro, not a numeric or suffix guess;
  // the guard makes a spelling/namespace change fail at compile time.
#ifndef CID____BEND2_SELFHOST_BACKEND_IR_SOURCEFILE
#error "canonical BIR.SourceFile constructor id is missing from the generated book"
#endif
  Term entry = io_node(e, CID____BEND2_SELFHOST_BACKEND_IR_SOURCEFILE, io_str(e, key, strlen(key)), io_str(e, bytes, length));
  loader->files = io_node(e, CID(Con), entry, loader->files);
  free(real);
  free(bytes);
  free(key);
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
  Term parsed[3];
  native_fields(e, result, CID(NativeParsed), 3, parsed);
  Term imports = parsed[0], foreign = parsed[1], load = parsed[2];
  while (term_aux(foreign) == CID(Con)) {
    Term cell[2];
    native_fields(e, foreign, CID(Con), 2, cell);
    foreign = cell[1];
    u64 length;
    char* declared = io_cstr(e, cell[0], &length);
    if (io_nul(declared, length)) err_fail("native experiment: NUL in declared foreign path");
    native_foreign(e, loader, input->path, declared);
    free(declared);
  }
  native_fields(e, foreign, CID(Nil), 0, NULL);
  while (term_aux(imports) == CID(Con)) {
    Term pair[2];
    native_fields(e, imports, CID(Con), 2, pair);
    imports = pair[1];
    u64 length;
    char* imported = io_cstr(e, pair[0], &length);
    if (io_nul(imported, length)) err_fail("native experiment: NUL in import");
    if (length >= 3 && strcmp(imported + length - 3, ".js") == 0) {
      // Module-level foreign imports are not BIR link sources; the definition's
      // own DefImports alternatives above are the declared target.
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
  NativeLoader loader = { .parse = parse, .files = term_pak(CID(Nil), 0), .base = base };
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
      // Existence and readability are checked here; the bytes that actually
      // reach the emitter are read when a definition declares that path.
      u64 length;
      char* foreign = native_read(real, &length);
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
  // 0 library emission, 1 runnable module emission for source fixtures,
  // -1 check only. The emitter entry point is selected in the checked driver.
  int action = strcmp(io_argv[5], "compile") == 0 ? 0
    : strcmp(io_argv[5], "compile-module") == 0 ? 1
    : strcmp(io_argv[5], "check") == 0 ? -1 : 2;
  if (action == 2) err_fail("native experiment: invalid phase");
  fprintf(stderr, "NATIVE_BEGIN {\"computeThreads\":%u,\"parserFuel\":8000000,\"phase\":\"%s\",\"phaseTraceVersion\":3}\n", pool_size, io_argv[5]);
  u64 started = io_tick();
  struct rusage cpu_started;
  native_phase_start("parse", &cpu_started);
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
  struct rusage cpu_finished;
  native_cpu_sample(&cpu_finished);
  fprintf(stderr, "NATIVE_PHASE {\"phase\":\"parse\",\"elapsedMs\":%.3f,\"userCpuMs\":%.3f,\"systemCpuMs\":%.3f,\"modules\":%zu,\"sourceBytes\":%llu,\"foreignBytes\":%llu,\"eagerFuelCells\":%llu,\"fuelBuildMs\":%.3f}\n",
    (double)(io_tick() - started) / 1000000.0,
    native_cpu_ms(&cpu_started.ru_utime, &cpu_finished.ru_utime),
    native_cpu_ms(&cpu_started.ru_stime, &cpu_finished.ru_stime), loader.module_count,
    (unsigned long long)loader.source_bytes, (unsigned long long)loader.foreign_bytes,
    (unsigned long long)loader.fuel_cells, (double)loader.fuel_build_ns / 1000000.0);
  Term expanded = native_drive(e, f[1], modules, f[2],
    CID(NativeTemplateFinished), CID(NativeTemplateMore), "expand");
  modules = native_accepted(e, native_apply(e, f[3], expanded));
  Term checked = native_drive(e, f[4], modules, f[5],
    CID(NativeCheckerFinished), CID(NativeCheckerMore), "check");
  Term emit = native_accepted(e, native_apply(e, f[6], checked));
  if (action >= 0) {
    Term request = action == 0
      ? io_node(e, CID(NativeLibrary), native_exports(e, io_argv[4]), loader.files)
      : io_box(e, CID(NativeModule), loader.files);
    Term emission = native_drive(e, f[7],
      io_tup(e, emit, request), f[8],
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
    term_drop(e, emit);
    printf("NATIVE_RESULT {\"result\":\"CheckSuccess\",\"modules\":%zu}\n", loader.module_count);
  }
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) native_experiment_use(void) {
  io_eff(CID(native_experiment), native_experiment_run);
}
