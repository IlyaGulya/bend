#!/usr/bin/env bun
/** Derive the one production emitter composition: both JS and C entry paths.
 * The canonical emitter root owns the single inert result and the two bridges;
 * js_emit, c_emit_core and every shared provider module are composed once into
 * the same typed CPS boundary. Lowering, catalog and normalizer therefore exist
 * exactly once by canonical identity, and both targets share one Run engine.
 * This entry point generates source/provenance only; native validation and the
 * C CLI proof are separate gates.
 *
 * CLI
 * ---
 *   bun evals/emitter_step_lower.ts            ordinary build (unchanged)
 *   bun evals/emitter_step_lower.ts --trace    diagnostic scheduler-boundary build
 *
 * `--trace` is opt-in and diagnostic only. It writes its own artifacts
 * (checkpoints/emitter_steps_trace_v1.bend, ..._component_v1.bend,
 * emitter-steps-trace-v1.json) and its own pin set
 * (checkpoints/emitter_trace_owned_v1.bend,
 * checkpoints/emitter-trace-owned-source-v1.json) so no ordinary byte moves.
 * The trace closure is the ordinary ten providers plus c_backend_sharing, which
 * is what gives emit-sharing a real boundary; its composition is regenerated,
 * never patched, and the derived pin set fails closed if the ordinary pin set
 * is stale. Every root is resolved to its composed declaration through
 * canonicalComposition.declarations. The trajectory itself: one EmitterRunSpan
 * value carrying one EmitterTraceBegin/EmitterTraceEnd per marked canonical
 * entry and its matching return, emitted at real scheduler yields; quantum,
 * semantic transitions, results and the 13-export ABI are unchanged.
 * Shared read-only inputs (dependency, frozen slice/driver/corpus, kernel,
 * parser, base, node/validation policies) keep their single canonical paths in
 * both configs: they are inputs authenticated per manifest by hash, not outputs.
 */
import {checkerStepConfig, generateNativeSteps} from './checker_core_step_lower.ts';
import type {StepConfig, StepTraceRoot} from './checker_core_step_lower.ts';

export const emitterStepConfig: StepConfig = {
  ...checkerStepConfig,
  mode: 'emitter', root: 'emit', result: 'EmitResult',
  canonical: 'bend2/selfhost/emitter.bend', owned: 'checkpoints/emitter_owned_v1.bend',
  generator: 'evals/emitter_step_lower.ts',
  providerClosure: [
    'bend2/selfhost/backend_lower.bend', 'bend2/selfhost/lower_catalog.bend', 'bend2/selfhost/descriptor_nf.bend',
    'bend2/selfhost/js_emit.bend', 'bend2/selfhost/js_backend.bend',
    'bend2/selfhost/c_emit_core.bend', 'bend2/selfhost/c_backend.bend',
    'bend2/selfhost/c_backend_link.bend', 'bend2/selfhost/c_backend_layout.bend',
    'bend2/selfhost/c_backend_physical.bend',
  ],
  entries: [
    {mode: 'emitter', root: 'emit', libraryRoot: 'emit_library'},
    {mode: 'cemit', root: 'emit_c', libraryRoot: 'emit_c_library'},
  ],
  componentAlias: 'Emit',
  ownedDriver: undefined, driver: undefined,
  output: 'checkpoints/emitter_steps_v1.bend',
  component: 'checkpoints/emitter_steps_component_v1.bend',
  manifest: 'checkpoints/emitter-steps-v1.json',
};
/** Canonical public entrypoints that bound one scheduler-observable stage.
 * `site` is the authenticated boundary identity; the host maps it to `stage`.
 * Only entrypoints that cross a provider/module boundary are listed, so a stage
 * is described by a span set rather than by one invented phase. NF and layouts
 * really do run under several parents; sharing needs the trace closure above.
 * Sites are stable, unique and ordered by stage. */
