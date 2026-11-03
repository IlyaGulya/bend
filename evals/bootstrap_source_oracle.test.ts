import {expect, test} from 'bun:test';
import {mkdtempSync, mkdirSync, readFileSync, realpathSync, rmSync, symlinkSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import * as B from '../bend2/bend.ts';
import {sourceOracle} from './bootstrap_source_oracle.ts';

test('source oracle preserves root declarations and bodies through a directory symlink', async () => {
  const directory = mkdtempSync(join(tmpdir(), 'bend-oracle-alias-'));
  try {
    const target = join(directory, 'target'), alias = join(directory, 'alias');
    mkdirSync(target);
    symlinkSync(target, alias);
    const source = 'import Base\ndef value() -> U32:\n  17\n';
    writeFileSync(join(target, 'source.bend'), source);
    const oracle = await sourceOracle(join(alias, 'source.bend'), source, {recordInputs: true});
    expect(oracle.accepted).toBe(true);
    expect(oracle.file).toBe(realpathSync(join(target, 'source.bend')));
    expect(oracle.declarations.map(({key, kind}) => ({key, kind})))
      .toEqual([{key: 'value', kind: 'def'}]);
    const book = oracle.normalizationBook();
    const value = B.term_wnf(book, B.Ref('value'));
    expect(value.$).toBe('Lit');
    if (value.$ !== 'Lit') throw Error('Expected authentic native literal body');
    expect(value.k).toBe('U32');
    expect(value.v).toBe(17);
  } finally {
    rmSync(directory, {recursive: true, force: true});
  }
});

test('identical frozen compilers retain their own Base and observation cache identity', async () => {
  const directory = mkdtempSync(join(tmpdir(), 'bend-oracle-frozen-'));
  try {
    const compiler = readFileSync(join(B.BEND_DIR, 'bend.ts'), 'utf8');
    const base = readFileSync(B.BASE_BEND, 'utf8');
    const observed: string[] = [];
    for (const [name, value] of [['first', 17], ['second', 29]] as const) {
      const root = join(directory, name), bend = join(root, 'bend2');
      mkdirSync(bend, {recursive: true});
      const frozenCompiler = join(bend, 'bend.ts'), frozenBase = join(bend, 'base.bend');
      writeFileSync(frozenCompiler, compiler);
      writeFileSync(frozenBase, base + `\ndef corpus_marker() -> U32:\n  ${value}\n`);
      const file = join(root, 'source.bend');
      const source = 'import Base\ndef value() -> U32:\n  corpus_marker()\n';
      writeFileSync(file, source);
      const oracle = await sourceOracle(file, source, {recordInputs: true, stage0File: frozenCompiler});
      expect(oracle.accepted).toBe(true);
      expect(oracle.inputFiles.some(input => input.file === realpathSync(frozenBase))).toBe(true);
      expect(oracle.inputFiles.some(input => input.file === B.BASE_BEND)).toBe(false);
      observed.push(oracle.observation.stage0Sha256);
      const result = B.term_wnf(oracle.normalizationBook(), B.Ref('value'));
      expect(result.$).toBe('Lit');
      if (result.$ !== 'Lit') throw Error('Expected frozen Base marker value');
      expect(result.v).toBe(value);
    }
    expect(observed[0]).toBe(observed[1]);
  } finally {
    rmSync(directory, {recursive: true, force: true});
  }
});
