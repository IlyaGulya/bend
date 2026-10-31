import {readFileSync, writeFileSync, realpathSync, existsSync} from 'node:fs';
import {resolve, dirname} from 'node:path';
import {createHash} from 'node:crypto';

// Static source inventory only: never imports a compiler or launches a child.
// Import discovery is a conservative lexical inventory, NOT parsing authority.
// Parent must compare each cell's inputs to actual source-worker.inputs.
const [repositoryArg, output, ...suites] = process.argv.slice(2);
if (!repositoryArg || !output || !suites.length || existsSync(output)) throw Error('usage: inventory.mjs REPOSITORY FRESH_JSON SUITE...');
const hash = b => createHash('sha256').update(b).digest('hex');
const report = {schemaVersion: 1, status: 'STARTING', executionClaim: false, discovery: 'anchored-source-import-inventory-not-parser-authority', cells: [], files: {}, failures: []};
const save = () => writeFileSync(output, JSON.stringify(report, null, 2) + '\n');
save();
try {
  const repository = realpathSync(repositoryArg);
  const pin = path => { path = realpathSync(path); const bytes = readFileSync(path); report.files[path] = {bytes: bytes.length, sha256: hash(bytes)}; return path; };
  for (const suiteFile of suites) {
    const suitePath = pin(suiteFile), suite = JSON.parse(readFileSync(suitePath, 'utf8'));
    for (const row of suite.rows) for (const target of row.targets ?? ['c', 'js']) {
      const cell = {name: row.name, source: realpathSync(row.source), target, expected: row.expected, sourceRevision: 'sha256-per-file', compilerAuthority: 'GENUINE_R12_NATIVE_SEED_STAGE1_REQUIRED', observedExecution: 'NOT_EXECUTED_BY_THIS_TOOL', inputs: {}, plugins: {}};
      const visit = path => {
        path = pin(path); if (Object.hasOwn(cell.inputs, path)) return;
        cell.inputs[path] = report.files[path].sha256;
        if (!path.endsWith('.bend')) return;
        const text = readFileSync(path, 'utf8');
        for (const match of text.matchAll(/^\s*import\s+(?:"([^"\n]+)"|([^\s#]+))/gm)) {
          const imported = match[1] ?? match[2];
          if (/\.(c|js)$/.test(imported) && !imported.endsWith('.' + target)) continue;
          if (imported !== 'Base' && !/\.(bend|c|js)$/.test(imported)) throw Error('Unresolved import inventory ' + path + ': ' + imported);
          visit(imported === 'Base' ? resolve(repository, 'bend2/base.bend') : resolve(dirname(path), imported));
        }
      };
      report.cells.push(cell); save();
      visit(row.source);
      if (target === 'c') visit(resolve(repository, 'bend2/selfhost/c_runtime.c'));
      for (const plugin of row.plugins ?? []) { const path = pin(plugin); cell.plugins[path] = report.files[path].sha256; }
      save();
    }
  }
  report.status = 'OFFLINE_INVENTORY_COMPLETE_NOT_EXECUTION';
} catch (error) { report.status = 'SETUP_FAILED'; report.failures.push({message: String(error), stack: error?.stack}); process.exitCode = 1; }
save();
