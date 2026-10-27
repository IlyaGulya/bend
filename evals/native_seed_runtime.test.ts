import {expect, test} from 'bun:test';
import {mkdtempSync, writeFileSync, chmodSync, rmSync} from 'node:fs';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {runNativeStage0, requireNativeRun} from './native_seed_runtime.mjs';

test('native process faults cannot pass an expected-negative source fixture', () => {
  const directory = mkdtempSync(join(tmpdir(), 'bend-native-rejection-'));
  try {
    for (const [name, ending, rejected] of [
      ['signal', 'kill -TERM $$', false],
      ['runtime', 'printf "bend: native experiment: unexpected typed constructor/layout\\n" >&2\nexit 1', false],
      ['rejected', 'printf "bend: native experiment: Bend rejected the input\\n" >&2\nexit 1', true],
    ] as const) {
      // Fault injection at the executable boundary; no compiler success is simulated.
      const binary = join(directory, name), output = binary + '.js';
      writeFileSync(binary, '#!/bin/sh\nprintf \'NATIVE_PHASE_START {"phase":"check"}\\n\' >&2\n' + ending + '\n');
      chmodSync(binary, 0o700);
      const run = runNativeStage0(binary, {
        root: 'fault-injection', base: 'base', manifest: 'manifest', exports: 'exports',
        phase: 'compile-module', output,
      }, {timeoutMs: 2000});
      let failure: any;
      try {
        requireNativeRun(run, {phases: ['parse', 'expand', 'check', 'emit'], sources: 1, output});
      } catch (error) {
        failure = error;
      }
      expect(failure).toBeInstanceOf(Error);
      expect(failure.failurePhase === 'check').toBe(rejected);
    }
  } finally {
    rmSync(directory, {recursive: true, force: true});
  }
});
