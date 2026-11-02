import {createHash} from 'node:crypto';
import {readFileSync, writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';

export type SemanticSchedulerPerfOptions = {
  groups: 1 | 2 | 4;
  /** Arms per group, not total arms. Every group contains all four result shapes. */
  arms: 4 | 8 | 16;
};

export const semanticSchedulerPerfPresets = {
  small: {groups: 1, arms: 4},
  medium: {groups: 2, arms: 8},
  large: {groups: 4, arms: 16},
} as const satisfies Record<string, SemanticSchedulerPerfOptions>;

export const semanticSchedulerPerfProvenance = {
  purpose: 'development-surrogate-not-original-qualification',
  originals: [
    {
      path: 'checkpoints/checker_core_steps_v1.bend',
      sha256: 'e4c1197d63129394551d5643ef2934be84af82eaeacfa3da1e4e660c6ff603a4',
      protocolLines: [2562, 2582],
      schedulerLines: [35907, 35930],
    },
    {
      path: 'evals/scheduler_chunk_smoke.bend',
      sha256: '21986a939adccc86c6580c446242be9feb95703c6eeb820ef939d961f2247140',
      workloadLines: [5, 82],
    },
    {
      path: 'bend2/base.bend',
      sha256: '21baec76caf1a6cfd4a544340b291f7bb55bf30cc841f9f5f29e3b12a1a4d614',
    },
  ],
  imports: ['Base'],
  quantum: 64,
  coreFamilies: ['PerfValue', 'PerfProgress', 'PerfStack', 'PerfRun'],
  coreConstructors: [
    'PerfValue', 'PerfFinished', 'PerfPending', 'PerfDirect', 'PerfBound',
    'PerfStackDone', 'PerfStackMore', 'PerfRunFinished', 'PerfRunState',
  ],
  resultShapes: ['U32', 'Bool', 'List<U32>', 'U32 & Bool'],
  aliases: ['Perf.Words', 'Perf.Pair', 'Perf.Flagged'],
  ownedPayload: 'PerfPayload<PerfValue<Perf.Flagged()>> with Array<U32>',
  dynamicRepresentativeness: 'unverified: parent must trace the first NF/layout demand and measure cost',
} as const;

const templatePath = new URL('./semantic_scheduler_perf.bend', import.meta.url);
// The checked-in runnable source is also the sole template for invariant code.
// Width changes replace only marked request/dispatch, invocation, and oracle regions.
const template = readFileSync(templatePath, 'utf8');
const sha256 = (text: string) => createHash('sha256').update(text).digest('hex');
const boundaryExpected = [
  4294967295, 37, 0, 4294967295, 1, 31, 4294967295, 32, 32,
  4294967295, 48, 4294967295, 72, 2, 1, 38,
];

function checkedOptions(options: SemanticSchedulerPerfOptions): SemanticSchedulerPerfOptions {
  if (![1, 2, 4].includes(options.groups) || ![4, 8, 16].includes(options.arms)) {
    throw new Error('Expected --groups 1|2|4 and --arms 4|8|16 (arms per group)');
  }
  return {groups: options.groups, arms: options.arms};
}

function replaceRegion(source: string, region: string, body: string): string {
  const begin = `# BEGIN PERF ${region}\n`;
  const end = `# END PERF ${region}`;
  const start = source.indexOf(begin);
  const finish = source.indexOf(end);
  if (start < 0 || finish < start + begin.length ||
      source.indexOf(begin, start + begin.length) !== -1 ||
      source.indexOf(end, finish + end.length) !== -1) {
    throw new Error(`Missing or ambiguous template region ${region}`);
  }
  return source.slice(0, start + begin.length) + body + source.slice(finish);
}

type Arm = {
  group: number;
  arm: number;
  name: string;
  suffix: string;
  fields: string;
  result: string;
  pattern: string;
  operation: string;
  arguments: string;
  consume: string;
  expected: number;
};

function requestArms({groups, arms}: SemanticSchedulerPerfOptions): Arm[] {
  const rows: Arm[] = [];
  for (let group = 0; group < groups; group++) {
    for (let arm = 0; arm < arms; arm++) {
      // Fixed maximum-width stride keeps retained arms identical across presets.
      const offset = group * 16 + arm;
      const suffix = `${group}_${arm}`;
      const flag = (group + Math.floor(arm / 4)) % 2 === 0;
      const common = {group, arm, name: `PerfRequest_${suffix}`, suffix};
      switch (arm % 4) {
        case 0:
          rows.push({...common, fields: 'left: U32, right: U32', result: 'U32',
            pattern: 'left, right', operation: `U32.add(U32.add(left, right), ${offset})`,
            arguments: '8, 9', consume: 'Perf.unbox(U32, box)', expected: 17 + offset});
          break;
        case 1:
          rows.push({...common, fields: 'left: U32, right: U32', result: 'Bool',
            pattern: 'left, right', operation: `U32.is_lt(U32.add(left, ${offset}), right)`,
            arguments: `3, ${flag ? offset + 4 : 0}`,
            consume: 'Bool.to_u32(Perf.unbox(Bool, box))', expected: Number(flag)});
          break;
        case 2:
          rows.push({...common, fields: 'values: Perf.Words(), bias: U32', result: 'Perf.Words()',
            pattern: 'values, bias', operation: `Perf.shift(values, U32.add(bias, ${offset}))`,
            arguments: '[1, 2, 3], 2', consume: 'Perf.words_score(Perf.unbox(Perf.Words(), box))',
            expected: 12 + 3 * offset});
          break;
        case 3:
          rows.push({...common,
            fields: 'payload: PerfPayload<PerfValue<Perf.Flagged()>>, bias: U32', result: 'Perf.Flagged()',
            pattern: 'payload, bias', operation: `Perf.payload_pair(payload, U32.add(bias, ${offset}))`,
            arguments: `PerfPayload{ANode{ALeaf{4}, ALeaf{5}}, PerfValue{(7, ${flag ? 'True' : 'False'}{})}}, 2`,
            consume: 'Perf.pair_score(Perf.unbox(Perf.Flagged(), box))', expected: 18 + offset + Number(flag)});
          break;
      }
    }
  }
  return rows;
}

function renderRequests(options: SemanticSchedulerPerfOptions, rows: Arm[]): string {
  const groups = Array.from({length: options.groups}, (_, group) => ({
    group, rows: rows.filter(row => row.group === group),
  }));
  const blocks = groups.map(({group, rows}) =>
    `type PerfRequestGroup${group} is Type:\n` +
    rows.map(row => `  ${row.name}{${row.fields}}`).join('\n'));
  blocks.push('type PerfRequest is Type:\n' + groups.map(({group}) =>
    `  PerfRequestGroup_${group}{request: PerfRequestGroup${group}}`).join('\n'));
  for (const {group, rows} of groups) {
    blocks.push(`def Perf.result_group_${group}(request: PerfRequestGroup${group}) -> Type:\n` +
      '  match request:\n' + rows.map(row => `    case ${row.name}{_, _}: ${row.result}`).join('\n'));
  }
  blocks.push('def Perf.result(request: PerfRequest) -> Type:\n  match request:\n' +
    groups.map(({group}) => `    case PerfRequestGroup_${group}{inner}: Perf.result_group_${group}(inner)`).join('\n'));
  return blocks.join('\n\n') + '\n\n';
}

function renderDispatch(options: SemanticSchedulerPerfOptions, rows: Arm[]): string {
  const groups = Array.from({length: options.groups}, (_, group) => ({
    group, rows: rows.filter(row => row.group === group),
  }));
  const blocks: string[] = [];
  for (const {group, rows} of groups) {
    blocks.push(`def Perf.step_group_${group}(request: PerfRequestGroup${group}) -> PerfProgress<Perf.result_group_${group}(request)>:\n` +
      '  match request:\n' + rows.map(row =>
        `    case ${row.name}{${row.pattern}}:\n      PerfFinished{PerfValue{${row.operation}}}`).join('\n'));
  }
  blocks.push('def Perf.step_one(request: PerfRequest) -> PerfProgress<Perf.result(request)>:\n  match request:\n' +
    groups.map(({group}) => `    case PerfRequestGroup_${group}{inner}: Perf.step_group_${group}(inner)`).join('\n'));
  return blocks.join('\n\n') + '\n\n';
}

function renderWorkload(rows: Arm[]): string {
  const blocks = rows.map(row => `def Perf.request_score_${row.suffix}() -> U32:\n` +
    '  Perf.score(Perf.step(U32, Perf.run(PerfPending{\n' +
    `    PerfRequestGroup_${row.group}{${row.name}{${row.arguments}}},\n` +
    `    box => PerfFinished{PerfValue{${row.consume}}}})))`);
  const body = ['def Perf.print_requests() -> IO(Unit):'];
  for (const row of rows) body.push(`  +score_${row.suffix} = Perf.request_score_${row.suffix}()`);
  rows.forEach((row, index) => body.push(
    `  checksum_${index} = U32.add(${index === 0 ? '0' : `checksum_${index - 1}`}, score_${row.suffix})`));
  body.push('  do IO<Unit>:');
  for (const row of rows) body.push(`    IO.print(U32.show(score_${row.suffix}))`);
  body.push(`    IO.print(U32.show(checksum_${rows.length - 1}))`);
  blocks.push(body.join('\n'));
  return blocks.join('\n\n') + '\n\n';
}

export function semanticSchedulerPerfExpected(
  options: SemanticSchedulerPerfOptions = semanticSchedulerPerfPresets.small,
): number[] {
  const rows = requestArms(checkedOptions(options));
  return [...boundaryExpected, ...rows.map(row => row.expected),
    rows.reduce((sum, row) => sum + row.expected, 0)];
}

export function renderSemanticSchedulerPerf(
  options: SemanticSchedulerPerfOptions = semanticSchedulerPerfPresets.small,
): string {
  const dimensions = checkedOptions(options);
  const rows = requestArms(dimensions);
  let source = replaceRegion(template, 'WIDTH', `# groups=${dimensions.groups} arms=${dimensions.arms}\n`);
  source = replaceRegion(source, 'REQUESTS', renderRequests(dimensions, rows));
  source = replaceRegion(source, 'DISPATCH', renderDispatch(dimensions, rows));
  source = replaceRegion(source, 'WORKLOAD', renderWorkload(rows));
  source = replaceRegion(source, 'EXPECTED',
    semanticSchedulerPerfExpected(dimensions).map(value => `#|${value}\n`).join(''));
  return source;
}

export function renderSemanticSchedulerPerfArtifact(
  options: SemanticSchedulerPerfOptions = semanticSchedulerPerfPresets.small,
) {
  const dimensions = checkedOptions(options);
  const source = renderSemanticSchedulerPerf(dimensions);
  return {
    source,
    metadata: {
      ...semanticSchedulerPerfProvenance,
      ...dimensions,
      requestCount: dimensions.groups * dimensions.arms,
      expectedLines: semanticSchedulerPerfExpected(dimensions),
      sourceSha256: sha256(source),
      sourceBytes: Buffer.byteLength(source),
      sourceLines: source.split('\n').length - 1,
      templatePath: 'evals/semantic_scheduler_perf.bend',
      templateSha256: sha256(template),
      generatorPath: 'evals/semantic_scheduler_perf_source.ts',
      generatorSha256: sha256(readFileSync(fileURLToPath(import.meta.url), 'utf8')),
      // Width validation and hashes are provenance, not a proof of structural equivalence.
      schemaWitness: 'Obtain independently from semantic_scheduler_perf_shape.ts',
    },
  };
}

function main(args: string[]): void {
  let options: SemanticSchedulerPerfOptions = {...semanticSchedulerPerfPresets.small};
  let out: string | undefined;
  const seen = new Set<string>();
  for (let index = 0; index < args.length; index++) {
    const flag = args[index];
    if (!['--preset', '--groups', '--arms', '--out'].includes(flag) || seen.has(flag)) {
      throw new Error(`Unknown or repeated option ${flag}`);
    }
    seen.add(flag);
    const value = args[++index];
    if (!value || value.startsWith('--')) throw new Error(`Missing value for ${flag}`);
    if (flag === '--preset') {
      if (seen.has('--groups') || seen.has('--arms')) throw new Error('--preset must precede width overrides');
      if (!Object.hasOwn(semanticSchedulerPerfPresets, value)) throw new Error('Expected --preset small|medium|large');
      options = {...semanticSchedulerPerfPresets[value as keyof typeof semanticSchedulerPerfPresets]};
    } else if (flag === '--groups') {
      if (!['1', '2', '4'].includes(value)) throw new Error('Expected --groups 1|2|4');
      options.groups = Number(value) as SemanticSchedulerPerfOptions['groups'];
    } else if (flag === '--arms') {
      if (!['4', '8', '16'].includes(value)) throw new Error('Expected --arms 4|8|16');
      options.arms = Number(value) as SemanticSchedulerPerfOptions['arms'];
    } else {
      out = value;
    }
  }
  const source = renderSemanticSchedulerPerf(options);
  // Never replace the generator's invariant template with a non-default variant.
  if (out && resolve(out) === fileURLToPath(templatePath) &&
      (options.groups !== 1 || options.arms !== 4)) {
    throw new Error('Write non-default variants to a separate --out path');
  }
  if (out) writeFileSync(out, source);
  else process.stdout.write(source);
}

if (process.argv[1] && pathToFileURL(resolve(process.argv[1])).href === import.meta.url) {
  main(process.argv.slice(2));
}
