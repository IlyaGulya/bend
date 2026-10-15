import {expect, test} from 'bun:test';
import {mkdtempSync, mkdirSync, realpathSync, rmSync, symlinkSync, writeFileSync} from 'node:fs';
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
