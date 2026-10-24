#!/usr/bin/env bun
/** Derive the one production emitter composition: both JS and C entry paths.
 * The canonical emitter root owns the single inert result and the two bridges;
 * js_emit, c_emit_core and every shared provider module are composed once into
 * the same typed CPS boundary. Lowering, catalog and normalizer therefore exist
 * exactly once by canonical identity, and both targets share one Run engine.
 * This entry point generates source/provenance only; native validation and the
 * C CLI proof are separate gates.
 */
import {checkerStepConfig, generateNativeSteps} from './checker_core_step_lower.ts';
import type {StepConfig} from './checker_core_step_lower.ts';

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
if (import.meta.main) await generateNativeSteps(emitterStepConfig);
