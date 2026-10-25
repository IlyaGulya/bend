// Diagnostic native chunk-attribution host. Included only by the profile-only
// driver; the production 14-callback native_experiment remains unchanged.
//
// The Bend view types carry exactly one owning thunk plus a nullary progress
// shape. The host reads only constructor identity and counts shapes; it never
// reads a request payload, a source span or a semantic stage name.
#include <sys/resource.h>

static void native_stage_cpu_sample(struct rusage* usage) {
  if (getrusage(RUSAGE_SELF, usage) != 0)
    err_fail("native stage profile: cannot sample process CPU");
}

static double native_stage_cpu_ms(const struct timeval* before, const struct timeval* after) {
  return (double)(after->tv_sec - before->tv_sec) * 1000.0
    + (double)(after->tv_usec - before->tv_usec) / 1000.0;
}

static Term native_stage_apply(Env e, Term function, Term argument) {
  u64 at = task_node(e, FID(Clo~apply), TERM_HOLE, 0, 0);
  e.mem[at] = function;
  e.mem[at + 1] = argument;
  return corpus_eval(e.mem, term_tsk(FID(Clo~apply), at));
}

static void native_stage_fields(Env e, Term value, u32 cid, u32 n, Term* fields) {
  if (term_aux(value) != cid || cid_arity(cid) != n
      || (term_tag(value) != TAG_CTR && term_tag(value) != TAG_PAK)) {
    err_fail("native stage profile: unexpected typed constructor/layout");
  }
  if (term_tag(value) == TAG_PAK) {
    if (n > 1) err_fail("native stage profile: packed constructor arity");
    if (n == 1) fields[0] = term_loc(value);
  } else {
    spare_free(e, cls_fit(n), ctr_take(e, value, n, fields));
  }
}

static Term native_stage_drive(Env e, Term start, Term view, u32 finished, u32 more, const char* phase, int group_stage, Term outcome) {
  u64 chunks = 0, shapes[4] = {0, 0, 0, 0}, groups[27] = {0};
  u64 started = io_tick();
  struct rusage before;
  native_stage_cpu_sample(&before);
  Term run = native_stage_apply(e, start, term_pak(CID(Unit), 0));
  for (;;) {
    Term observed = native_stage_apply(e, view, run);
    u32 tag = (u32)term_aux(observed);
    Term thunk;
    if (tag == more) {
      Term fields[2];
      native_stage_fields(e, observed, more, 2, fields);
      // Template/checker codes: 0 Finished, 1 Pending, 2 Direct, 3 Bound.
      // Emitter codes: 0 Finished, 1 Direct(erased request), 2 Bound,
      // 100+N Pending whose outer request-group variant is N.
      u32 shape = (u32)term_loc(fields[1]);
      if (!group_stage) {
        if (shape > 3) err_fail("native stage profile: unknown chunk progress shape");
        shapes[shape] += 1;
      } else if (shape <= 2) {
        shapes[shape] += 1;
      } else if (shape >= 100 && shape < 127) {
        groups[shape - 100] += 1;
      } else {
        err_fail("native stage profile: unknown emitter request group code");
      }
      thunk = fields[0];
      observed = TERM_HOLE;
      run = native_stage_apply(e, thunk, term_pak(CID(Unit), 0));
      chunks += 1;
    } else if (tag == finished) {
      native_stage_fields(e, observed, finished, 1, &thunk);
      Term result = native_stage_apply(e, thunk, term_pak(CID(Unit), 0));
      struct rusage after;
      native_stage_cpu_sample(&after);
      fprintf(stderr, "NATIVE_CHUNK_PROFILE {\"phase\":\"%s\",\"elapsedMs\":%.3f,\"userCpuMs\":%.3f,\"systemCpuMs\":%.3f,\"chunkAdvances\":%llu,\"chunkQuantum\":64,\"shapeFinished\":%llu,\"shapePending\":%llu,\"shapeDirect\":%llu,\"shapeBound\":%llu,\"requestGroups\":{",
        phase, (double)(io_tick() - started) / 1000000.0,
        native_stage_cpu_ms(&before.ru_utime, &after.ru_utime),
        native_stage_cpu_ms(&before.ru_stime, &after.ru_stime),
        (unsigned long long)chunks, (unsigned long long)shapes[0],
        (unsigned long long)shapes[1], (unsigned long long)shapes[2],
        (unsigned long long)shapes[3]);
      int first_group = 1;
      for (u32 i = 0; i < 27; i++) {
        if (groups[i] == 0) continue;
        fprintf(stderr, "%s\"%u\":%llu", first_group ? "" : ",", i, (unsigned long long)groups[i]);
        first_group = 0;
      }
      fprintf(stderr, "}}\n");
      if (outcome != TERM_HOLE) {
        // The typed outcome callback consumes the affine result exactly once.
        return native_stage_apply(e, outcome, result);
      }
      term_drop(e, result);
      return term_pak(CID(Unit), 0);
    } else {
      err_fail("native stage profile: invalid profile view constructor");
    }
  }
}

static Term native_stage_template_run(Env e, Term* f, IoWork* work) {
  (void)work;
  return native_stage_drive(e, f[0], f[1],
    CID(NativeTemplateStageFinished), CID(NativeTemplateStageMore), "template-chunks", 0, TERM_HOLE);
}

static Term native_stage_template_pending_run(Env e, Term* f, IoWork* work) {
  (void)work;
  return native_stage_drive(e, f[0], f[1],
    CID(NativeTemplateStageFinished), CID(NativeTemplateStageMore), "template-pending-chunks", 0, TERM_HOLE);
}

static Term native_stage_checker_run(Env e, Term* f, IoWork* work) {
  (void)work;
  return native_stage_drive(e, f[0], f[1],
    CID(NativeCheckerStageFinished), CID(NativeCheckerStageMore), "checker-chunks", 0, TERM_HOLE);
}

static Term native_stage_emitter_run(Env e, Term* f, IoWork* work) {
  (void)work;
  return native_stage_drive(e, f[0], f[1],
    CID(NativeEmitterStageFinished), CID(NativeEmitterStageMore), "emitter-chunks", 1, f[2]);
}

static void __attribute__((constructor)) native_stage_profile_use(void) {
  io_eff(CID(native_stage_template), native_stage_template_run);
  io_eff(CID(native_stage_checker), native_stage_checker_run);
  io_eff(CID(native_stage_template_pending), native_stage_template_pending_run);
  io_eff(CID(native_stage_emitter), native_stage_emitter_run);
}
