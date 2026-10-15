#!/usr/bin/env bun
/** Derive canonical JSEmit with the same authenticated AST/CPS implementation as CheckerCore.
 * This entry point generates source/provenance only; the target gate owns native validation.
 */
import {checkerStepConfig, generateNativeSteps} from './checker_core_step_lower.ts';
import type {StepConfig} from './checker_core_step_lower.ts';

export const emitterStepConfig: StepConfig = {
  ...checkerStepConfig,
  mode: 'emitter', root: 'emit', result: 'EmitResult',
  canonical: 'bend2/selfhost/js_emit.bend', owned: 'checkpoints/js_emit_owned_v1.bend',
  generator: 'evals/js_emit_step_lower.ts',
  ownedDriver: undefined,
  output: 'checkpoints/js_emit_steps_v1.bend',
  component: 'checkpoints/js_emit_steps_component_v1.bend',
  driver: 'checkpoints/checker_core_steps_emit_driver_v1.bend',
  manifest: 'checkpoints/js-emit-steps-v1.json',
  checkerOutput: 'checkpoints/checker_core_steps_driver_v1.bend',
  checkerManifest: 'checkpoints/checker-core-steps-v1.json',
};
if (import.meta.main) await generateNativeSteps(emitterStepConfig);