const emitterTraceRoots: readonly StepTraceRoot[] = [
  {site: 1, stage: 'emit-emitter-entry', source: 'bend2/selfhost/emitter.bend', canonicalName: 'emit'},
  {site: 2, stage: 'emit-emitter-entry', source: 'bend2/selfhost/emitter.bend', canonicalName: 'emit_library'},
  {site: 3, stage: 'emit-emitter-entry', source: 'bend2/selfhost/emitter.bend', canonicalName: 'emit_c'},
  {site: 4, stage: 'emit-emitter-entry', source: 'bend2/selfhost/emitter.bend', canonicalName: 'emit_c_library'},
  {site: 5, stage: 'emit-backend-lowering', source: 'bend2/selfhost/backend_lower.bend', canonicalName: 'lower'},
  {site: 6, stage: 'emit-backend-lowering', source: 'bend2/selfhost/backend_lower.bend', canonicalName: 'lower_library'},
  {site: 7, stage: 'emit-catalog', source: 'bend2/selfhost/lower_catalog.bend', canonicalName: 'build'},
  {site: 8, stage: 'emit-descriptor-nf', source: 'bend2/selfhost/descriptor_nf.bend', canonicalName: 'normalize_in'},
  {site: 9, stage: 'emit-descriptor-nf', source: 'bend2/selfhost/descriptor_nf.bend', canonicalName: 'nf'},
  {site: 10, stage: 'emit-descriptor-nf', source: 'bend2/selfhost/descriptor_nf.bend', canonicalName: 'nf_context'},
  {site: 11, stage: 'emit-layouts', source: 'bend2/selfhost/c_backend_layout.bend', canonicalName: 'context'},
  {site: 12, stage: 'emit-layouts', source: 'bend2/selfhost/c_backend_layout.bend', canonicalName: 'layout_of_desc'},
  {site: 13, stage: 'emit-layouts', source: 'bend2/selfhost/c_backend_layout.bend', canonicalName: 'layout_fill'},
  {site: 14, stage: 'emit-layouts', source: 'bend2/selfhost/c_backend_layout.bend', canonicalName: 'layout_unfill'},
  {site: 15, stage: 'emit-sharing', source: 'bend2/selfhost/c_backend_sharing.bend', canonicalName: 'sharing_plan'},
  {site: 16, stage: 'emit-sharing', source: 'bend2/selfhost/c_backend_sharing.bend', canonicalName: 's_facts_build'},
  {site: 17, stage: 'emit-sharing', source: 'bend2/selfhost/c_backend_sharing.bend', canonicalName: 's_plan_from_facts'},
  {site: 18, stage: 'emit-render-js', source: 'bend2/selfhost/js_emit.bend', canonicalName: 'emit'},
  {site: 19, stage: 'emit-render-js', source: 'bend2/selfhost/js_emit.bend', canonicalName: 'emit_library'},
  {site: 20, stage: 'emit-render-js', source: 'bend2/selfhost/js_emit.bend', canonicalName: 'render'},
  {site: 21, stage: 'emit-render-js', source: 'bend2/selfhost/js_backend.bend', canonicalName: 'link'},
  {site: 22, stage: 'emit-render-js', source: 'bend2/selfhost/js_backend.bend', canonicalName: 'emit_linked'},
  {site: 23, stage: 'emit-render-c', source: 'bend2/selfhost/c_emit_core.bend', canonicalName: 'emit'},
  {site: 24, stage: 'emit-render-c', source: 'bend2/selfhost/c_emit_core.bend', canonicalName: 'emit_library'},
  {site: 25, stage: 'emit-render-c', source: 'bend2/selfhost/c_emit_core.bend', canonicalName: 'render'},
  {site: 26, stage: 'emit-render-c', source: 'bend2/selfhost/c_backend.bend', canonicalName: 'emit'},
  {site: 27, stage: 'emit-render-c', source: 'bend2/selfhost/c_backend.bend', canonicalName: 'render'},
  {site: 28, stage: 'emit-render-c', source: 'bend2/selfhost/c_backend.bend', canonicalName: 'plan_make'},
  {site: 29, stage: 'emit-render-c', source: 'bend2/selfhost/c_backend_physical.bend', canonicalName: 'show_build'},
  {site: 30, stage: 'emit-link-planning', source: 'bend2/selfhost/c_backend_link.bend', canonicalName: 'rewrite'},
];
export const emitterTraceStepConfig: StepConfig = {
  ...emitterStepConfig,
  providerClosure: [...emitterStepConfig.providerClosure!, 'bend2/selfhost/c_backend_sharing.bend'],
  owned: 'checkpoints/emitter_trace_owned_v1.bend',
  ownedManifest: 'checkpoints/emitter-trace-owned-source-v1.json',
  output: 'checkpoints/emitter_steps_trace_v1.bend',
  component: 'checkpoints/emitter_steps_trace_component_v1.bend',
  manifest: 'checkpoints/emitter-steps-trace-v1.json',
  trace: {protocolVersion: 1, quantum: 64, maxEventsPerBoundary: 1, roots: emitterTraceRoots},
};
async function prepareTracePins() {
  // A static import cannot work: checker_core_owned_source.ts imports
  // emitterStepConfig from this module, so it must load after this module has
  // fully evaluated. The specifier is a constant; nothing else is dynamic.
  const {generateDiagnosticEmitterTracePins} = await import('./checker_core_owned_source.ts');
  return generateDiagnosticEmitterTracePins({
    mode: emitterTraceStepConfig.mode, canonical: emitterTraceStepConfig.canonical,
    output: emitterTraceStepConfig.owned, ownedManifest: emitterTraceStepConfig.ownedManifest,
    baseManifest: emitterStepConfig.ownedManifest,
    closure: emitterTraceStepConfig.providerClosure!, baseClosure: emitterStepConfig.providerClosure!,
  });
}
if (import.meta.main) {
  const arguments_ = process.argv.slice(2);
  const unknown = arguments_.filter(argument => argument !== '--trace');
  if (unknown.length) throw Error('Unknown emitter CLI arguments: ' + unknown.join(' ') + ' (expected no arguments or --trace)');
  if (arguments_.length === 0) {
    await generateNativeSteps(emitterStepConfig);
  } else {
    const pins = await prepareTracePins();
    console.log(JSON.stringify({traceOwned: pins.owned, traceOwnedManifest: pins.manifest, traceSourceSha256: pins.sourceSha256}));
    await generateNativeSteps(emitterTraceStepConfig);
  }
}
