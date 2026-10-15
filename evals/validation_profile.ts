import type * as Bend from '../bend2/bend.ts';

type Memory = {footprintBytes?: number; rssBytes: number; heapUsed: number};
type Emit = (event: Record<string, unknown>) => void;
/** Observe complete native validation without controlling the runtime collector. */
export function validationProfile(memory: () => Memory, emit: Emit) {
  const rows: Record<string, unknown>[] = [];
  let active: {index: number; name: string; start: number; cpu: NodeJS.CpuUsage; bodyMs: number; bodyChecks: number} | undefined;
  const bodyStarts: {name: string; start: number}[] = [];
  const finish = () => {
    if (!active) return;
    const cpu = process.cpuUsage(active.cpu);
    const row = {stage: 'declaration-end', index: active.index, name: active.name,
      elapsedMs: performance.now() - active.start, bodyMs: active.bodyMs, bodyChecks: active.bodyChecks,
      cpuMs: (cpu.user + cpu.system) / 1000, ...memory()};
    rows.push(row); emit(row); active = undefined;
  };
  const observeCheck = (name: string, stage: 'before' | 'after') => {
    if (stage === 'before') bodyStarts.push({name, start: performance.now()});
    else {
      const check = bodyStarts.pop();
      if (!check || check.name !== name) throw Error('Native body observation nesting changed: ' + name);
      if (active) {
        if (!bodyStarts.length) active.bodyMs += performance.now() - check.start;
        active.bodyChecks++;
      }
    }
  };
  const run = (kernel: typeof Bend, book: Bend.Book, limit = book.order.length) => {
    const original = book.order, order = original.slice(0, limit);
    let passes = 0;
    const start = performance.now(), cpuStart = process.cpuUsage();
    emit({stage: 'validation-policy', manualGC: false,
      checksExcluded: 0, checkedOutputRetention: 'native e', totalEvents: original.length,
      diagnosticPrefix: limit < original.length ? limit : null});
    book.order = new Proxy(order, {get(array, key, receiver) {
      if (typeof key === 'string' && /^\d+$/.test(key)) {
        const index = Number(key);
        if (index === 0) passes++;
        if (passes === 2) {
          finish();
          active = {index, name: array[index]!, start: performance.now(), cpu: process.cpuUsage(), bodyMs: 0, bodyChecks: 0};
          emit({stage: 'declaration-begin', index, name: array[index]});
        }
      }
      return Reflect.get(array, key, receiver);
    }});
    try { kernel.book_valid(book); }
    finally { finish(); book.order = original; }
    const cpu = process.cpuUsage(cpuStart);
    return {status: limit < original.length ? 'DIAGNOSTIC_PREFIX_PASS' : 'FULL_VALIDATION_PASS',
      eventsChecked: order.length, totalEvents: original.length, manualGC: false,
      elapsedMs: performance.now() - start, cpuMs: (cpu.user + cpu.system) / 1000, rows};
  };
  return {observeCheck, run};
}
