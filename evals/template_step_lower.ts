#!/usr/bin/env bun
/** Derive real Template expansion with the authenticated shared Body-AST/CPS lowerer.
 * Generate source/provenance only; native validation belongs to the integration gate.
 * This component leaves the combined Checker/Emitter driver untouched.
 */
import {checkerStepConfig, generateNativeSteps} from './checker_core_step_lower.ts';
import type {StepConfig} from './checker_core_step_lower.ts';

export const templateStepConfig: StepConfig = {
  ...checkerStepConfig,
  mode: 'template', root: 'expand', result: 'ExpandResult',
  canonical: 'bend2/selfhost/template.bend', owned: 'checkpoints/template_owned_v1.bend',
  ownedDriver: undefined,
  generator: 'evals/template_step_lower.ts',
  output: 'checkpoints/template_steps_v1.bend',
  component: 'checkpoints/template_steps_component_v1.bend',
  driver: undefined,
  manifest: 'checkpoints/template-steps-v1.json',
};
if (import.meta.main) await generateNativeSteps(templateStepConfig);
