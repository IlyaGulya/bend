#!/usr/bin/env bun
/** Derive the C emitter through the same authenticated typed CPS boundary as JS.
 * The pure seam c_emit_core lowers and joins; provider modules are composed into
 * the boundary so C emission is real CPS work, not one external call.
 * This entry point generates source/provenance only; actual native validation
 * and the C CLI proof are separate gates.
 */
import {checkerStepConfig, generateNativeSteps} from './checker_core_step_lower.ts';
import type {StepConfig} from './checker_core_step_lower.ts';

export const cemitStepConfig: StepConfig = {
  ...checkerStepConfig,
  mode: 'cemit', root: 'emit', result: 'EmitResult',
  canonical: 'bend2/selfhost/c_emit_core.bend', owned: 'checkpoints/c_emit_owned_v1.bend',
  generator: 'evals/c_emit_step_lower.ts',
  providerClosure: ['bend2/selfhost/backend_lower.bend', 'bend2/selfhost/lower_catalog.bend',
    'bend2/selfhost/descriptor_nf.bend', 'bend2/selfhost/c_backend.bend',
    'bend2/selfhost/c_backend_layout.bend', 'bend2/selfhost/c_backend_physical.bend'],
  ownedDriver: undefined, driver: undefined,
  checkerOutput: undefined, checkerManifest: undefined,
  output: 'checkpoints/c_emit_steps_v1.bend',
  component: 'checkpoints/c_emit_steps_component_v1.bend',
  manifest: 'checkpoints/c-emit-steps-v1.json',
};
if (import.meta.main) await generateNativeSteps(cemitStepConfig);
